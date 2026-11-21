import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skincare/Models/ScanAiModel.dart';
import 'package:skincare/Services/app_feedback.dart';
import 'package:skincare/Services/pdf_report_service.dart';
import 'package:skincare/Services/routine_notification_service.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:skincare/Utils/AppTheme.dart';
import 'package:skincare/Views/Home/visual_mapping_viewer.dart';
import 'package:url_launcher/url_launcher.dart';

class AnalysisResultView extends StatelessWidget {
  final ScanAiResult result;
  final VoidCallback? onScanAgain;
  final RxBool _isSharingPdf = false.obs;
  final GlobalKey _doctorsKey = GlobalKey();

  AnalysisResultView({super.key, required this.result, this.onScanAgain});

  bool get isHighUrgency => result.urgency.toLowerCase() == 'high';
  bool get isMediumUrgency => result.urgency.toLowerCase() == 'medium';

  String get urgencyLabelKey {
    switch (result.urgency.toLowerCase()) {
      case 'high':
        return 'priority_high';
      case 'medium':
        return 'priority_medium';
      case 'low':
        return 'priority_low';
      default:
        return '--';
    }
  }

  String get statusLabelKey {
    if (result.shouldSeeDoctor || isHighUrgency) {
      return 'medical_followup_advised';
    }
    if (isMediumUrgency) {
      return 'careful_monitoring_recommended';
    }
    return 'general_care_guidance';
  }

  Color get urgencyColor {
    if (isHighUrgency) return Colors.redAccent;
    if (isMediumUrgency) return AppColors.accent;
    return const Color(0xFF7F9777);
  }

  IconData get urgencyIcon {
    if (isHighUrgency) return Icons.priority_high_rounded;
    if (isMediumUrgency) return Icons.error_outline_rounded;
    return Icons.info_outline_rounded;
  }

  bool get _isArabic => _lang.startsWith('ar');
  String _label(String ar, String en) => _isArabic ? ar : en;

  String get casePriorityDescriptionKey {
    if (result.shouldSeeDoctor || isHighUrgency) {
      return 'case_priority_desc_high';
    }
    if (isMediumUrgency) {
      return 'case_priority_desc_medium';
    }
    return 'case_priority_desc_low';
  }

  String get _lang => (Get.locale?.languageCode ?? 'en').toLowerCase();
  String get _summary => result.summaryByLang(_lang);
  List<String> get _visibleFindings => result.visibleFindingsByLang(_lang);
  List<String> get _careSteps => result.careStepsByLang(_lang);
  List<String> get _reasons => result.reasonsByLang(_lang);
  String get _imageQuality => result.imageQualityByLang(_lang);
  String get _disclaimer => result.disclaimerByLang(_lang);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppTheme.backgroundGradient(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 26),
                    _buildHeroResultCard(),
                    const SizedBox(height: 16),
                    VisualMappingViewer(
                      assets: result.visualAssets,
                      isArabic: _isArabic,
                      metrics: {
                        'pore': result.poreClarityScore,
                        'lines': result.fineLinesScore,
                        'tone': result.overallToneScore,
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildMeasurements(),
                    const SizedBox(height: 34),
                    _buildSectionHeader(
                      title: 'triage_decision_title'.tr,
                      subtitle: 'triage_decision_subtitle'.tr,
                    ),
                    const SizedBox(height: 16),
                    _buildTriageCard(),
                    const SizedBox(height: 34),
                    _buildSectionHeader(
                      title: 'ai_summary_title'.tr,
                      subtitle: 'ai_summary_subtitle'.tr,
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCard(),
                    const SizedBox(height: 34),
                    _buildSectionHeader(
                      title: 'visible_findings_title'.tr,
                      subtitle: 'visible_findings_subtitle'.tr,
                    ),
                    const SizedBox(height: 16),
                    _buildFindingsList(),
                    const SizedBox(height: 34),
                    _buildSectionHeader(
                      title: 'care_steps_title'.tr,
                      subtitle: 'care_steps_subtitle'.tr,
                    ),
                    const SizedBox(height: 16),
                    _buildCareStepsList(),
                    const SizedBox(height: 34),
                    _buildCatalogSection(doctors: false),
                    const SizedBox(height: 34),
                    Container(
                      key: _doctorsKey,
                      child: _buildCatalogSection(doctors: true),
                    ),
                    const SizedBox(height: 34),
                    if (_reasons.isNotEmpty) ...[
                      _buildSectionHeader(
                        title: 'followup_reasons_title'.tr,
                        subtitle: 'followup_reasons_subtitle'.tr,
                      ),
                      const SizedBox(height: 16),
                      _buildReasonsCard(),
                      const SizedBox(height: 34),
                    ],

                    _buildDisclaimerCard(),
                    const SizedBox(height: 34),
                    _buildActionsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        AppTheme.circleBackButton(
          onTap: () {
            try {
              Get.back();
            } catch (e, s) {
              log('[AnalysisResultView.back] $e', error: e, stackTrace: s);
            }
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'analysis_results_title'.tr,
                style: AppTheme.headingStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'analysis_results_subtitle'.tr,
                style: AppTheme.bodyStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary.withOpacity(.92),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Obx(
          () => InkWell(
            onTap: _isSharingPdf.value
                ? null
                : () {
                    try {
                      _shareResult();
                    } catch (e, s) {
                      log(
                        '[AnalysisResultView.share] $e',
                        error: e,
                        stackTrace: s,
                      );
                    }
                  },
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.glass,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: _isSharingPdf.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.accent,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.share_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroResultCard() {
    return AppTheme.glassPanel(
      borderRadius: 16,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned(
            top: -35,
            right: -20,
            child: _buildHeroOrb(120, AppColors.primary.withOpacity(.18)),
          ),
          Positioned(
            bottom: -30,
            left: -10,
            child: _buildHeroOrb(95, AppColors.accent.withOpacity(.14)),
          ),
          Positioned(
            top: 110,
            left: -25,
            child: _buildHeroOrb(70, AppColors.textSecondary.withOpacity(.14)),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        result.title.trim().isEmpty
                            ? 'analysis_results_title'.tr
                            : result.title,
                        style: AppTheme.bodyStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    AppTheme.statusBadge(
                      label: urgencyLabelKey.tr,
                      color: urgencyColor,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                AppTheme.glassPanel(
                  borderRadius: 12,
                  padding: const EdgeInsets.all(22),
                  backgroundColor: AppColors.surfaceMuted,
                  child: Column(
                    children: [
                      _buildOverallScoreCircle(),
                      const SizedBox(height: 16),
                      Text(
                        _label('الدرجة الإجمالية', 'Overall score'),
                        textAlign: TextAlign.center,
                        style: AppTheme.headingStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        statusLabelKey.tr,
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        casePriorityDescriptionKey.tr,
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary.withOpacity(.92),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _MiniInsightCard(
                          title: 'case_priority_title'.tr,
                          value: urgencyLabelKey.tr,
                          icon: Icons.flag_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniInsightCard(
                          title: 'doctor_review_label'.tr,
                          value: result.shouldSeeDoctor
                              ? 'doctor_review_advised'.tr
                              : 'doctor_review_optional'.tr,
                          icon: result.shouldSeeDoctor
                              ? Icons.medical_services_outlined
                              : Icons.health_and_safety_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniInsightCard(
                          title: 'image_quality_label'.tr,
                          value: ReportPresentation.imageQuality(
                            _imageQuality,
                            _isArabic,
                          ),
                          icon: Icons.photo_filter_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallScoreCircle() {
    final score = result.overallScore;
    return SizedBox(
      width: 86,
      height: 86,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 86,
            height: 86,
            child: CircularProgressIndicator(
              value: score != null && score.isFinite
                  ? score.clamp(0, 100) / 100
                  : 0,
              strokeWidth: 7,
              backgroundColor: AppColors.primary.withOpacity(.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                ReportPresentation.score(score),
                style: AppTheme.headingStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurements() {
    return AppTheme.glassPanel(
      borderRadius: 16,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_label('نوع التحليل', 'Analysis target')}: ${ReportPresentation.target(result, _isArabic)}',
            style: AppTheme.bodyStyle(),
          ),
          Text(
            '${_label('تاريخ التقرير', 'Report date')}: ${_humanReportDate(result.createdAt)}',
            style: AppTheme.bodyStyle(),
          ),
          Text(
            '${_label('ثقة التحليل المرسلة', 'Reported AI confidence')}: ${ReportPresentation.text(result.aiConfidence)}',
            style: AppTheme.bodyStyle(),
          ),
          const SizedBox(height: 12),
          ...ReportPresentation.metrics(result, _isArabic).entries.map(
            (entry) => _buildMetricProgress(entry.key, entry.value),
          ),
        ],
      ),
    );
  }

  String _humanReportDate(DateTime? date) {
    if (date == null) return '--';

    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    if (_isArabic) {
      const months = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ];
      final period = local.hour < 12 ? 'ص' : 'م';
      return '${local.day} ${months[local.month - 1]} ${local.year}، $hour:$minute $period';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '${months[local.month - 1]} ${local.day}, ${local.year} · $hour:$minute $period';
  }

  Widget _buildMetricProgress(String label, double? score) {
    final value = (score ?? 0).clamp(0, 100).toDouble();
    final isAvailable = score != null && score.isFinite;
    final color = value >= 75
        ? AppColors.secondary
        : value >= 50
        ? AppColors.gold
        : AppColors.oliveGreen;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.bodyStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                ReportPresentation.score(score),
                textDirection: TextDirection.ltr,
                style: AppTheme.headingStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isAvailable ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: isAvailable ? value / 100 : 0,
              minHeight: 8,
              backgroundColor: AppColors.sageTint,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriageCard() {
    final urgent = result.shouldSeeDoctor || isHighUrgency;

    return AppTheme.glassPanel(
      borderRadius: 16,
      borderColor: urgent ? Colors.redAccent.withOpacity(0.5) : null,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(urgencyIcon, color: urgencyColor, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabelKey.tr,
                  style: AppTheme.bodyStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: urgent ? Colors.redAccent : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  result.shouldSeeDoctor
                      ? 'triage_doctor_advised_desc'.tr
                      : 'triage_general_monitoring_desc'.tr,
                  style: AppTheme.bodyStyle(
                    fontSize: 12,
                    height: 1.55,
                    color: AppColors.textSecondary.withOpacity(.92),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return AppTheme.glassPanel(
      borderRadius: 16,
      padding: const EdgeInsets.all(18),
      child: Text(
        ReportPresentation.text(_summary),
        style: AppTheme.bodyStyle(
          fontSize: 13.5,
          color: AppColors.textSecondary.withOpacity(.96),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFindingsList() {
    if (_visibleFindings.isEmpty) {
      return _buildEmptyCard('no_visible_findings'.tr);
    }

    return Column(
      children: _visibleFindings.map((item) {
        return AppTheme.glassPanel(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.visibility_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item,
                  style: AppTheme.bodyStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCareStepsList() {
    return Column(
      children: [
        _buildRoutineBlock(
          title: _label('روتين صباحي', 'Morning routine'),
          icon: Icons.wb_sunny_outlined,
          steps: result.morningRoutine,
        ),
        const SizedBox(height: 12),
        _buildRoutineBlock(
          title: _label('روتين مسائي', 'Evening routine'),
          icon: Icons.nightlight_round,
          steps: result.eveningRoutine,
        ),
        if (_careSteps.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildRoutineBlock(
            title: _label('العناية العامة', 'General care'),
            icon: Icons.spa_outlined,
            steps: _careSteps,
          ),
        ],
        const SizedBox(height: 16),
        _buildRoutineReminderBanner(),
      ],
    );
  }

  Widget _buildRoutineReminderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.40),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.gold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _label(
                        'التذكير اليومي بالروتين',
                        'Daily Routine Reminders',
                      ),
                      style: AppTheme.headingStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _label(
                        'احصل على إشعار يومي في الصباح والمساء بخطوات هذا الروتين.',
                        'Get daily morning and evening alerts for this tailored routine.',
                      ),
                      style: AppTheme.bodyStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () async {
                final enabled = await RoutineNotificationService.instance
                    .enableFromAnalysis(
                      morningSteps: result.morningRoutine,
                      eveningSteps: result.eveningRoutine,
                    );
                if (!enabled) {
                  AppFeedback.warning(
                    _label(
                      'يمكنك السماح بالإشعارات من إعدادات الجهاز لتفعيل التذكير.',
                      'Allow notifications in your device settings to enable reminders.',
                    ),
                    title: _label(
                      'يلزم السماح بالإشعارات',
                      'Notification permission needed',
                    ),
                  );
                  return;
                }
                AppFeedback.success(
                  _label(
                    'تمت جدولة إشعارات الروتين الصباحي والمسائي بنجاح بناءً على حالتك!',
                    'Morning and evening routine notifications scheduled successfully!',
                  ),
                  title: _label('تم تفعيل التذكير', 'Reminders Activated'),
                );
              },
              icon: const Icon(Icons.alarm_on_rounded, size: 18),
              label: Text(
                _label(
                  'تفعيل التذكير اليومي بهذا الروتين 🔔',
                  'Activate Daily Reminders for Routine 🔔',
                ),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.oliveGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineBlock({
    required String title,
    required IconData icon,
    required List<String> steps,
  }) {
    return AppTheme.glassPanel(
      borderRadius: 16,
      borderColor: AppColors.primary,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.headingStyle(
                    fontSize: 18,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (steps.isEmpty) Text('--', style: AppTheme.bodyStyle()),
          ...steps.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTheme.bodyStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReasonsCard() {
    return AppTheme.glassPanel(
      borderRadius: 16,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: _reasons.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: AppTheme.bodyStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary.withOpacity(.95),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDisclaimerCard() {
    return AppTheme.glassPanel(
      borderRadius: 16,
      borderColor: AppColors.accent.withOpacity(.3),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.gpp_good_outlined,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _disclaimer,
              style: AppTheme.bodyStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary.withOpacity(.95),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareResult() async {
    if (_isSharingPdf.value) return;
    _isSharingPdf.value = true;
    try {
      AppFeedback.info(
        'pdf_preparing_desc'.tr,
        title: 'pdf_preparing_title'.tr,
      );

      final bytes = await PdfReportService.generateReportBytes(
        result: result,
        isArabic: _isArabic,
        reportTimestamp: result.createdAt,
      );
      final box = Get.context?.findRenderObject();
      await SharePlus.instance.share(
        ShareParams(
          title: 'analysis_results_title'.tr,
          subject: 'analysis_results_title'.tr,
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'application/pdf',
              name: 'sidar-report.pdf',
            ),
          ],
          fileNameOverrides: ['sidar-report.pdf'],
          sharePositionOrigin: box is RenderBox && box.hasSize
              ? box.localToGlobal(Offset.zero) & box.size
              : null,
        ),
      );
    } catch (e, s) {
      log('[AnalysisResultView.shareResult] $e', error: e, stackTrace: s);
      AppFeedback.error(e.toString(), title: 'error'.tr);
    } finally {
      _isSharingPdf.value = false;
    }
  }

  Widget _buildCatalogSection({required bool doctors}) {
    final items = doctors ? result.doctors : result.products;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          doctors
              ? _label('أطباء مقترحين', 'Recommended doctors')
              : _label('منتجات مقترحة', 'Recommended products'),
          style: AppTheme.headingStyle(fontSize: 20),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          _buildEmptyCard(
            _label(
              doctors
                  ? 'لا توجد توصيات أطباء متاحة.'
                  : 'لا توجد منتجات مقترحة متاحة.',
              doctors
                  ? 'No recommended doctors available.'
                  : 'No recommended products available.',
            ),
          ),
        ...items.map((item) {
          final uri = ReportPresentation.safeExternalUri(item['link']);
          final image = ReportPresentation.safeExternalUri(item['image']);
          return AppTheme.glassPanel(
            borderRadius: 16,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!doctors && image != null) ...[
                  Image.network(
                    image.toString(),
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  ReportPresentation.text(item['name']?.toString() ?? ''),
                  style: AppTheme.headingStyle(fontSize: 17),
                ),
                if (doctors) ...[
                  Text(
                    ReportPresentation.text(
                      item['specialty']?.toString() ?? '',
                    ),
                    style: AppTheme.bodyStyle(),
                  ),
                  Text(
                    ReportPresentation.text(item['address']?.toString() ?? ''),
                    style: AppTheme.bodyStyle(),
                  ),
                ] else ...[
                  Text(
                    ReportPresentation.text(item['desc']?.toString() ?? ''),
                    style: AppTheme.bodyStyle(),
                  ),
                  Text(
                    '${_label('السعر', 'Price')}: ${ReportPresentation.text(item['price']?.toString() ?? '')}',
                    style: AppTheme.bodyStyle(),
                  ),
                ],
                if (uri != null)
                  TextButton.icon(
                    onPressed: () => _openCatalogLink(uri),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(
                      doctors
                          ? _label('التواصل مع الطبيب', 'Contact physician')
                          : _label('عرض المنتج', 'View product'),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Future<void> _openCatalogLink(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (error, stack) {
      log(
        '[AnalysisResultView.catalogLink] $error',
        error: error,
        stackTrace: stack,
      );
    }
    AppFeedback.error(
      _label('تعذر فتح الرابط.', 'Could not open link.'),
      title: 'error'.tr,
    );
  }

  void _rescan() {
    if (onScanAgain != null) {
      onScanAgain!();
    } else {
      // The caller can start another scan after this route closes; no scanner import cycle.
      Get.back(result: 'rescan');
    }
  }

  void _focusDoctors() {
    final context = _doctorsKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 350),
        alignment: 0,
      );
    }
  }

  Widget _buildActionsSection() {
    return Column(
      children: [
        AppTheme.goldButton(
          text: result.shouldSeeDoctor || isHighUrgency
              ? 'find_dermatologist'.tr
              : 'scan_again'.tr,
          onPressed: result.shouldSeeDoctor || isHighUrgency
              ? _focusDoctors
              : _rescan,
        ),
        if (result.shouldSeeDoctor || isHighUrgency) ...[
          const SizedBox(height: 12),
          AppTheme.outlineButton(text: 'scan_again'.tr, onPressed: _rescan),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => _isSharingPdf.value
                    ? Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.accent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'pdf_preparing_button'.tr,
                              style: AppTheme.bodyStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : AppTheme.outlineButton(
                        text: 'share_result'.tr,
                        onPressed: _shareResult,
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return AppTheme.sectionHeader(title: title, subtitle: subtitle);
  }

  Widget _buildHeroOrb(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }

  Widget _buildEmptyCard(String text) {
    return AppTheme.glassPanel(
      borderRadius: 16,
      child: Text(
        text,
        style: AppTheme.bodyStyle(
          color: AppColors.textSecondary.withOpacity(.92),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MiniInsightCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MiniInsightCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppTheme.glassPanel(
      borderRadius: 12,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTheme.bodyStyle(
              fontSize: 10,
              color: AppColors.textSecondary.withOpacity(.88),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyStyle(
              fontSize: 11,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
