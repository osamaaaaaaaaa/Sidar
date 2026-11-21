class ScanAiResult {
  final String summary;
  final List<String> visibleFindings;
  final List<String> careSteps;
  final String urgency;
  final bool shouldSeeDoctor;
  final List<String> reasons;
  final String imageQuality;
  final String disclaimer;
  final String title;
  final String analysisTarget;
  final String aiConfidence;
  final double? overallScore;
  final double? hydrationScore;
  final double? poreClarityScore;
  final double? fineLinesScore;
  final double? overallToneScore;
  final double? hairDensityScore;
  final double? hairTextureScore;
  final double? hairStrengthScore;
  final double? scalpHealthScore;
  final List<String> morningRoutine;
  final List<String> eveningRoutine;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> doctors;

  /// Provider-backed visual maps only. Each item keeps the provider metric,
  /// asset kind and the private-storage path used to regenerate access URLs.
  final List<Map<String, dynamic>> visualAssets;
  final DateTime? createdAt;

  // Retained for reports saved by older bilingual mobile clients.
  final String? summaryAr;
  final String? summaryEn;
  final List<String>? visibleFindingsAr;
  final List<String>? visibleFindingsEn;
  final List<String>? careStepsAr;
  final List<String>? careStepsEn;
  final List<String>? reasonsAr;
  final List<String>? reasonsEn;
  final String? imageQualityAr;
  final String? imageQualityEn;
  final String? disclaimerAr;
  final String? disclaimerEn;

  const ScanAiResult({
    required this.summary,
    required this.visibleFindings,
    required this.careSteps,
    required this.urgency,
    required this.shouldSeeDoctor,
    required this.reasons,
    required this.imageQuality,
    required this.disclaimer,
    this.title = '',
    this.analysisTarget = 'skin',
    this.aiConfidence = '',
    this.overallScore,
    this.hydrationScore,
    this.poreClarityScore,
    this.fineLinesScore,
    this.overallToneScore,
    this.hairDensityScore,
    this.hairTextureScore,
    this.hairStrengthScore,
    this.scalpHealthScore,
    this.morningRoutine = const [],
    this.eveningRoutine = const [],
    this.products = const [],
    this.doctors = const [],
    this.visualAssets = const [],
    this.createdAt,
    this.summaryAr,
    this.summaryEn,
    this.visibleFindingsAr,
    this.visibleFindingsEn,
    this.careStepsAr,
    this.careStepsEn,
    this.reasonsAr,
    this.reasonsEn,
    this.imageQualityAr,
    this.imageQualityEn,
    this.disclaimerAr,
    this.disclaimerEn,
  });

  // Resolve row aliases first so partial raw responses cannot override saved fields.
  factory ScanAiResult.fromJson(Map<String, dynamic> json) {
    final raw = json['raw_ai_response'];
    final rawAi = raw is Map ? raw : const <String, dynamic>{};

    dynamic pick(List<String> keys) {
      for (final source in [json, rawAi]) {
        for (final key in keys) {
          // An explicit null/empty persisted value must not revive stale raw data.
          if (source.containsKey(key)) return source[key];
        }
      }
      return null;
    }

    String text(List<String> keys) {
      for (final source in [json, rawAi]) {
        var present = false;
        for (final key in keys) {
          if (!source.containsKey(key)) continue;
          present = true;
          final value = (source[key] ?? '').toString().trim();
          if (value.isNotEmpty) return value;
        }
        // Nullable row aliases (e.g. report_title) can fall back to another
        // row alias (title), but not to stale provider text in raw_ai_response.
        if (present) return '';
      }
      return '';
    }

    String? localizedText(String key) {
      final value = text([key]);
      return value.isEmpty ? null : value;
    }

    List<String>? localizedList(String key) {
      final value = _strings(pick([key]));
      return value.isEmpty ? null : value;
    }

    double? score(String snakeKey, String camelKey) {
      final value = pick([snakeKey, camelKey]);
      if (value == null || value is bool) return null;
      final number = value is num
          ? value.toDouble()
          : double.tryParse(value.toString().trim());
      return number != null && number.isFinite
          ? number.clamp(0, 100).toDouble()
          : null;
    }

    final priority = text(['urgency', 'case_priority']).toLowerCase();
    final urgency = switch (priority) {
      'high' || 'urgent' => 'high',
      'low' => 'low',
      _ => 'medium',
    };
    final target = text(['analysis_target', 'analysisTarget']).toLowerCase();
    final scanType = text(['scan_type']);
    final inferredTarget =
        scanType == 'hair_check' ||
            scanType == 'scalp_check' ||
            text(['body_location']) == 'scalp'
        ? 'hair'
        : 'skin';
    final created = pick(['created_at', 'createdAt']);

    return ScanAiResult(
      summary: text(['summary', 'guidance', 'problem_description']),
      visibleFindings: _strings(
        pick(['visible_findings', 'visibleFindings', 'visible_patterns']),
      ),
      careSteps: _strings(pick(['care_steps', 'careSteps', 'next_steps'])),
      urgency: urgency,
      shouldSeeDoctor:
          urgency == 'high' ||
          pick(['should_see_doctor', 'shouldSeeDoctor']) == true,
      reasons: _strings(pick(['reasons'])),
      imageQuality: text(['image_quality', 'imageQuality']),
      disclaimer: text(['disclaimer']),
      title: text(['report_title', 'title']),
      analysisTarget: ['skin', 'hair', 'both'].contains(target)
          ? target
          : inferredTarget,
      aiConfidence: text(['ai_confidence', 'aiConfidence']),
      overallScore: score('overall_score', 'overallScore'),
      hydrationScore: score('hydration_score', 'hydrationScore'),
      poreClarityScore: score('pore_clarity_score', 'poreClarityScore'),
      fineLinesScore: score('fine_lines_score', 'fineLinesScore'),
      overallToneScore: score('overall_tone_score', 'overallToneScore'),
      hairDensityScore: score('hair_density_score', 'hairDensityScore'),
      hairTextureScore: score('hair_texture_score', 'hairTextureScore'),
      hairStrengthScore: score('hair_strength_score', 'hairStrengthScore'),
      scalpHealthScore: score('scalp_health_score', 'scalpHealthScore'),
      morningRoutine: _strings(pick(['morning_routine', 'morningRoutine'])),
      eveningRoutine: _strings(pick(['evening_routine', 'eveningRoutine'])),
      products: _records(pick(['commercial_product_suggestions', 'products'])),
      doctors: _records(pick(['nearby_doctors', 'doctors'])),
      visualAssets: _records(pick(['visual_assets', 'visualAssets'])),
      createdAt: created is DateTime
          ? created
          : DateTime.tryParse((created ?? '').toString()),
      summaryAr: localizedText('summary_ar'),
      summaryEn: localizedText('summary_en'),
      visibleFindingsAr: localizedList('visible_findings_ar'),
      visibleFindingsEn: localizedList('visible_findings_en'),
      careStepsAr: localizedList('care_steps_ar'),
      careStepsEn: localizedList('care_steps_en'),
      reasonsAr: localizedList('reasons_ar'),
      reasonsEn: localizedList('reasons_en'),
      imageQualityAr: localizedText('image_quality_ar'),
      imageQualityEn: localizedText('image_quality_en'),
      disclaimerAr: localizedText('disclaimer_ar'),
      disclaimerEn: localizedText('disclaimer_en'),
    );
  }

  static List<String> _strings(dynamic value) => value is List
      ? value
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList()
      : [];

  static List<Map<String, dynamic>> _records(dynamic value) => value is List
      ? value
            .whereType<Map>()
            // Historical AI-generated objects without a database ID are not
            // catalog records and must not become product/doctor suggestions.
            .where((item) => (item['id'] ?? '').toString().trim().isNotEmpty)
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : [];

  String _localizedText(
    String languageCode,
    String? ar,
    String? en,
    String base,
  ) {
    final value = languageCode.toLowerCase().startsWith('ar') ? ar : en;
    return value == null || value.trim().isEmpty ? base.trim() : value.trim();
  }

  List<String> _localizedList(
    String languageCode,
    List<String>? ar,
    List<String>? en,
    List<String> base,
  ) {
    final value = _strings(
      languageCode.toLowerCase().startsWith('ar') ? ar : en,
    );
    return value.isEmpty ? _strings(base) : value;
  }

  String summaryByLang(String languageCode) =>
      _localizedText(languageCode, summaryAr, summaryEn, summary);

  List<String> visibleFindingsByLang(String languageCode) => _localizedList(
    languageCode,
    visibleFindingsAr,
    visibleFindingsEn,
    visibleFindings,
  );

  List<String> careStepsByLang(String languageCode) =>
      _localizedList(languageCode, careStepsAr, careStepsEn, careSteps);

  List<String> reasonsByLang(String languageCode) =>
      _localizedList(languageCode, reasonsAr, reasonsEn, reasons);

  String imageQualityByLang(String languageCode) => _localizedText(
    languageCode,
    imageQualityAr,
    imageQualityEn,
    imageQuality,
  );

  String disclaimerByLang(String languageCode) =>
      _localizedText(languageCode, disclaimerAr, disclaimerEn, disclaimer);

  /// Canonical scan_sessions row fields, not the provider's response shape.
  Map<String, dynamic> toJson() => {
    'title': title,
    'report_title': title,
    'analysis_target': analysisTarget,
    'ai_confidence': aiConfidence,
    'summary': summary,
    'problem_description': summary,
    'visible_findings': visibleFindings,
    'care_steps': careSteps,
    'urgency': urgency,
    'should_see_doctor': shouldSeeDoctor,
    'reasons': reasons,
    'image_quality': imageQuality,
    'disclaimer': disclaimer,
    'overall_score': overallScore,
    'hydration_score': hydrationScore,
    'pore_clarity_score': poreClarityScore,
    'fine_lines_score': fineLinesScore,
    'overall_tone_score': overallToneScore,
    'hair_density_score': hairDensityScore,
    'hair_texture_score': hairTextureScore,
    'hair_strength_score': hairStrengthScore,
    'scalp_health_score': scalpHealthScore,
    'morning_routine': morningRoutine,
    'evening_routine': eveningRoutine,
    'natural_product_suggestions': const <Map<String, dynamic>>[],
    'commercial_product_suggestions': products,
    'nearby_doctors': doctors,
    'visual_assets': visualAssets,
    'created_at': createdAt?.toIso8601String(),
    'summary_ar': summaryAr,
    'summary_en': summaryEn,
    'visible_findings_ar': visibleFindingsAr,
    'visible_findings_en': visibleFindingsEn,
    'care_steps_ar': careStepsAr,
    'care_steps_en': careStepsEn,
    'reasons_ar': reasonsAr,
    'reasons_en': reasonsEn,
    'image_quality_ar': imageQualityAr,
    'image_quality_en': imageQualityEn,
    'disclaimer_ar': disclaimerAr,
    'disclaimer_en': disclaimerEn,
  };
}
