import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skincare/Controllers/HomeController.dart';
import 'package:skincare/Services/profile_values.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  GoTrueClient get _auth => _client.auth;
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null && _auth.currentSession != null;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> profile,
  }) {
    final error = ProfileValues.validateProfile(
      name: profile['full_name']?.toString() ?? '',
      age: profile['age']?.toString() ?? '',
      genderValue: profile['gender']?.toString(),
      skin: profile['skin_type']?.toString(),
      location: profile['location_text']?.toString(),
    );
    if (error != null) throw ArgumentError('Invalid profile: $error');
    return _auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        ...profile,
        'gender': ProfileValues.gender(profile['gender']),
        'skin_type': ProfileValues.skinType(profile['skin_type']),
        'location_text': ProfileValues.country(profile['location_text']),
      },
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) => _auth.signInWithPassword(email: email.trim(), password: password);

  void _requireUser(String id) {
    if (!isLoggedIn || currentUser!.id != id) {
      throw const AuthException('Please sign in again.');
    }
  }

  Future<Map<String, dynamic>?> ensureProfile() async {
    final user = currentUser;
    if (user == null || !isLoggedIn) return null;
    final existing = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    _requireUser(user.id);
    final metadata = <String, dynamic>{...?(user.userMetadata)};
    metadata['full_name'] ??= metadata['name'];
    metadata['avatar_url'] ??= metadata['picture'];
    final patch = {
      ...ProfileValues.missingProfileFields(existing ?? {}, metadata),
      ...ProfileValues.canonicalStoredFields(existing ?? {}),
    };
    if (existing != null) {
      if (patch.isEmpty) return existing;
      // Only backfill blanks or normalize equivalent legacy Arabic labels.
      // Provider metadata never replaces a saved skin/location/name.
      return await _client
          .from('profiles')
          .update({
            ...patch,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', user.id)
          .select()
          .single();
    }
    final payload = <String, dynamic>{
      'id': user.id,
      'email': user.email,
      ...patch,
      'full_name':
          patch['full_name'] ?? user.email?.split('@').first ?? 'Sidar User',
    };
    // A database trigger/another auth callback may create the row meanwhile.
    // Ignore the conflict, then re-read instead of overwriting its values.
    await _client
        .from('profiles')
        .upsert(payload, onConflict: 'id', ignoreDuplicates: true);
    _requireUser(user.id);
    return await _client.from('profiles').select().eq('id', user.id).single();
  }

  /// A failed profile fetch must not trap an otherwise authenticated session.
  Future<void> prepareSession() async {
    final id = currentUser?.id;
    if (id == null || !isLoggedIn) return;
    Map<String, dynamic>? profile;
    try {
      profile = await ensureProfile().timeout(const Duration(seconds: 10));
    } catch (_) {
      // The profile screens can retry once connectivity is restored.
    }
    if (!isLoggedIn || currentUser?.id != id) return;
    final language =
        profile?['preferred_language'] ??
        currentUser?.userMetadata?['preferred_language'];
    if (language == 'ar' || language == 'en') {
      await Get.updateLocale(
        language == 'ar' ? const Locale('ar', 'SA') : const Locale('en', 'US'),
      );
    }
    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().loadHomeData();
    }
  }

  static Future<void> clearHome() async {
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().reset();
    }
  }

  Future<void> saveProfile(Map<String, dynamic> fields) async {
    final user = currentUser;
    if (user == null) throw const AuthException('Please sign in again.');
    _requireUser(user.id);
    await ensureProfile();
    _requireUser(user.id);
    // Partial UPDATE leaves health/preferences columns not in this form intact.
    await _client
        .from('profiles')
        .update({
          ...fields,
          'email': user.email,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id);
    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      await home.fetchUserProfile();
      // Location drives the Home climate radar. Bypass its cache immediately
      // after a saved change so the pills and care note never show the old city.
      if (fields.containsKey('location_text')) {
        await home.fetchClimateRadar(forceRefresh: true);
      }
    }
  }

  Future<void> updatePassword(String password, String confirmation) async {
    final error = ProfileValues.validatePassword(password, confirmation);
    if (error != null) throw ArgumentError(error);
    final user = currentUser;
    if (user == null) throw const AuthException('Please sign in again.');
    _requireUser(user.id);
    await _auth.updateUser(UserAttributes(password: password));
  }

  Future<void> deleteAccount(String phrase) async {
    if (!ProfileValues.validDeletePhrase(phrase))
      throw ArgumentError('Invalid confirmation');
    final user = currentUser;
    if (user == null) throw const AuthException('Please sign in again.');
    _requireUser(user.id);
    // Verify the identity with Auth before deleting any user-owned objects.
    final verified = await _auth.getUser();
    if (verified.user?.id != user.id)
      throw const AuthException('Please sign in again.');
    final bucket = _client.storage.from('scan-images');
    await drainOwnedImages(
      owner: user.id,
      checkSession: () => _requireUser(user.id),
      listFirstPage: (path) async {
        final objects = await bucket.list(
          path: path,
          searchOptions: const SearchOptions(
            limit: 100,
            offset: 0,
            sortBy: SortBy(column: 'name', order: 'asc'),
          ),
        );
        return objects
            .map((object) => (name: object.name, folder: object.id == null))
            .toList();
      },
      remove: (paths) async {
        await bucket.remove(paths);
      },
    );
    _requireUser(user.id);
    await _client.rpc('delete_own_account');
    // The deleted user's token may already be revoked. Clear the local session
    // regardless; no admin/service-role credentials are used on the client.
    await signOut();
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Supabase clears its persisted local session before revoking the token.
      // A failed network revocation must not leave the old user's UI visible.
      if (_auth.currentSession != null) rethrow;
    }
    await clearHome();
  }
}
