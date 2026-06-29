import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:skincare/Utils/AppTheme.dart';

/// An in-app camera used for scans. Face detection only drives the visual
/// framing guide; captured images are not analysed or uploaded on this page.
class LiveScanCameraView extends StatefulWidget {
  const LiveScanCameraView({super.key, required this.faceGuide});

  final bool faceGuide;

  @override
  State<LiveScanCameraView> createState() => _LiveScanCameraViewState();
}

class _LiveScanCameraViewState extends State<LiveScanCameraView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = const [];
  CameraLensDirection _activeLens = CameraLensDirection.front;
  FaceMeshDetector? _meshDetector;
  late final AnimationController _scanAnimation;
  FaceMesh? _faceMesh;
  Size? _sourceSize;
  InputImageRotation? _imageRotationForPreview;
  bool _processingFrame = false;
  bool _takingPicture = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid) {
      _meshDetector = FaceMeshDetector(
        option: FaceMeshDetectorOptions.faceMesh,
      );
    }
    _scanAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    unawaited(_initializeCamera());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      unawaited(controller.dispose());
      _cameraController = null;
    } else if (state == AppLifecycleState.resumed &&
        _cameraController == null) {
      unawaited(_initializeCamera());
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      final selectedCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == _activeLens,
        orElse: () => _cameras.first,
      );
      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _cameraController = controller;
      if (widget.faceGuide && _meshDetector != null) {
        await controller.startImageStream(_processCameraImage);
      }
      if (mounted) setState(() {});
    } on CameraException catch (error) {
      if (mounted) setState(() => _error = _cameraErrorText(error));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'تعذر تشغيل الكاميرا. تحقق من إذن الكاميرا وحاول مجددًا.',
        );
      }
    }
  }

  String _cameraErrorText(CameraException error) {
    if (error.code == 'CameraAccessDenied' ||
        error.code == 'CameraAccessDeniedWithoutPrompt') {
      return 'يرجى السماح للتطبيق باستخدام الكاميرا لإتمام الفحص.';
    }
    return 'تعذر تشغيل الكاميرا. حاول مجددًا.';
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_processingFrame || !mounted) return;
    final detector = _meshDetector;
    final inputImage = _toInputImage(image);
    if (detector == null || inputImage == null) return;
    _processingFrame = true;
    try {
      final meshes = await detector.processImage(inputImage);
      if (mounted) {
        setState(() {
          _faceMesh = meshes.isEmpty ? null : meshes.first;
          _sourceSize = Size(image.width.toDouble(), image.height.toDouble());
          _imageRotationForPreview = _imageRotation(_cameraController!);
        });
      }
    } catch (_) {
      // The visual guide is optional. A supported camera can still capture.
    } finally {
      _processingFrame = false;
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    final controller = _cameraController;
    if (controller == null || image.planes.isEmpty) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    final rotation = _imageRotation(controller);
    if (format == null ||
        rotation == null ||
        image.planes.length != 1 ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }
    return InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  InputImageRotation? _imageRotation(CameraController controller) {
    final sensorOrientation = controller.description.sensorOrientation;
    if (Platform.isIOS) {
      return InputImageRotationValue.fromRawValue(sensorOrientation);
    }
    if (!Platform.isAndroid) return null;
    final orientationCompensation =
        switch (controller.value.deviceOrientation) {
          DeviceOrientation.portraitUp => 0,
          DeviceOrientation.landscapeLeft => 90,
          DeviceOrientation.portraitDown => 180,
          DeviceOrientation.landscapeRight => 270,
        };
    final compensation =
        controller.description.lensDirection == CameraLensDirection.front
        ? (sensorOrientation + orientationCompensation) % 360
        : (sensorOrientation - orientationCompensation + 360) % 360;
    return InputImageRotationValue.fromRawValue(compensation);
  }

  Future<void> _takePicture() async {
    final controller = _cameraController;
    if (controller == null ||
        _takingPicture ||
        !controller.value.isInitialized) {
      return;
    }
    setState(() => _takingPicture = true);
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      final picture = await controller.takePicture();
      if (mounted) Navigator.of(context).pop<XFile>(picture);
    } on CameraException catch (error) {
      if (mounted) setState(() => _error = _cameraErrorText(error));
    } finally {
      if (mounted) setState(() => _takingPicture = false);
    }
  }

  bool get _canSwitchCamera =>
      _cameras.any(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      ) &&
      _cameras.any(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );

  Future<void> _switchCamera() async {
    if (!_canSwitchCamera || _takingPicture) return;
    final controller = _cameraController;
    if (controller == null) return;
    setState(() {
      _activeLens = _activeLens == CameraLensDirection.front
          ? CameraLensDirection.back
          : CameraLensDirection.front;
      _cameraController = null;
      _faceMesh = null;
    });
    await controller.dispose();
    if (mounted) await _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanAnimation.dispose();
    unawaited(_meshDetector?.close());
    unawaited(_cameraController?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraController;
    return Scaffold(
      backgroundColor: const Color(0xFF071815),
      body: SafeArea(
        child: _error != null
            ? _CameraError(
                message: _error!,
                onBack: () => Navigator.pop(context),
              )
            : controller == null || !controller.value.isInitialized
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: _portraitPreviewAspectRatio(controller),
                      child: CameraPreview(controller),
                    ),
                  ),
                  IgnorePointer(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: _portraitPreviewAspectRatio(controller),
                        child: AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, _) => CustomPaint(
                            painter: _FaceScanPainter(
                              progress: _scanAnimation.value,
                              mesh: _faceMesh,
                              sourceSize: _sourceSize,
                              rotation: _imageRotationForPreview,
                              lensDirection:
                                  controller.description.lensDirection,
                              showFaceGuide: widget.faceGuide,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _topBar(),
                  _bottomControls(),
                ],
              ),
      ),
    );
  }

  double _portraitPreviewAspectRatio(CameraController controller) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null || previewSize.width == 0) return 9 / 16;
    // Camera preview frames are landscape dimensions even while the phone is
    // portrait. Swapping them preserves the whole frame instead of cropping it.
    return previewSize.height / previewSize.width;
  }

  Widget _topBar() => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(18, 12, 18, 0),
    child: Align(
      alignment: AlignmentDirectional.topStart,
      child: Row(
        children: [
          _roundButton(
            icon: Icons.close_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          if (_canSwitchCamera) ...[
            _roundButton(
              icon: Icons.flip_camera_ios_rounded,
              onTap: _switchCamera,
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    ),
  );

  Widget _bottomControls() => Align(
    alignment: Alignment.bottomCenter,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(26, 0, 26, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.faceGuide
                ? (_faceMesh == null
                      ? 'وجّه وجهك داخل الإطار'
                      : 'تم رصد الوجه — ثبّت الكاميرا ثم التقط الصورة')
                : 'ثبّت الجزء المراد فحصه داخل الإطار',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontFamily: AppTheme.appFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(color: Colors.black, blurRadius: 8)],
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: _takePicture,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                color: Colors.white.withValues(alpha: 0.14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _takingPicture ? AppColors.gold : Colors.white,
                  ),
                  child: _takingPicture
                      ? const Padding(
                          padding: EdgeInsets.all(18),
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(
                          Icons.camera_alt_rounded,
                          color: AppColors.primary,
                          size: 29,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _roundButton({required IconData icon, required VoidCallback onTap}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      );
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.camera_alt_outlined,
            color: AppColors.gold,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontFamily: AppTheme.appFontFamily,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: onBack, child: const Text('رجوع')),
        ],
      ),
    ),
  );
}

class _FaceScanPainter extends CustomPainter {
  const _FaceScanPainter({
    required this.progress,
    required this.mesh,
    required this.sourceSize,
    required this.rotation,
    required this.lensDirection,
    required this.showFaceGuide,
  });

  final double progress;
  final FaceMesh? mesh;
  final Size? sourceSize;
  final InputImageRotation? rotation;
  final CameraLensDirection lensDirection;
  final bool showFaceGuide;

  @override
  void paint(Canvas canvas, Size size) {
    if (!showFaceGuide ||
        mesh == null ||
        sourceSize == null ||
        rotation == null) {
      return;
    }
    final translatedPoints = <int, Offset>{
      for (final point in mesh!.points)
        point.index: _translate(point.x, point.y, size),
    };
    final points = translatedPoints.values
        .where((point) => (Offset.zero & size).contains(point))
        .toList();
    if (points.length < 3) return;

    final faceBounds = _boundsFor(points);
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .55
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF75FBC1).withValues(alpha: .42);
    final contourPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF55FFA9).withValues(alpha: .88);
    final dotPaint = Paint()
      ..color = const Color(0xFF65FFB8).withValues(alpha: .9);

    // ML Kit supplies the actual 468 points and their triangle topology.
    // A selective sample keeps the mesh readable on a phone screen while
    // preserving the true geometry and all key facial contours below.
    for (
      var triangleIndex = 0;
      triangleIndex < mesh!.triangles.length;
      triangleIndex += 3
    ) {
      final triangle = mesh!.triangles[triangleIndex];
      if (triangle.points.length != 3) continue;
      final trianglePoints = triangle.points
          .map((point) => translatedPoints[point.index])
          .toList();
      if (trianglePoints.any((point) => point == null)) continue;
      final path = Path()
        ..moveTo(trianglePoints[0]!.dx, trianglePoints[0]!.dy)
        ..lineTo(trianglePoints[1]!.dx, trianglePoints[1]!.dy)
        ..lineTo(trianglePoints[2]!.dx, trianglePoints[2]!.dy)
        ..close();
      canvas.drawPath(path, linePaint);
    }
    for (var pointIndex = 0; pointIndex < points.length; pointIndex += 2) {
      canvas.drawCircle(points[pointIndex], .75, dotPaint);
    }
    _drawFeatureContours(canvas, translatedPoints, contourPaint);

    final scanY = faceBounds.top + faceBounds.height * progress;
    final scanPaint = Paint()
      ..shader =
          LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFF5CFFB3).withValues(alpha: .94),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromLTWH(faceBounds.left, scanY - 2, faceBounds.width, 4),
          );
    canvas.drawRect(
      Rect.fromLTWH(faceBounds.left, scanY - 1, faceBounds.width, 3),
      scanPaint,
    );
  }

  void _drawFeatureContours(
    Canvas canvas,
    Map<int, Offset> translatedPoints,
    Paint paint,
  ) {
    const highlightedFeatures = [
      FaceMeshContourType.faceOval,
      FaceMeshContourType.leftEyebrowTop,
      FaceMeshContourType.rightEyebrowTop,
      FaceMeshContourType.leftEye,
      FaceMeshContourType.rightEye,
      FaceMeshContourType.noseBridge,
      FaceMeshContourType.upperLipTop,
      FaceMeshContourType.lowerLipBottom,
    ];
    for (final feature in highlightedFeatures) {
      final contour = mesh!.contours[feature];
      if (contour == null || contour.length < 2) continue;
      final first = translatedPoints[contour.first.index];
      if (first == null) continue;
      final path = Path()..moveTo(first.dx, first.dy);
      for (final point in contour.skip(1)) {
        final translated = translatedPoints[point.index];
        if (translated != null) path.lineTo(translated.dx, translated.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  Offset _translate(double x, double y, Size canvasSize) {
    final source = sourceSize!;
    // Use the same coordinate conversion as the ML Kit camera example. ML Kit
    // already applies the image rotation while producing mesh coordinates;
    // swapping x/y here moves the mesh away from the actual face.
    return switch (rotation!) {
      InputImageRotation.rotation90deg => Offset(
        x * canvasSize.width / source.height,
        y * canvasSize.height / source.width,
      ),
      InputImageRotation.rotation270deg => Offset(
        canvasSize.width - (x * canvasSize.width / source.height),
        y * canvasSize.height / source.width,
      ),
      InputImageRotation.rotation180deg => Offset(
        lensDirection == CameraLensDirection.back
            ? x * canvasSize.width / source.width
            : canvasSize.width - (x * canvasSize.width / source.width),
        canvasSize.height - (y * canvasSize.height / source.height),
      ),
      InputImageRotation.rotation0deg => Offset(
        lensDirection == CameraLensDirection.back
            ? x * canvasSize.width / source.width
            : canvasSize.width - (x * canvasSize.width / source.width),
        y * canvasSize.height / source.height,
      ),
    };
  }

  Rect _boundsFor(List<Offset> points) {
    var left = points.first.dx;
    var right = left;
    var top = points.first.dy;
    var bottom = top;
    for (final point in points.skip(1)) {
      left = left < point.dx ? left : point.dx;
      right = right > point.dx ? right : point.dx;
      top = top < point.dy ? top : point.dy;
      bottom = bottom > point.dy ? bottom : point.dy;
    }
    return Rect.fromLTRB(left, top, right, bottom).inflate(8);
  }

  @override
  bool shouldRepaint(covariant _FaceScanPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.mesh != mesh ||
      oldDelegate.sourceSize != sourceSize ||
      oldDelegate.rotation != rotation ||
      oldDelegate.lensDirection != lensDirection;
}
