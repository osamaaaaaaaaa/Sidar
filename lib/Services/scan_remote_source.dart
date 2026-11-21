import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skincare/Models/ScanAiModel.dart';

class ScanRemoteSource {
  ScanRemoteSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const bucketName = 'scan-images';

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Please sign in first.');
    return id;
  }

  static Map<String, dynamic> buildScanPayload({
    required ScanAiResult result,
    required Map<String, dynamic> input,
    required String userId,
    required String languageCode,
    required int imageCount,
    DateTime? createdAt,
  }) {
    final timestamp = (createdAt ?? DateTime.now()).toUtc().toIso8601String();
    return {
      'user_id': userId,
      'title': result.title,
      'report_title': result.title,
      'scan_type': input['scan_type'],
      'body_location': input['body_location'],
      'symptoms': input['symptoms'],
      'duration': input['duration'],
      'severity': input['severity'],
      'notes': input['notes'],
      'issue_type': input['issue_type'],
      'concern_category': input['skin_type_context'],
      'analysis_target': result.analysisTarget,
      'image_urls': <String>[],
      'images_count': imageCount,
      'language_code': languageCode,
      'ai_confidence': result.aiConfidence,
      'summary': result.summary,
      'problem_description': result.summary,
      'urgency': result.urgency,
      'image_quality': result.imageQuality,
      'visible_findings': result.visibleFindings,
      'care_steps': result.careSteps,
      'reasons': result.reasons,
      'disclaimer': result.disclaimer,
      'overall_score': result.overallScore,
      'hydration_score': result.hydrationScore,
      'pore_clarity_score': result.poreClarityScore,
      'fine_lines_score': result.fineLinesScore,
      'overall_tone_score': result.overallToneScore,
      'hair_density_score': result.hairDensityScore,
      'hair_texture_score': result.hairTextureScore,
      'hair_strength_score': result.hairStrengthScore,
      'scalp_health_score': result.scalpHealthScore,
      'morning_routine': result.morningRoutine,
      'evening_routine': result.eveningRoutine,
      'natural_product_suggestions': <Map<String, dynamic>>[],
      'commercial_product_suggestions': result.products,
      'nearby_doctors': result.doctors,
      'raw_ai_response': {
        ...result.toJson(),
        'location_text': input['location_text'],
        'location_label': input['location_label'],
        'image_focus_areas': input['image_focus_areas'] ?? [],
        if (input['age'] != null) 'age': input['age'],
        if (input['gender'] != null) 'gender': input['gender'],
        if (input['allergies'] != null &&
            input['allergies'].toString().isNotEmpty)
          'allergies': input['allergies'],
        if (input['medications'] != null &&
            input['medications'].toString().isNotEmpty)
          'medications': input['medications'],
        if (input['sun_sensitive'] != null)
          'sun_sensitive': input['sun_sensitive'],
      },
      'status': 'completed',
      'created_at': timestamp,
      'updated_at': timestamp,
    };
  }

  Future<String> uploadImage({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '-');
    final path = '$_userId/${DateTime.now().microsecondsSinceEpoch}-$safeName';
    await _client.storage
        .from(bucketName)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );
    return path;
  }

  Future<void> removeImages(List<String> paths) async {
    final prefix = '$_userId/';
    final owned = paths.where((path) => path.startsWith(prefix)).toList();
    if (owned.length != paths.length) {
      throw const AuthException('Image ownership does not match this account.');
    }
    if (owned.isNotEmpty) await _client.storage.from(bucketName).remove(owned);
  }

  Future<Map<String, dynamic>> saveReport({
    required Map<String, dynamic> payload,
    required List<String> imagePaths,
    required List<Map<String, dynamic>> findings,
  }) async {
    final userId = _userId;
    if (payload['user_id'] != userId ||
        imagePaths.any((path) => !path.startsWith('$userId/'))) {
      throw const AuthException('This report belongs to a different account.');
    }
    final row = await _client
        .from('scan_sessions')
        .insert({...payload, 'user_id': userId})
        .select()
        .single();
    final id = row['id'] as String;
    try {
      if (imagePaths.isNotEmpty) {
        await _client.from('scan_images').insert([
          for (var i = 0; i < imagePaths.length; i++)
            {
              'scan_id': id,
              'image_url': imagePaths[i],
              'image_path': imagePaths[i],
              'sort_order': i,
            },
        ]);
      }
      if (findings.isNotEmpty) {
        await _client.from('scan_findings').insert([
          for (var i = 0; i < findings.length; i++)
            {...findings[i], 'scan_id': id, 'sort_order': i},
        ]);
      }
    } catch (_) {
      await _client
          .from('scan_sessions')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
      rethrow;
    }
    return row;
  }

  /// The history list only needs the report rows. Loading linked images creates
  /// a signed URL for every report and is intentionally deferred unless a
  /// caller explicitly needs those details.
  Future<List<Map<String, dynamic>>> getScans({
    bool includeDetails = true,
  }) async {
    final userId = _userId;
    final rows = await _client
        .from('scan_sessions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    final scans = List<Map<String, dynamic>>.from(rows);
    if (scans.isEmpty || !includeDetails) return scans;
    final ids = scans.map((scan) => scan['id'] as String).toList();
    final children = await Future.wait([
      _client
          .from('scan_images')
          .select()
          .inFilter('scan_id', ids)
          .order('sort_order'),
      _client
          .from('scan_findings')
          .select()
          .inFilter('scan_id', ids)
          .order('sort_order'),
    ]);
    final images = List<Map<String, dynamic>>.from(children[0]);
    for (final image in images) {
      final path = image['image_path']?.toString() ?? '';
      if (path.startsWith('$userId/')) {
        image['image_url'] = await _client.storage
            .from(bucketName)
            .createSignedUrl(path, 3600);
      }
    }
    for (final scan in scans) {
      final scanImages = images
          .where((image) => image['scan_id'] == scan['id'])
          .toList();
      final findings = List<Map<String, dynamic>>.from(
        children[1],
      ).where((finding) => finding['scan_id'] == scan['id']).toList();
      scan['scan_images'] = scanImages;
      scan['scan_findings'] = findings;
      if (scanImages.isNotEmpty) {
        scan['image_urls'] = scanImages
            .map((image) => image['image_url'])
            .whereType<String>()
            .toList();
      }
      if ((scan['visible_findings'] as List?)?.isNotEmpty != true) {
        scan['visible_findings'] = findings
            .map((finding) => finding['title'])
            .whereType<String>()
            .toList();
      }
      final raw = scan['raw_ai_response'];
      if (raw is Map && raw['visual_assets'] is List) {
        final assets = List<Map<String, dynamic>>.from(
          (raw['visual_assets'] as List).whereType<Map>(),
        );
        for (final asset in assets) {
          final path = asset['storage_path']?.toString() ?? '';
          if (path.startsWith('$userId/')) {
            asset['url'] = await _client.storage
                .from(bucketName)
                .createSignedUrl(path, 3600);
          }
        }
        raw['visual_assets'] = assets;
      }
    }
    return scans;
  }

  Future<void> deleteScan(String scanId) async {
    final userId = _userId;
    final scan = await _client
        .from('scan_sessions')
        .select('id')
        .eq('id', scanId)
        .eq('user_id', userId)
        .single();
    final images = await _client
        .from('scan_images')
        .select('image_path')
        .eq('scan_id', scan['id']);
    final paths = images
        .map((row) => row['image_path'])
        .whereType<String>()
        .where((path) => path.startsWith('$userId/'))
        .toList();
    await removeImages(paths);
    await _client
        .from('scan_sessions')
        .delete()
        .eq('id', scanId)
        .eq('user_id', userId);
  }

  Future<Map<String, dynamic>> createScan({
    required String scanType,
    required String bodyLocation,
    required List<String> symptoms,
    required String duration,
    required String severity,
    required String notes,
    String? aiConfidence,
    String? urgency,
    String? summary,
  }) async {
    return await _client
        .from('scan_sessions')
        .insert({
          'user_id': _userId,
          'scan_type': scanType,
          'body_location': bodyLocation,
          'symptoms': symptoms,
          'duration': duration,
          'severity': severity,
          'notes': notes,
          'ai_confidence': aiConfidence,
          'urgency': urgency,
          'summary': summary,
        })
        .select()
        .single();
  }

  Future<String> uploadScanImage({
    required File file,
    required String fileName,
  }) async {
    return uploadImage(
      bytes: await file.readAsBytes(),
      fileName: fileName,
      mimeType: 'image/jpeg',
    );
  }

  Future<void> saveScanImage({
    required String scanId,
    required String imageUrl,
    required String imagePath,
  }) async {
    await _client.from('scan_images').insert({
      'scan_id': scanId,
      'image_url': imagePath,
      'image_path': imagePath,
    });
  }

  Future<void> saveFindings({
    required String scanId,
    required List<Map<String, dynamic>> findings,
  }) async {
    if (findings.isEmpty) return;
    await _client.from('scan_findings').insert([
      for (var i = 0; i < findings.length; i++)
        {
          'scan_id': scanId,
          'title': findings[i]['title'],
          'description': findings[i]['description'],
          'sort_order': i,
        },
    ]);
  }
}
