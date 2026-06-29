class ScanFindingModel {
  final String id;
  final String scanId;
  final String title;
  final String? description;
  final int sortOrder;

  ScanFindingModel({
    required this.id,
    required this.scanId,
    required this.title,
    this.description,
    required this.sortOrder,
  });

  factory ScanFindingModel.fromJson(Map<String, dynamic> json) {
    return ScanFindingModel(
      id: json['id'] as String,
      scanId: json['scan_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      sortOrder: (json['sort_order'] ?? 0) as int,
    );
  }
}
