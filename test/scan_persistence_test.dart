import 'package:flutter_test/flutter_test.dart';
import 'package:skincare/Models/ScanAiModel.dart';
import 'package:skincare/Services/scan_remote_source.dart';

void main() {
  const result = ScanAiResult(
    title: 'Dryness review',
    summary: 'Gentle care recommended.',
    visibleFindings: ['Dry patches'],
    careSteps: ['Avoid irritants'],
    urgency: 'high',
    shouldSeeDoctor: true,
    reasons: ['Persistent irritation'],
    imageQuality: 'Low',
    disclaimer: 'Not a diagnosis.',
    analysisTarget: 'skin',
    aiConfidence: '82%',
    overallScore: 67,
    hydrationScore: 41,
    morningRoutine: ['Use sunscreen'],
    eveningRoutine: ['Moisturize'],
  );
  final input = <String, dynamic>{
    'scan_type': 'skin_check',
    'body_location': 'face',
    'symptoms': ['dryness'],
    'duration': 'one_week',
    'severity': 'moderate',
    'notes': 'Visible irritation',
    'issue_type': 'dryness',
    'skin_type_context': 'dry',
    'location_text': 'eg',
    'location_label': 'Egypt',
    'image_focus_areas': [
      {'file_name': 'skin.png', 'selected': true},
    ],
  };

  Map<String, dynamic> payload() => ScanRemoteSource.buildScanPayload(
    result: result,
    input: input,
    userId: 'test-user',
    languageCode: 'en',
    imageCount: 2,
    createdAt: DateTime.utc(2026, 11, 10, 12),
  );

  test(
    'session columns match website schema without provider-only columns',
    () {
      final row = payload();
      expect(row['user_id'], 'test-user');
      expect(row['status'], 'completed');
      expect(row['report_title'], 'Dryness review');
      expect(row['concern_category'], 'dry');
      expect(row['images_count'], 2);
      expect(row['image_urls'], isEmpty);
      expect(row.containsKey('should_see_doctor'), isFalse);
      expect(row.containsKey('visible_patterns'), isFalse);
      expect(row['overall_score'], 67);
      expect(row['hair_density_score'], isNull);
      expect(row['created_at'], '2026-11-10T12:00:00.000Z');
    },
  );

  test('saved payload round-trips priority, quality, routines and date', () {
    final restored = ScanAiResult.fromJson(payload());
    expect(restored.urgency, 'high');
    expect(restored.shouldSeeDoctor, isTrue);
    expect(restored.imageQuality, 'Low');
    expect(restored.summary, result.summary);
    expect(restored.visibleFindingsByLang('ar'), ['Dry patches']);
    expect(restored.careStepsByLang('en'), ['Avoid irritants']);
    expect(restored.morningRoutine, ['Use sunscreen']);
    expect(restored.eveningRoutine, ['Moisturize']);
    expect(restored.overallScore, 67);
    expect(restored.createdAt, DateTime.utc(2026, 11, 10, 12));
  });

  test('private paths and focus selections are not public URLs', () {
    final row = payload();
    expect(row['image_urls'], isEmpty);
    final raw = row['raw_ai_response'] as Map<String, dynamic>;
    expect(raw['location_text'], 'eg');
    expect((raw['image_focus_areas'] as List).single['selected'], isTrue);
    expect(row['natural_product_suggestions'], isEmpty);
  });
}
