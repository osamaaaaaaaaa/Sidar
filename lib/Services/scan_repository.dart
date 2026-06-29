import 'dart:io';
import '../Models/scan_result_model.dart';
import 'scan_remote_source.dart';

class ScanRepository {
  final ScanRemoteSource remote;

  ScanRepository({required this.remote});

  Future<ScanResultModel> createScanWithImages({
    required List<File> images,
    required String scanType,
    required String bodyLocation,
    required List<String> symptoms,
    required String duration,
    required String severity,
    required String notes,
    String? aiConfidence,
    String? urgency,
    String? summary,
    List<Map<String, dynamic>> findings = const [],
  }) async {
    final scan = await remote.createScan(
      scanType: scanType,
      bodyLocation: bodyLocation,
      symptoms: symptoms,
      duration: duration,
      severity: severity,
      notes: notes,
      aiConfidence: aiConfidence,
      urgency: urgency,
      summary: summary,
    );

    final scanId = scan['id'] as String;

    for (int i = 0; i < images.length; i++) {
      final file = images[i];
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final imageUrl = await remote.uploadScanImage(
        file: file,
        fileName: fileName,
      );

      await remote.saveScanImage(
        scanId: scanId,
        imageUrl: imageUrl,
        imagePath: imageUrl,
      );
    }

    await remote.saveFindings(scanId: scanId, findings: findings);

    return ScanResultModel.fromJson(scan);
  }

  Future<List<ScanResultModel>> getScans() async {
    final rows = await remote.getScans();
    return rows.map(ScanResultModel.fromJson).toList();
  }
}
