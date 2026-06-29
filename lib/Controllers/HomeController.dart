import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skincare/Models/ScanAiModel.dart';
import 'package:skincare/Services/climate_radar_service.dart';
import 'package:skincare/Services/scan_remote_source.dart';
import 'package:skincare/Utils/AppTheme.dart';
import 'package:skincare/Views/Auth/Login.dart';

class HomeController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ScanRemoteSource _scans = ScanRemoteSource();
  StreamSubscription<AuthState>? _authSubscription;

  // =========================
  // STATE
  // =========================
  final isLoading = false.obs;
  final isProfileLoading = false.obs;
  final isScansLoading = false.obs;
  final isDoctorsLoading = false.obs;
  final isProductsLoading = false.obs;
  final isRefreshing = false.obs;
  final isDeletingScan = false.obs;

  final errorMessage = RxnString();

  final isGuestMode = false.obs;
  final userId = RxnString();
  final userEmail = RxnString();

  final profile = <String, dynamic>{}.obs;

  final latestScan = Rxn<Map<String, dynamic>>();
  final recentScans = <Map<String, dynamic>>[].obs;
  final doctors = <Map<String, dynamic>>[].obs;
  final products = <Map<String, dynamic>>[].obs;

  /// نفس ليست السجل اللي هتستخدمها DiagnosisHistoryView
  final diagnosisHistory = <Map<String, dynamic>>[].obs;

  final totalScans = 0.obs;
  final completedScans = 0.obs;
  final highUrgencyCount = 0.obs;
  final lowUrgencyCount = 0.obs;
  final mediumUrgencyCount = 0.obs;

  /// لو محتاج آخر نتيجة بشكل dynamic كما كنت مستخدم قبل كده
  final latestScanResult = Rxn<dynamic>();

  /// رادار المناخ الحي والبيئة المتصل بـ AI
  final climateData = Rxn<ClimateData>();
  final isClimateLoading = false.obs;
  int _climateRequestId = 0;

  // =========================
  // LIFECYCLE
  // =========================
  @override
  void onInit() {
    super.onInit();

    _authSubscription = _supabase.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedOut) {
        isGuestMode.value = true;
        _setGuestDefaults();
      } else if (state.session?.user.id != null &&
          state.session!.user.id != userId.value) {
        loadHomeData();
      }
    });
    loadHomeData();
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  // =========================
  // PUBLIC METHODS
  // =========================
  Future<void> loadHomeData() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final user = _supabase.auth.currentUser;

      if (user == null) {
        isGuestMode.value = true;
        _setGuestDefaults();
        fetchClimateRadar();
        return;
      }

      if (userId.value != user.id) _setGuestDefaults();
      isGuestMode.value = false;
      userId.value = user.id;
      userEmail.value = user.email;

      await Future.wait([
        fetchUserProfile(),
        fetchRecentScans(),
        fetchProducts(),
      ]);

      await fetchClimateRadar();

      _calculateStats();
    } catch (e, s) {
      log('[HomeController.loadHomeData] $e', error: e, stackTrace: s);
      errorMessage.value = 'Failed to load home data.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshHome() async {
    try {
      isRefreshing.value = true;
      errorMessage.value = null;

      if (isGuestMode.value) {
        _setGuestDefaults();
        await fetchClimateRadar(forceRefresh: true);
        return;
      }

      await Future.wait([
        fetchUserProfile(),
        fetchRecentScans(),
        fetchProducts(),
        fetchClimateRadar(forceRefresh: true),
      ]);

      _calculateStats();
    } catch (e, s) {
      log('[HomeController.refreshHome] $e', error: e, stackTrace: s);
      errorMessage.value = 'Failed to refresh data.';
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Refreshes report rows only. It keeps the current history visible while
  /// data is fetched and avoids unrelated profile, product, and climate calls.
  Future<void> refreshDiagnosisHistory() async {
    errorMessage.value = null;
    await fetchRecentScans();
  }

  Future<void> fetchClimateRadar({bool forceRefresh = false}) async {
    final requestId = ++_climateRequestId;
    try {
      isClimateLoading.value = true;
      final countryCode = profile['location_text']?.toString();
      final data = await ClimateRadarService.instance.fetchClimateData(
        countryCode: countryCode,
        isArabic: AppTheme.isArabic,
        forceRefresh: forceRefresh,
      );
      if (isClosed || requestId != _climateRequestId) return;
      climateData.value = data;
    } catch (e, s) {
      log('[HomeController.fetchClimateRadar] $e', error: e, stackTrace: s);
    } finally {
      if (!isClosed && requestId == _climateRequestId) {
        isClimateLoading.value = false;
      }
    }
  }

  Future<void> fetchUserProfile() async {
    if (isGuestMode.value || userId.value == null) return;
    try {
      isProfileLoading.value = true;

      final ownerId = userId.value;
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', ownerId as Object)
          .maybeSingle();
      if (_supabase.auth.currentUser?.id != ownerId || isClosed) return;

      if (response != null) {
        profile.value = Map<String, dynamic>.from(response);
      } else {
        profile.value = {
          'id': userId.value,
          'email': userEmail.value,
          'full_name': null,
          'preferred_language': 'en',
        };
      }
      update();
    } catch (e, s) {
      log('[HomeController.fetchUserProfile] $e', error: e, stackTrace: s);
      errorMessage.value = 'Failed to load profile.';
    } finally {
      isProfileLoading.value = false;
    }
  }

  Future<void> fetchRecentScans() async {
    if (isGuestMode.value || userId.value == null) return;

    try {
      isScansLoading.value = true;

      final ownerId = userId.value;
      final scans = await _scans.getScans(includeDetails: false);
      if (_supabase.auth.currentUser?.id != ownerId || isClosed) return;

      recentScans.assignAll(scans);
      diagnosisHistory.assignAll(scans);
      _calculateStats();

      if (scans.isNotEmpty) {
        latestScan.value = scans.first;
        latestScanResult.value = scans.first;
      } else {
        latestScan.value = null;
        latestScanResult.value = null;
      }
    } catch (e, s) {
      log('[HomeController.fetchRecentScans] $e', error: e, stackTrace: s);
      errorMessage.value = 'Failed to load scan history.';
    } finally {
      isScansLoading.value = false;
    }
  }

  Future<void> deleteScan(String scanId) async {
    if (isGuestMode.value || scanId.trim().isEmpty) return;

    try {
      isDeletingScan.value = true;
      errorMessage.value = null;

      await _scans.deleteScan(scanId);

      recentScans.removeWhere(
        (scan) => (scan['id']?.toString() ?? '') == scanId,
      );
      diagnosisHistory.removeWhere(
        (scan) => (scan['id']?.toString() ?? '') == scanId,
      );

      if (recentScans.isNotEmpty) {
        latestScan.value = recentScans.first;
        latestScanResult.value = recentScans.first;
      } else {
        latestScan.value = null;
        latestScanResult.value = null;
      }

      _calculateStats();
    } catch (e, s) {
      log('[HomeController.deleteScan] $e', error: e, stackTrace: s);
      errorMessage.value = 'Failed to delete scan.';
      rethrow;
    } finally {
      isDeletingScan.value = false;
    }
  }

  Future<void> fetchDoctors() async {
    try {
      isDoctorsLoading.value = true;

      final ownerId = userId.value;
      final response = await _supabase
          .from('doctors')
          .select()
          .eq('status', 'Active')
          .eq('is_verified', true);

      if (_supabase.auth.currentUser?.id != ownerId || isClosed) return;
      doctors.assignAll(List<Map<String, dynamic>>.from(response));
    } catch (e, s) {
      log('[HomeController.fetchDoctors] $e', error: e, stackTrace: s);
      doctors.clear();
    } finally {
      isDoctorsLoading.value = false;
    }
  }

  Future<void> fetchProducts() async {
    try {
      isProductsLoading.value = true;

      final ownerId = userId.value;
      final response = await _supabase
          .from('products')
          .select()
          .eq('is_active', true)
          .order('name');
      if (_supabase.auth.currentUser?.id != ownerId || isClosed) return;
      products.assignAll(List<Map<String, dynamic>>.from(response));
    } catch (e, s) {
      log('[HomeController.fetchProducts] $e', error: e, stackTrace: s);
      products.clear();
    } finally {
      isProductsLoading.value = false;
    }
  }

  Future<void> updateProfile({
    String? fullName,
    int? age,
    String? gender,
    String? skinType,
    String? allergies,
    String? medications,
    bool? sunSensitive,
    String? preferredLanguage,
  }) async {
    if (isGuestMode.value || userId.value == null) return;

    try {
      final now = DateTime.now().toIso8601String();

      final payload = <String, dynamic>{'id': userId.value, 'updated_at': now};

      if (fullName != null) payload['full_name'] = fullName;
      if (userEmail.value != null) payload['email'] = userEmail.value;
      if (age != null) payload['age'] = age;
      if (gender != null) payload['gender'] = gender;
      if (skinType != null) payload['skin_type'] = skinType;
      if (allergies != null) payload['allergies'] = allergies;
      if (medications != null) payload['medications'] = medications;
      if (sunSensitive != null) payload['sun_sensitive'] = sunSensitive;
      if (preferredLanguage != null) {
        payload['preferred_language'] = preferredLanguage;
      }

      await _supabase.from('profiles').upsert(payload);
      await fetchUserProfile();
    } catch (e, s) {
      log('[HomeController.updateProfile] $e', error: e, stackTrace: s);
      errorMessage.value = 'Failed to update profile.';
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      Get.offAll(() => const LoginView());
    } catch (e, s) {
      log('[HomeController.logout] $e', error: e, stackTrace: s);
      errorMessage.value = 'Failed to sign out.';
    }
  }

  void reset() {
    isGuestMode.value = true;
    _setGuestDefaults();
  }

  // =========================
  // HELPERS
  // =========================
  void _setGuestDefaults() {
    profile.value = {
      'full_name': 'Guest',
      'email': null,
      'skin_type': null,
      'preferred_language': Get.locale?.languageCode ?? 'en',
    };

    userId.value = null;
    userEmail.value = null;

    recentScans.clear();
    diagnosisHistory.clear();
    doctors.clear();
    products.clear();

    latestScan.value = null;
    latestScanResult.value = null;

    totalScans.value = 0;
    completedScans.value = 0;
    highUrgencyCount.value = 0;
    mediumUrgencyCount.value = 0;
    lowUrgencyCount.value = 0;
  }

  void _calculateStats() {
    totalScans.value = recentScans.length;

    completedScans.value = recentScans.where((scan) {
      final status = (scan['status'] ?? '').toString().toLowerCase();
      return status == 'completed' || status.isEmpty;
    }).length;

    highUrgencyCount.value = recentScans.where((scan) {
      final urgency = (scan['urgency'] ?? '').toString().toLowerCase();
      return urgency == 'high';
    }).length;

    mediumUrgencyCount.value = recentScans.where((scan) {
      final urgency = (scan['urgency'] ?? '').toString().toLowerCase();
      return urgency == 'medium';
    }).length;

    lowUrgencyCount.value = recentScans.where((scan) {
      final urgency = (scan['urgency'] ?? '').toString().toLowerCase();
      return urgency == 'low' || urgency.isEmpty;
    }).length;
  }

  // =========================
  // GETTERS
  // =========================
  // bool get isGuest => isGuestMode.value;

  String get displayName {
    final name = profile['full_name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;

    final email = userEmail.value?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return isGuestMode.value ? 'Guest' : 'User';
  }

  String get initials {
    final name = displayName.trim();
    if (name.isEmpty) return 'S';

    final parts = name.split(' ').where((e) => e.trim().isNotEmpty).toList();
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) return parts.first[0].toUpperCase();

    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String get skinTypeText => (profile['skin_type'] ?? '').toString();
  String get genderText => (profile['gender'] ?? '').toString();
  String get emailText =>
      (profile['email'] ?? userEmail.value ?? '').toString();
  int? get ageValue => profile['age'] as int?;
  bool get sunSensitiveValue => profile['sun_sensitive'] == true;

  String get latestSummary => (latestScan.value?['summary'] ?? '').toString();
  String get latestUrgency => (latestScan.value?['urgency'] ?? '').toString();
  String get latestImageQuality =>
      (latestScan.value?['image_quality'] ?? '').toString();

  List<String> get latestFindings {
    final raw = latestScan.value?['visible_findings'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return [];
  }

  List<String> get latestCareSteps {
    final raw = latestScan.value?['care_steps'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return [];
  }

  ScanAiResult? get latestAnalysisResult {
    final raw = latestScanResult.value;

    if (raw == null) return null;
    if (raw is ScanAiResult) return raw;

    if (raw is Map<String, dynamic>) {
      try {
        return ScanAiResult.fromJson(raw);
      } catch (e, s) {
        log(
          '[HomeController.latestAnalysisResult] $e',
          error: e,
          stackTrace: s,
        );
      }
    }

    return null;
  }
}
