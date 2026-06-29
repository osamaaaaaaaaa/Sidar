class ScanResultModel {
  final String id;
  final String? userId;
  final String scanType;
  final String bodyLocation;
  final List<String> symptoms;
  final String? duration;
  final String? severity;
  final String? notes;
  final String? aiConfidence;
  final String? urgency;
  final String? summary;
  final DateTime? createdAt;

  ScanResultModel({
    required this.id,
    this.userId,
    required this.scanType,
    required this.bodyLocation,
    required this.symptoms,
    this.duration,
    this.severity,
    this.notes,
    this.aiConfidence,
    this.urgency,
    this.summary,
    this.createdAt,
  });

  factory ScanResultModel.fromJson(Map<String, dynamic> json) {
    return ScanResultModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      scanType: json['scan_type'] as String,
      bodyLocation: json['body_location'] as String,
      symptoms: List<String>.from(json['symptoms'] ?? []),
      duration: json['duration'] as String?,
      severity: json['severity'] as String?,
      notes: json['notes'] as String?,
      aiConfidence: json['ai_confidence']?.toString(),
      urgency: json['urgency'] as String?,
      summary: json['summary'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'scan_type': scanType,
      'body_location': bodyLocation,
      'symptoms': symptoms,
      'duration': duration,
      'severity': severity,
      'notes': notes,
      'ai_confidence': aiConfidence,
      'urgency': urgency,
      'summary': summary,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
