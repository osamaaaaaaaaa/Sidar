import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skincare/Services/profile_values.dart';
import 'package:skincare/Services/scan_controller.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:skincare/Utils/AppTheme.dart';
import 'package:skincare/Views/Settings/EditProfile.dart';
import 'package:skincare/Views/Home/scan_city_field.dart';

class ScanView extends StatelessWidget {
  ScanView({super.key});

  final ScanController controller = Get.put(ScanController());

  bool get _isArabic =>
      (Get.locale?.languageCode ?? 'en').toLowerCase().startsWith('ar');

  String _text(String ar, String en) => _isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: AppTheme.backgroundGradient(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Central Rotating Medallion
                  const Center(child: _RotatingScanMedallion()),
                  const SizedBox(height: 18),

                  // Step 1: Scan Type
                  _buildScanTypeSection(),
                  const SizedBox(height: 20),

                  // Step 2: Upload Images (Native Mobile Cards)
                  _buildImagesSection(context),
                  const SizedBox(height: 20),

                  // Step 3: Clinical Parameters
                  _buildInputsSection(context),
                  const SizedBox(height: 24),

                  // Step 4: Actions (Start Analysis)
                  _buildActionsRow(),
                ],
              ),
            ),
            Obx(
              () => controller.isAnalyzing.value
                  ? _AnalysisProgressOverlay(isArabic: _isArabic)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsetsDirectional.only(start: 14),
        child: Center(
          child: InkWell(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Get.back();
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ),
        ),
      ),
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: AppColors.gold, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.25),
                  blurRadius: 6,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/sidar-emblem-clean.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.gold,
                  size: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _text('الفحص الذكي', 'AI Scan'),
            style: TextStyle(
              fontFamily: AppTheme.appFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 14),
          child: Center(
            child: InkWell(
              onTap: () async {
                final saved = await Get.to(() => const EditProfileView());
                if (saved == true) {
                  controller.loadProfileDefaults(refreshCity: true);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 16,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _text('حسابي', 'Account'),
                      style: TextStyle(
                        fontFamily: AppTheme.appFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanTypeSection() {
    final tabs = [
      _TabData(
        'skin_check',
        _text('فحص البشرة', 'Skin Analysis'),
        Icons.face_retouching_natural_rounded,
      ),
      _TabData(
        'hair_check',
        _text('فحص الشعر', 'Hair Analysis'),
        Icons.content_cut_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          _text('نوع الفحص', 'Scan Type'),
          _text('اختر نوع الفحص المطلوب', 'Choose required scan type'),
        ),
        const SizedBox(height: 12),
        Obx(() {
          return Row(
            children: [
              Expanded(
                child: _TabChip(
                  label: tabs[0].label,
                  icon: tabs[0].icon,
                  selected: controller.selectedScanType.value == tabs[0].value,
                  onTap: () =>
                      controller.selectedScanType.value = tabs[0].value,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TabChip(
                  label: tabs[1].label,
                  icon: tabs[1].icon,
                  selected: controller.selectedScanType.value == tabs[1].value,
                  onTap: () =>
                      controller.selectedScanType.value = tabs[1].value,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildImagesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          _text('صور الفحص', 'Scan Photos'),
          _text(
            'التقط من الكاميرا أو اختر من المعرض (حتى 5 صور)',
            'Capture from camera or gallery (max 5)',
          ),
        ),
        const SizedBox(height: 12),
        AppTheme.glassPanel(
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Two Native Mobile Buttons: Camera & Gallery
              _imagePickerCards(),

              // Selected Images Preview Grid
              Obx(() {
                if (controller.selectedImages.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _text('الصور المرفقة', 'Attached Photos'),
                          style: TextStyle(
                            fontFamily: AppTheme.appFontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.goldSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${controller.selectedImages.length} / 5',
                            style: TextStyle(
                              fontFamily: AppTheme.appFontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _previewGrid(context),
                  ],
                );
              }),

              const SizedBox(height: 14),
              _hintLine(
                _text(
                  'لأدق نتيجة: التقط صورة واضحة في إضاءة جيدة بدون فلاتر.',
                  'For best results: capture a clear photo in good light without filters.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imagePickerCards() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              try {
                await controller.pickFromCamera();
              } catch (e, s) {
                log('[ScanView.camera] $e', error: e, stackTrace: s);
              }
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.goldSoft,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.gold,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _text('الكاميرا', 'Camera'),
                    style: TextStyle(
                      fontFamily: AppTheme.appFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _text('التقاط فوري', 'Instant photo'),
                    style: TextStyle(
                      fontFamily: AppTheme.appFontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () async {
              try {
                await controller.pickFromGallery();
              } catch (e, s) {
                log('[ScanView.gallery] $e', error: e, stackTrace: s);
              }
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _text('المعرض', 'Gallery'),
                    style: TextStyle(
                      fontFamily: AppTheme.appFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _text('اختيار صور', 'Choose photos'),
                    style: TextStyle(
                      fontFamily: AppTheme.appFontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _previewGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 560 ? 4 : 3;
        return GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.selectedImages.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final image = controller.selectedImages[index];
            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(image.bytes, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: _deleteButton(() => controller.removeImageAt(index)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInputsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          _text('بيانات الفحص', 'Scan Details'),
          _text(
            'معلومات دقيقة تساعد الذكاء الاصطناعي على التشخيص',
            'Details that aid accurate diagnostic matching',
          ),
        ),
        const SizedBox(height: 12),
        AppTheme.glassPanel(
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(() {
                return _buildGrid([
                  _dropdownField(
                    label: _text('نوع المشكلة', 'Problem type'),
                    value: controller.selectedIssueType.value,
                    items: const [
                      _DropItem('redness'),
                      _DropItem('dryness'),
                      _DropItem('acne'),
                      _DropItem('pigmentation'),
                      _DropItem('texture'),
                      _DropItem('hair_loss'),
                      _DropItem('scalp'),
                    ],
                    displayLabel: _issueTypeLabel,
                    onChanged: (value) =>
                        controller.selectedIssueType.value = value,
                  ),
                  _dropdownField(
                    label: _text('الشدة', 'Severity'),
                    value: controller.selectedSeverity.value,
                    items: const [
                      _DropItem('low'),
                      _DropItem('moderate'),
                      _DropItem('noticeable'),
                      _DropItem('high'),
                    ],
                    displayLabel: _severityLabel,
                    onChanged: (value) =>
                        controller.selectedSeverity.value = value,
                  ),
                  _dropdownField(
                    label: _text('المدة', 'Duration'),
                    value: controller.selectedDuration.value,
                    items: const [
                      _DropItem('one_week'),
                      _DropItem('few_weeks'),
                      _DropItem('one_month'),
                      _DropItem('several_months'),
                      _DropItem('one_year_or_more'),
                    ],
                    displayLabel: _durationLabel,
                    onChanged: (value) =>
                        controller.selectedDuration.value = value,
                  ),
                ]);
              }),
              const SizedBox(height: 14),
              ScanCityField(controller: controller, isArabic: _isArabic),
              const SizedBox(height: 14),
              _chipsField(
                label: _text('الأعراض الملاحظة', 'Observed Symptoms'),
                valueBuilder: controller.selectedSymptoms.contains,
                onSelected: controller.toggleSymptom,
              ),
              const SizedBox(height: 14),
              _textField(
                label: _text(
                  'ملاحظات إضافية (اختياري)',
                  'Additional Notes (Optional)',
                ),
                hint: _text(
                  'أي تفاصيل ترغب بإضافتها للذكاء الاصطناعي...',
                  'Any additional details for the AI...',
                ),
                controller: controller.notesController,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        if (!isWide) {
          return Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children
              .map(
                (child) => SizedBox(
                  width: (constraints.maxWidth - 12) / 2,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<_DropItem> items,
    required String Function(String value) displayLabel,
    required ValueChanged<String> onChanged,
    String? hint,
  }) {
    String? effectiveValue;
    if (items.any((item) => item.value == value)) {
      effectiveValue = value;
    } else {
      final normalized = ProfileValues.skinType(value);
      if (normalized != null && items.any((item) => item.value == normalized)) {
        effectiveValue = normalized;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.appFontFamily,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: effectiveValue,
          hint: Text(
            hint ?? _text('اختر...', 'Select...'),
            style: TextStyle(
              fontFamily: AppTheme.appFontFamily,
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          decoration: AppTheme.inputDecoration(hintText: ''),
          iconEnabledColor: AppColors.primary,
          dropdownColor: AppColors.surface,
          style: TextStyle(
            fontFamily: AppTheme.appFontFamily,
            fontSize: 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item.value,
                  child: Text(displayLabel(item.value)),
                ),
              )
              .toList(),
          onChanged: (newValue) {
            if (newValue == null) return;
            onChanged(newValue);
          },
        ),
      ],
    );
  }

  Widget _textField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.appFontFamily,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          style: TextStyle(
            fontFamily: AppTheme.appFontFamily,
            fontSize: 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: AppTheme.inputDecoration(hintText: hint),
        ),
      ],
    );
  }

  Widget _chipsField({
    required String label,
    required bool Function(String value) valueBuilder,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.appFontFamily,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        Obx(() {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.symptoms.map((symptom) {
              final selected = valueBuilder(symptom);
              return FilterChip(
                label: Text(
                  _symptomLabel(symptom),
                  style: TextStyle(
                    fontFamily: AppTheme.appFontFamily,
                    fontSize: 12,
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                selected: selected,
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                backgroundColor: AppColors.surfaceMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: selected
                        ? AppColors.primary
                        : AppColors.gold.withValues(alpha: 0.2),
                  ),
                ),
                onSelected: (_) => onSelected(symptom),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildActionsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() {
          if (controller.errorMessage.value.isEmpty)
            return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    controller.errorMessage.value,
                    style: TextStyle(
                      fontFamily: AppTheme.appFontFamily,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Obx(
                () => AppTheme.goldButton(
                  text: _text('بدء التحليل الذكي', 'Start AI Analysis'),
                  height: 54,
                  isLoading: controller.isAnalyzing.value,
                  onPressed: () async {
                    try {
                      await controller.analyze();
                    } catch (e, s) {
                      log('[ScanView.analyze] $e', error: e, stackTrace: s);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTheme.outlineButton(
                text: _text('مسح', 'Clear'),
                height: 54,
                onPressed: controller.clearForm,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 18,
          margin: const EdgeInsetsDirectional.only(end: 8, top: 2),
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTheme.appFontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: AppTheme.appFontFamily,
                  fontSize: 11.5,
                  color: AppColors.textSecondary.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hintLine(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.gold,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: AppTheme.appFontFamily,
                fontSize: 11.5,
                color: AppColors.primary.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deleteButton(VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.2),
          ),
          child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  String _durationLabel(String value) {
    switch (value) {
      case 'one_week':
        return _text('أسبوع', 'One week');
      case 'few_weeks':
        return _text('عدة أسابيع', 'Several weeks');
      case 'one_month':
        return _text('شهر', 'One month');
      case 'several_months':
        return _text('عدة أشهر', 'Several months');
      case 'one_year_or_more':
        return _text('سنة أو أكثر', 'One year or more');
      default:
        return value;
    }
  }

  String _severityLabel(String value) {
    switch (value) {
      case 'low':
        return _text('خفيفة', 'Mild');
      case 'moderate':
        return _text('متوسطة', 'Moderate');
      case 'noticeable':
        return _text('ملحوظة', 'Noticeable');
      case 'high':
        return _text('شديدة', 'Severe');
      default:
        return value;
    }
  }

  String _issueTypeLabel(String value) {
    switch (value) {
      case 'redness':
        return _text('احمرار / تهيج', 'Redness / irritation');
      case 'dryness':
        return _text('جفاف / قشور', 'Dryness / flaking');
      case 'acne':
        return _text('حبوب / بثور', 'Acne / breakouts');
      case 'pigmentation':
        return _text('تصبغات / بقع', 'Pigmentation / dark spots');
      case 'texture':
        return _text('ملمس / مسام', 'Texture / pores');
      case 'hair_loss':
        return _text('تساقط / كثافة', 'Hair loss / density');
      case 'scalp':
        return _text('مشكلة بفروة الرأس', 'Scalp issue');
      default:
        return value;
    }
  }

  String _symptomLabel(String value) {
    switch (value) {
      case 'redness':
        return _text('احمرار', 'Redness');
      case 'dryness':
        return _text('جفاف', 'Dryness');
      case 'oiliness':
        return _text('دهنية', 'Oiliness');
      case 'dark_spots':
        return _text('بقع داكنة', 'Dark spots');
      case 'bumps':
        return _text('حبيبات', 'Bumps');
      case 'pigmentation':
        return _text('تصبغ', 'Pigmentation');
      case 'hair_loss':
        return _text('تساقط الشعر', 'Hair loss');
      case 'itching':
        return _text('حكة', 'Itching');
      default:
        return value;
    }
  }
}

class _TabData {
  final String value;
  final String label;
  final IconData icon;

  const _TabData(this.value, this.label, this.icon);
}

class _TabChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? Colors.white : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.gold
                : AppColors.gold.withValues(alpha: 0.22),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.20),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.gold : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.appFontFamily,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropItem {
  final String value;

  const _DropItem(this.value);
}

class _AnalysisProgressOverlay extends StatefulWidget {
  const _AnalysisProgressOverlay({required this.isArabic});

  final bool isArabic;

  @override
  State<_AnalysisProgressOverlay> createState() =>
      _AnalysisProgressOverlayState();
}

class _AnalysisProgressOverlayState extends State<_AnalysisProgressOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isArabic
        ? 'يتم تحليل صورك الآن'
        : 'Analyzing your photos';
    final subtitle = widget.isArabic
        ? 'نقرأ المؤشرات ونُعد توصياتك الشخصية...'
        : 'Reading indicators and preparing your personal recommendations...';

    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.background.withValues(alpha: 0.88),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _orbitController,
                  _pulseController,
                ]),
                builder: (context, child) {
                  final pulse = 0.96 + (_pulseController.value * 0.05);
                  return Transform.scale(scale: pulse, child: child);
                },
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 30,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.55),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.16),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 164,
                        height: 164,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            RotationTransition(
                              turns: _orbitController,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  _ring(
                                    160,
                                    AppColors.gold.withValues(alpha: 0.48),
                                  ),
                                  _ring(
                                    128,
                                    AppColors.primary.withValues(alpha: 0.32),
                                  ),
                                  Transform.translate(
                                    offset: const Offset(80, 0),
                                    child: _orbitDot(AppColors.gold),
                                  ),
                                  Transform.translate(
                                    offset: const Offset(-64, 0),
                                    child: _orbitDot(AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: AppColors.gold,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.16,
                                    ),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Image.asset(
                                  'assets/images/sidar-emblem-clean.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.auto_awesome_rounded,
                                    color: AppColors.gold,
                                    size: 34,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTheme.headingStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 22),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: SizedBox(
                          height: 7,
                          child: LinearProgressIndicator(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.10,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.gold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ring(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: color, width: 1.3),
    ),
  );

  Widget _orbitDot(Color color) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 8),
      ],
    ),
  );
}

class _RotatingScanMedallion extends StatefulWidget {
  const _RotatingScanMedallion();

  @override
  State<_RotatingScanMedallion> createState() => _RotatingScanMedallionState();
}

class _RotatingScanMedallionState extends State<_RotatingScanMedallion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Widget _ring(double size, Color color, {double strokeWidth = 1.2}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: strokeWidth),
      ),
    );
  }

  Widget _orbitDot(double offset, Color color, {double size = 8}) {
    return Transform.translate(
      offset: Offset(offset, 0),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.6),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Slow rotating orbital rings
          RotationTransition(
            turns: _rotationController,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _ring(
                  170,
                  AppColors.gold.withValues(alpha: 0.25),
                  strokeWidth: 1.2,
                ),
                _ring(
                  192,
                  AppColors.primary.withValues(alpha: 0.16),
                  strokeWidth: 1.0,
                ),
                _orbitDot(85, AppColors.gold, size: 6),
                _orbitDot(-96, AppColors.lightGold, size: 5),
              ],
            ),
          ),

          // Radiant outer glow
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.28),
                  blurRadius: 30,
                  spreadRadius: 3,
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),

          // Central luxury white & gold medallion
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFF7F4EA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppColors.gold, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.20),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: ClipOval(
                child: Image.asset(
                  'assets/images/sidar-emblem-clean.png',
                  width: 70,
                  height: 70,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/WhatsApp Image 2026-03-02 at 3.31.37 AM.jpeg',
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.gold,
                      size: 38,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
