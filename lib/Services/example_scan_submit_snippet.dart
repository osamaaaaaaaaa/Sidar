// import 'dart:io';
// import 'package:get/get.dart';
// import 'scan_controller.dart';

// Future<void> exampleSubmit({
//   required List<File> selectedFiles,
//   required String selectedScanType,
//   required String selectedBodyLocation,
//   required List<String> selectedSymptoms,
//   required String selectedDuration,
//   required String selectedSeverity,
//   required String notes,
// }) async {
//   final controller = Get.find<ScanController>();

//   await controller.submitScan(
//     images: selectedFiles,
//     scanType: selectedScanType,
//     bodyLocation: selectedBodyLocation,
//     symptoms: selectedSymptoms,
//     duration: selectedDuration,
//     severity: selectedSeverity,
//     notes: notes,
//     aiConfidence: 87.5,
//     casePriority: 'Medium',
//     summary: 'Visible irritation and uneven texture detected.',
//     findings: const [
//       {
//         'title': 'Texture variation',
//         'description': 'Some areas appear uneven in tone and texture.',
//         'sort_order': 1,
//       },
//       {
//         'title': 'Mild redness',
//         'description': 'Light redness visible around the selected area.',
//         'sort_order': 2,
//       },
//     ],
//   );
// }
