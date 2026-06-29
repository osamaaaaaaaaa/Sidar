// // ignore_for_file: library_private_types_in_public_api

// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
// import 'dart:ui';

// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

// class ScannerView extends StatefulWidget {
//   @override
//   _ScannerViewState createState() => _ScannerViewState();
// }

// class _ScannerViewState extends State<ScannerView>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;

//   // =========================
//   // Face++ CONFIG
//   // =========================
//   static const String _faceppApiKey = "2HE6e1JY81HTGTgjOePxSUDDNc2q_sVb";
//   static const String _faceppApiSecret = "sj9qoo9JwiRwG9cjj5wm8RsYgM-QpoCg";
//   static const String _faceppEndpoint =
//       "https://api-us.faceplusplus.com/facepp/v3/detect";

//   // =========================
//   // Camera + ML Kit
//   // =========================
//   CameraController? _cam;
//   bool _camReady = false;

//   late final FaceDetector _faceDetector;

//   // =========================
//   // Auto capture
//   // =========================
//   Timer? _autoTimer;
//   int _stableHits = 0;
//   bool _busy = false;

//   // =========================
//   // UI states
//   // =========================
//   String _lightingStatus = "جارِ القياس";
//   String _faceStatus = "جارِ الرصد";
//   double _progress = 0.0;

//   @override
//   void initState() {
//     super.initState();

//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 3),
//     )..repeat(reverse: true);

//     _faceDetector = FaceDetector(
//       options: FaceDetectorOptions(
//         performanceMode: FaceDetectorMode.fast,
//         enableLandmarks: false,
//         enableContours: false,
//         enableClassification: false,
//       ),
//     );

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _initCamera();
//     });
//   }

//   @override
//   void dispose() {
//     _autoTimer?.cancel();
//     _animationController.dispose();
//     _faceDetector.close();
//     _cam?.dispose();
//     super.dispose();
//   }

//   Future<void> _initCamera() async {
//     try {
//       setState(() {
//         _busy = true;
//         _progress = 0.08;
//         _lightingStatus = "جارِ القياس";
//         _faceStatus = "جارِ الرصد";
//       });

//       final cams = await availableCameras();
//       final front = cams.firstWhere(
//         (c) => c.lensDirection == CameraLensDirection.front,
//         orElse: () => cams.first,
//       );

//       _cam = CameraController(
//         front,
//         ResolutionPreset.medium,
//         enableAudio: false,
//         imageFormatGroup: ImageFormatGroup.jpeg,
//       );

//       await _cam!.initialize();

//       if (!mounted) return;

//       setState(() {
//         _camReady = true;
//         _busy = false;
//         _progress = 0.15;
//       });

//       _startAutoCaptureLoop();
//     } catch (e) {
//       log("Camera init error: $e");
//       if (!mounted) return;

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("مش قادر أفتح الكاميرا")));
//       Get.back();
//     }
//   }

//   void _startAutoCaptureLoop() {
//     _autoTimer?.cancel();

//     // كل 800ms ناخد لقطة صغيرة ونشوف هل الوجه موجود "وبشكل مناسب"
//     _autoTimer = Timer.periodic(const Duration(milliseconds: 800), (_) async {
//       if (!mounted) return;
//       if (_busy) return;
//       if (!_camReady || _cam == null) return;

//       await _tryAutoCaptureCycle();
//     });
//   }

//   Future<void> _tryAutoCaptureCycle() async {
//     try {
//       setState(() {
//         _progress = 0.25;
//         _faceStatus = "جارِ الرصد";
//       });

//       // التقط صورة
//       final shot = await _cam!.takePicture();
//       final file = File(shot.path);

//       // Face detection على الملف مباشرة ✅
//       final input = InputImage.fromFilePath(file.path);
//       final faces = await _faceDetector.processImage(input);

//       if (faces.isEmpty) {
//         _stableHits = 0;
//         if (mounted) {
//           setState(() {
//             _faceStatus = "غير واضح";
//             _lightingStatus = "جارِ القياس";
//             _progress = 0.30;
//           });
//         }
//         return;
//       }

//       // عندنا وجه -> اعتبره داخل الإطار عمليًا (ممكن تزود تحقق أكبر لاحقًا)
//       _stableHits++;

//       if (mounted) {
//         setState(() {
//           _faceStatus = "في الإطار";
//           _lightingStatus = "تم";
//           _progress = 0.55;
//         });
//       }

//       // لازم يثبت مرتين (تقريبًا 1.6 ثانية)
//       if (_stableHits >= 2) {
//         _stableHits = 0;
//         await _autoCaptureAndAnalyzeFinal(file);
//       }
//     } catch (_) {
//       _stableHits = 0;
//     }
//   }

//   Future<void> _autoCaptureAndAnalyzeFinal(File file) async {
//     if (_busy) return;

//     setState(() {
//       _busy = true;
//       _faceStatus = "رفع الصورة";
//       _progress = 0.75;
//     });

//     try {
//       final result = await _analyzeWithFacePP(file);

//       setState(() {
//         _faceStatus = "تم";
//         _progress = 1.0;
//       });

//       log("Face++ analysis result: $result");

//       // لو عندك صفحة نتائج:
//       // Get.toNamed('/results', arguments: result);
//     } catch (e) {
//       log("ScannerView error: $e");
//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("حصل خطأ أثناء التحليل. حاول تاني.")),
//       );
//     } finally {
//       if (!mounted) return;

//       setState(() {
//         _busy = false;
//         _progress = 0.35;
//         _faceStatus = "جارِ الرصد";
//       });
//     }
//   }

//   Future<Map<String, dynamic>> _analyzeWithFacePP(File imageFile) async {
//     if (_faceppApiKey.contains("PUT_") || _faceppApiSecret.contains("PUT_")) {
//       throw Exception("Missing Face++ api_key/api_secret");
//     }

//     final uri = Uri.parse(_faceppEndpoint);
//     final request = http.MultipartRequest("POST", uri);

//     request.fields["api_key"] = _faceppApiKey;
//     request.fields["api_secret"] = _faceppApiSecret;

//     // ✅ ده اللي طلع معاك: attributes.skinstatus.*
//     request.fields["return_attributes"] = "skinstatus";

//     request.files.add(
//       await http.MultipartFile.fromPath("image_file", imageFile.path),
//     );

//     setState(() {
//       _faceStatus = "انتظار النتيجة";
//       _progress = 0.85;
//     });

//     final streamed = await request.send();
//     final body = await streamed.stream.bytesToString();

//     final jsonMap = json.decode(body) as Map<String, dynamic>;

//     if (streamed.statusCode != 200) {
//       final err = jsonMap["error_message"] ?? "Unknown error";
//       throw Exception("Face++ error: $err");
//     }

//     // لو حابب تشوف الخام:
//     // log("Raw Face++ response: $jsonMap");

//     return _mapFaceppResponse(jsonMap);
//   }

//   Map<String, dynamic> _mapFaceppResponse(Map<String, dynamic> raw) {
//     final faces = (raw["faces"] is List) ? (raw["faces"] as List) : const [];
//     if (faces.isEmpty) {
//       return {
//         "score": 0,
//         "health": null,
//         "stain": null,
//         "darkCircle": null,
//         "acne": null,
//         "raw": raw,
//       };
//     }

//     final face0 = faces.first as Map<String, dynamic>;
//     final attrs = (face0["attributes"] is Map<String, dynamic>)
//         ? (face0["attributes"] as Map<String, dynamic>)
//         : <String, dynamic>{};

//     final skinstatus = (attrs["skinstatus"] is Map<String, dynamic>)
//         ? (attrs["skinstatus"] as Map<String, dynamic>)
//         : <String, dynamic>{};

//     double? n(dynamic v) => v is num ? v.toDouble() : null;

//     final health = n(skinstatus["health"]);
//     final stain = n(skinstatus["stain"]);
//     final darkCircle = n(skinstatus["dark_circle"]);
//     final acne = n(skinstatus["acne"]);

//     // Score robust:
//     int score;
//     if (health == null) {
//       final penalty =
//           (acne ?? 0) * 0.45 + (stain ?? 0) * 0.35 + (darkCircle ?? 0) * 0.20;
//       score = (100 - penalty).clamp(0, 100).round();
//     } else {
//       final normalized = health <= 10 ? (health * 10) : health;
//       score = normalized.clamp(0, 100).round();
//     }

//     return {
//       "score": score,
//       "health": health,
//       "stain": stain,
//       "darkCircle": darkCircle,
//       "acne": acne,
//       "raw": raw,
//     };
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           // ✅ كاميرا لايف
//           if (_camReady && _cam != null)
//             SizedBox.expand(child: CameraPreview(_cam!))
//           else
//             Container(
//               width: double.infinity,
//               height: double.infinity,
//               color: Colors.black,
//             ),

//           _buildScannerOverlay(),

//           AnimatedBuilder(
//             animation: _animationController,
//             builder: (context, child) {
//               return Positioned(
//                 top:
//                     MediaQuery.of(context).size.height *
//                     _animationController.value,
//                 left: 0,
//                 right: 0,
//                 child: _buildScanningLine(),
//               );
//             },
//           ),

//           _buildUIElements(),
//         ],
//       ),
//     );
//   }

//   Widget _buildScannerOverlay() {
//     return CustomPaint(
//       painter: ScannerPainter(),
//       child: Container(
//         decoration: BoxDecoration(
//           backgroundBlendMode: BlendMode.overlay,
//           color: Colors.blue.withOpacity(0.05),
//         ),
//       ),
//     );
//   }

//   Widget _buildScanningLine() {
//     return Container(
//       height: 100,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [
//             Colors.transparent,
//             Colors.blueAccent.withOpacity(0.5),
//             Colors.white.withOpacity(0.8),
//             Colors.transparent,
//           ],
//         ),
//       ),
//       child: const Divider(
//         color: Colors.white,
//         thickness: 1,
//         indent: 20,
//         endIndent: 20,
//       ),
//     );
//   }

//   Widget _buildUIElements() {
//     return SafeArea(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           // شريط علوي
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.close, color: Colors.white, size: 30),
//                   onPressed: () => Get.back(),
//                 ),
//                 const Text(
//                   "جاري التحليل...",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.w300,
//                     letterSpacing: 2,
//                   ),
//                 ),
//                 const Icon(Icons.flash_on, color: Colors.white70),
//               ],
//             ),
//           ),

//           // منطقة التركيز في المنتصف (Frame)
//           Container(
//             width: 280,
//             height: 380,
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.white24, width: 1),
//               borderRadius: BorderRadius.circular(150),
//             ),
//           ),

//           // البطاقة السفلية الذكية
//           _buildBottomAnalysisCard(),
//         ],
//       ),
//     );
//   }

//   Widget _buildBottomAnalysisCard() {
//     return ClipRRect(
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
//         child: Container(
//           width: double.infinity,
//           padding: const EdgeInsets.all(30),
//           decoration: BoxDecoration(
//             color: Colors.black.withOpacity(0.5),
//             borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 "ضع وجهك داخل الإطار",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               LinearProgressIndicator(
//                 backgroundColor: Colors.white10,
//                 color: Colors.blueAccent,
//                 minHeight: 2,
//                 value: (_progress <= 0) ? null : _progress.clamp(0.0, 1.0),
//               ),
//               const SizedBox(height: 20),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   _statusIndicator("الإضاءة", _lightingStatus, Icons.wb_sunny),
//                   _statusIndicator("الوجه", _faceStatus, Icons.face),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _statusIndicator(String label, String status, IconData icon) {
//     return Row(
//       children: [
//         Icon(icon, color: Colors.white54, size: 16),
//         const SizedBox(width: 8),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               label,
//               style: const TextStyle(color: Colors.white38, fontSize: 10),
//             ),
//             Text(
//               status,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

// // الرسام الخاص بالشبكة العصبية الوهمية
// class ScannerPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.white10
//       ..strokeWidth = 0.5;

//     for (var i = 0; i < size.width; i += 40) {
//       canvas.drawLine(
//         Offset(i.toDouble(), 0),
//         Offset(i.toDouble(), size.height),
//         paint,
//       );
//     }
//     for (var i = 0; i < size.height; i += 40) {
//       canvas.drawLine(
//         Offset(0, i.toDouble()),
//         Offset(size.width, i.toDouble()),
//         paint,
//       );
//     }
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => false;
// }
