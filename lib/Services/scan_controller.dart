import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skincare/Services/app_feedback.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skincare/Controllers/HomeController.dart';
import 'package:skincare/Models/ScanAiModel.dart';
import 'package:skincare/Services/ScanAiServices.dart';
import 'package:skincare/Services/scan_remote_source.dart';
import 'package:skincare/Services/profile_values.dart';
import 'package:skincare/Views/Home/Analysis.Resulat.dart';
import 'package:skincare/Views/Home/live_scan_camera_view.dart';

class LocalScanImage {
  final XFile file;
  final Uint8List bytes;
  final String mimeType;
  final Uint8List? focusBytes;

  const LocalScanImage({
    required this.file,
    required this.bytes,
    required this.mimeType,
    this.focusBytes,
  });
}

class ScanController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;
  final ScanRemoteSource _remote = ScanRemoteSource();

  final selectedScanType = 'skin_check'.obs;
  final scanTypes = [
    'skin_check',
    'hair_check',
    'scalp_check',
    'texture_review',
  ];
  final bodyLocations = ['face', 'forehead', 'cheek', 'chin', 'scalp'];
  final symptoms = [
    'redness',
    'dryness',
    'oiliness',
    'dark_spots',
    'bumps',
    'pigmentation',
    'hair_loss',
    'itching',
  ];
  final durations = [
    'one_week',
    'few_weeks',
    'one_month',
    'several_months',
    'one_year_or_more',
  ];
  final severityLevels = ['low', 'moderate', 'noticeable', 'high'];
  final issueTypes = [
    'redness',
    'dryness',
    'acne',
    'pigmentation',
    'texture',
    'hair_loss',
    'scalp',
  ];
  final skinTypes = ['normal', 'dry', 'oily', 'combination', 'sensitive'];
  final bodyAreas = [
    'face',
    'forehead',
    'cheek',
    'chin',
    'nose',
    'jawline',
    'under_eye',
    'scalp',
    'neck',
  ];
  final selectedBodyLocation = 'face'.obs;
  final selectedDuration = 'one_week'.obs;
  final selectedSeverity = 'low'.obs;
  final selectedIssueType = 'redness'.obs;
  final selectedSkinType = ''.obs;
  final locationText = ''.obs;
  final userName = ''.obs;
  final userAge = RxnInt();
  final userGender = RxnString();
  final userAllergies = ''.obs;
  final userMedications = ''.obs;
  final userSunSensitive = false.obs;
  final isProfileLoaded = false.obs;
  final selectedSymptoms = <String>[].obs;
  final notes = ''.obs;
  final locationController = TextEditingController();
  final notesController = TextEditingController();
  final selectedImages = <LocalScanImage>[].obs;
  final isAnalyzing = false.obs;
  final isSaving = false.obs;
  final hasUnsavedResult = false.obs;
  final aiResult = Rxn<ScanAiResult>();
  final errorMessage = ''.obs;
  Map<String, dynamic>? _pendingPayload;
  List<String> _pendingPaths = [];

  bool get _isArabic => Get.locale?.languageCode == 'ar';
  String _text(String ar, String en) => _isArabic ? ar : en;
  int get imagesCount => selectedImages.length;
  String get analysisTarget =>
      ['hair_check', 'scalp_check'].contains(selectedScanType.value) ||
          selectedBodyLocation.value == 'scalp'
      ? 'hair'
      : 'skin';

  @override
  void onInit() {
    super.onInit();
    notesController.addListener(() => notes.value = notesController.text);
    loadProfileDefaults();
  }

  Future<bool> loadProfileDefaults() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    try {
      final profile = await _supabase
          .from('profiles')
          .select(
            'full_name,age,gender,skin_type,location_text,allergies,medications,sun_sensitive',
          )
          .eq('id', user.id)
          .maybeSingle();
      if (isClosed || _supabase.auth.currentUser?.id != user.id) return false;

      final homeProfile = Get.isRegistered<HomeController>()
          ? Get.find<HomeController>().profile
          : null;

      final rawName = profile?['full_name'] ?? homeProfile?['full_name'];
      userName.value = (rawName ?? '').toString().trim();

      final rawAge = profile?['age'] ?? homeProfile?['age'];
      userAge.value = rawAge is int
          ? rawAge
          : int.tryParse(rawAge?.toString() ?? '');

      final rawGender = profile?['gender'] ?? homeProfile?['gender'];
      userGender.value = ProfileValues.gender(rawGender);

      final rawSkin = profile?['skin_type'] ?? homeProfile?['skin_type'];
      selectedSkinType.value =
          ProfileValues.skinType(rawSkin) ?? rawSkin?.toString() ?? '';

      final rawLocation =
          (profile?['location_text'] ?? homeProfile?['location_text'])
              ?.toString()
              .trim() ??
          '';
      // Never invent a location. It affects both the AI context and the
      // catalog of local doctors/products.
      locationText.value = rawLocation;
      locationController.text = locationText.value;

      final rawAllergies = profile?['allergies'] ?? homeProfile?['allergies'];
      userAllergies.value = (rawAllergies ?? '').toString().trim();

      final rawMeds = profile?['medications'] ?? homeProfile?['medications'];
      userMedications.value = (rawMeds ?? '').toString().trim();

      final rawSun = profile?['sun_sensitive'] ?? homeProfile?['sun_sensitive'];
      userSunSensitive.value = rawSun == true;

      isProfileLoaded.value = true;
      log(
        '[ScanController] Loaded clinical profile defaults: age=${userAge.value}, gender=${userGender.value}, skin=${selectedSkinType.value}, location=${locationText.value}, allergies=${userAllergies.value}, meds=${userMedications.value}, sunSensitive=${userSunSensitive.value}',
      );
      return true;
    } catch (error, stack) {
      log('Unable to load scan profile', error: error, stackTrace: stack);
      errorMessage.value = _text(
        'تعذر تحميل بيانات الحساب. حاول مجددًا.',
        'Unable to load your profile. Please retry.',
      );
      return false;
    }
  }

  void toggleSymptom(String value) {
    if (isAnalyzing.value) return;
    selectedSymptoms.contains(value)
        ? selectedSymptoms.remove(value)
        : selectedSymptoms.add(value);
  }

  Future<void> pickFromCamera() async {
    if (isAnalyzing.value) return;
    try {
      final file = await Get.to<XFile>(
        () => LiveScanCameraView(faceGuide: analysisTarget == 'skin'),
        fullscreenDialog: true,
      );
      if (file != null && !isClosed) await _addFile(file);
    } catch (error, stack) {
      log('Unable to open camera', error: error, stackTrace: stack);
      _showError(
        _text(
          'تعذر فتح الكاميرا. تأكد من السماح للتطبيق باستخدام الكاميرا ثم حاول مجددًا.',
          'Unable to open the camera. Allow camera access for the app, then try again.',
        ),
      );
    }
  }

  Future<void> pickFromGallery() async {
    if (isAnalyzing.value) return;
    final files = await _picker.pickMultiImage(
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 78,
    );
    for (final file in files) {
      if (isClosed) return;
      if (selectedImages.length >= 5) {
        _showError(
          _text('الحد الأقصى خمس صور.', 'You can upload up to five images.'),
        );
        break;
      }
      await _addFile(file);
    }
  }

  Future<void> _addFile(XFile file) async {
    if (selectedImages.length >= 5 || isAnalyzing.value) return;
    final bytes = await file.readAsBytes();
    final mime = lookupMimeType(file.name, headerBytes: bytes) ?? '';
    if (!['image/jpeg', 'image/png', 'image/webp'].contains(mime) ||
        bytes.isEmpty ||
        bytes.length > 10485760) {
      _showError(
        _text(
          'استخدم صورة JPG أو PNG أو WEBP لا تتجاوز 10 ميجابايت.',
          'Use a JPG, PNG or WEBP image up to 10 MB.',
        ),
      );
      return;
    }
    selectedImages.add(
      LocalScanImage(file: file, bytes: bytes, mimeType: mime),
    );
  }

  void setFocus(int index, Uint8List? bytes) {
    if (isAnalyzing.value || index >= selectedImages.length) return;
    final image = selectedImages[index];
    selectedImages[index] = LocalScanImage(
      file: image.file,
      bytes: image.bytes,
      mimeType: image.mimeType,
      focusBytes: bytes,
    );
  }

  void removeImageAt(int index) {
    if (isAnalyzing.value || index < 0 || index >= selectedImages.length)
      return;
    selectedImages.removeAt(index);
  }

  Future<void> clearForm() async {
    if (isAnalyzing.value || isSaving.value) return;
    if (hasUnsavedResult.value) {
      final discard = await Get.dialog<bool>(
        AlertDialog(
          title: Text(_text('تقرير غير محفوظ', 'Unsaved report')),
          content: Text(
            _text(
              'هل تريد حذف النتيجة غير المحفوظة وصورها؟',
              'Discard this unsaved result and its uploaded images?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text(_text('إلغاء', 'Cancel')),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: Text(_text('تجاهل', 'Discard')),
            ),
          ],
        ),
      );
      if (discard != true) return;
      try {
        await _remote.removeImages(_pendingPaths);
      } catch (error) {
        _showError(
          _text(
            'تعذر حذف الصور. حاول مجددًا.',
            'Unable to remove the images. Please retry.',
          ),
        );
        return;
      }
    }
    _pendingPayload = null;
    _pendingPaths = [];
    hasUnsavedResult.value = false;
    selectedImages.clear();
    selectedSymptoms.clear();
    selectedBodyLocation.value = 'face';
    selectedDuration.value = 'one_week';
    selectedSeverity.value = 'low';
    selectedIssueType.value = 'redness';
    selectedScanType.value = 'skin_check';
    notesController.clear();
    aiResult.value = null;
    errorMessage.value = '';
  }

  Future<void> analyze() async {
    if (isAnalyzing.value || isSaving.value) return;
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _showError(
        _text(
          'سجّل الدخول أولًا لبدء التحليل.',
          'Sign in before starting an analysis.',
        ),
      );
      return;
    }
    if (hasUnsavedResult.value) {
      _showError(
        _text(
          'احفظ النتيجة السابقة أو تجاهلها أولًا.',
          'Save or discard the previous result first.',
        ),
      );
      return;
    }
    if (selectedImages.isEmpty) {
      _showError(
        _text('ارفع صورة واحدة على الأقل.', 'Upload at least one image.'),
      );
      return;
    }
    final uploadedPaths = <String>[];
    isAnalyzing.value = true;
    errorMessage.value = '';
    try {
      if (!await loadProfileDefaults()) throw Exception(errorMessage.value);
      if (locationText.value.trim().isEmpty) {
        final homeLoc = Get.isRegistered<HomeController>()
            ? Get.find<HomeController>().profile['location_text']
                  ?.toString()
                  .trim()
            : null;
        locationText.value = homeLoc ?? '';
      }
      if (locationText.value.trim().isEmpty) {
        throw Exception(
          _text(
            'أكمل الدولة في بيانات الحساب أولًا لضمان توصيات مناسبة لموقعك.',
            'Complete your country in your profile first for location-appropriate recommendations.',
          ),
        );
      }
      if (!skinTypes.contains(selectedSkinType.value)) {
        throw Exception(
          _text(
            'أكمل الدولة ونوع البشرة في بيانات الحساب أولًا.',
            'Complete your country and skin type in your profile first.',
          ),
        );
      }
      final images = List<LocalScanImage>.of(selectedImages);
      final language = _isArabic ? 'ar' : 'en';
      final input = <String, dynamic>{
        'scan_type': selectedScanType.value,
        'body_location': selectedBodyLocation.value,
        'symptoms': selectedSymptoms.toList(),
        'duration': selectedDuration.value,
        'severity': selectedSeverity.value,
        'notes': notes.value.trim(),
        'issue_type': selectedIssueType.value,
        'skin_type_context': selectedSkinType.value,
        'location_text': locationText.value,
        'location_label': locationText.value,
        if (userAge.value != null) 'age': userAge.value,
        if (userGender.value != null && userGender.value!.isNotEmpty)
          'gender': userGender.value,
        if (userAllergies.value.trim().isNotEmpty)
          'allergies': userAllergies.value.trim(),
        if (userMedications.value.trim().isNotEmpty)
          'medications': userMedications.value.trim(),
        'sun_sensitive': userSunSensitive.value,
        'image_focus_areas': images
            .map(
              (image) => {
                'file_name': image.file.name,
                'selected': image.focusBytes != null,
              },
            )
            .toList(),
      };
      uploadedPaths.addAll(
        await Future.wait(
          images.map(
            (image) => _remote.uploadImage(
              bytes: image.bytes,
              fileName: image.file.name,
              mimeType: image.mimeType,
            ),
          ),
        ),
      );
      final result = await ScanAiService.instance.analyze(
        languageCode: language,
        images: images
            .map(
              (image) => ScanImageInput(
                bytes: image.focusBytes ?? image.bytes,
                mimeType: image.focusBytes == null
                    ? image.mimeType
                    : 'image/png',
              ),
            )
            .toList(),
        scanType: input['scan_type'],
        bodyLocation: input['body_location'],
        symptoms: List<String>.from(input['symptoms']),
        duration: input['duration'],
        severity: input['severity'],
        notes: input['notes'],
        issueType: input['issue_type'],
        skinTypeContext: input['skin_type_context'],
        locationText: input['location_text'],
        profileContext: {
          if (userAge.value != null) 'age': userAge.value,
          if (userGender.value != null && userGender.value!.isNotEmpty)
            'gender': userGender.value,
          if (userAllergies.value.trim().isNotEmpty)
            'allergies': userAllergies.value.trim(),
          if (userMedications.value.trim().isNotEmpty)
            'medications': userMedications.value.trim(),
          'sun_sensitive': userSunSensitive.value,
          'skin_type': selectedSkinType.value,
          'location_text': locationText.value,
        },
      );
      if (_supabase.auth.currentUser?.id != user.id)
        throw const AuthException('Your session changed. Sign in again.');
      _pendingPayload = ScanRemoteSource.buildScanPayload(
        result: result,
        input: input,
        userId: user.id,
        languageCode: language,
        imageCount: images.length,
      );
      _pendingPaths = List.of(uploadedPaths);
      aiResult.value = ScanAiResult.fromJson(_pendingPayload!);
      hasUnsavedResult.value = true;
      await savePendingResult();
      if (!isClosed)
        Get.to(
          () => AnalysisResultView(result: aiResult.value!),
          transition: Transition.cupertino,
        );
    } catch (error, stack) {
      log('Scan failed', error: error, stackTrace: stack);
      if (!hasUnsavedResult.value && uploadedPaths.isNotEmpty) {
        try {
          await _remote.removeImages(uploadedPaths);
        } catch (cleanupError, cleanupStack) {
          log(
            'Unable to remove incomplete scan images',
            error: cleanupError,
            stackTrace: cleanupStack,
          );
        }
      }
      _showError(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      isAnalyzing.value = false;
    }
  }

  Future<void> savePendingResult() async {
    if (isSaving.value || !hasUnsavedResult.value || _pendingPayload == null)
      return;
    isSaving.value = true;
    try {
      final result = aiResult.value!;
      final row = await _remote.saveReport(
        payload: _pendingPayload!,
        imagePaths: _pendingPaths,
        findings: [
          for (var i = 0; i < result.visibleFindings.length; i++)
            {
              'title': result.visibleFindings[i],
              'description': i < result.reasons.length
                  ? result.reasons[i]
                  : null,
              'severity': result.urgency,
              'category': _pendingPayload!['scan_type'],
            },
        ],
      );
      aiResult.value = ScanAiResult.fromJson(row);
      hasUnsavedResult.value = false;
      _pendingPayload = null;
      _pendingPaths = [];
      if (Get.isRegistered<HomeController>())
        await Get.find<HomeController>().loadHomeData();
    } catch (error, stack) {
      log('Unable to save report', error: error, stackTrace: stack);
      _showError(
        _text(
          'التحليل جاهز لكن لم يُحفظ. ارجع لشاشة الفحص واضغط إعادة الحفظ.',
          'Your result is ready but was not saved. Return to the scan screen and retry saving.',
        ),
      );
    } finally {
      isSaving.value = false;
    }
  }

  void _showError(String message) {
    errorMessage.value = message;
    AppFeedback.error(message, title: _text('تنبيه', 'Notice'));
  }

  @override
  void onClose() {
    locationController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
