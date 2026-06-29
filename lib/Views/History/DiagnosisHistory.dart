import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skincare/Services/app_feedback.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skincare/Controllers/HomeController.dart';
import 'package:skincare/Models/ScanAiModel.dart';
import 'package:skincare/Services/pdf_report_service.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:skincare/Utils/AppTheme.dart';
import 'package:skincare/Views/Auth/Login.dart';
import 'package:skincare/Views/Home/Analysis.Resulat.dart';
import 'package:skincare/Views/Home/scan.dart';

class DiagnosisHistoryView extends StatelessWidget {
  DiagnosisHistoryView({super.key});

  final HomeController homeController = Get.isRegistered<HomeController>()
      ? Get.find<HomeController>()
      : Get.put(HomeController(), permanent: true);

  List<dynamic> get historyItems => homeController.diagnosisHistory;

  bool get isGuest => homeController.isGuestMode.value;
  bool get isLoading => homeController.isLoading.value;
  String get errorMessage => homeController.errorMessage.value ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppTheme.backgroundGradient(
        child: Obx(() {
          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (isGuest) {
            return _buildGuestState();
          }

          if (errorMessage.trim().isNotEmpty) {
            return _buildErrorState();
          }

          if (historyItems.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _buildTopBar(),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStatsSummary(),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    await homeController.refreshDiagnosisHistory();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    physics: const BouncingScrollPhysics(),
                    itemCount: historyItems.length,
                    itemBuilder: (context, index) {
                      final item = historyItems[index];
                      return _buildHistoryCard(item, index);
                    },
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        AppTheme.circleBackButton(onTap: Get.back),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'diagnosis_history_title'.tr,
                style: AppTheme.headingStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'diagnosis_history_subtitle'.tr,
                style: AppTheme.bodyStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary.withOpacity(.92),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => homeController.refreshDiagnosisHistory(),
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
            child: const Icon(
              Icons.refresh_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSummary() {
    final totalScans = historyItems.length;
    final highCount = historyItems.where((e) {
      final urgency = _scanUrgency(e).toLowerCase();
      return urgency == 'high';
    }).length;

    final lowCount = historyItems.where((e) {
      final urgency = _scanUrgency(e).toLowerCase();
      return urgency == 'low';
    }).length;

    return AppTheme.glassPanel(
      borderRadius: 16,
      borderColor: AppColors.primary.withOpacity(0.3),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              '$totalScans',
              'diagnosis_total_scans',
              Icons.analytics_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatItem(
              '$highCount',
              'diagnosis_high_priority',
              Icons.priority_high_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatItem(
              '$lowCount',
              'diagnosis_low_priority',
              Icons.verified_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(dynamic item, int index) {
    final urgency = _scanUrgency(item);
    final title = _scanTitle(item);
    final dateText = _scanDate(item);
    final scanType = _scanType(item);
    final quality = _scanQuality(item);

    return AppTheme.glassPanel(
      borderRadius: 16,
      margin: const EdgeInsets.only(bottom: 18),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodyStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dateText,
                        style: AppTheme.bodyStyle(
                          color: AppColors.textSecondary.withOpacity(.78),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildMiniMetaChip(
                            icon: Icons.auto_awesome_rounded,
                            label: scanType,
                          ),
                          _buildMiniMetaChip(
                            icon: Icons.photo_filter_outlined,
                            label: quality,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildPriorityBadge(urgency),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 1,
            color: AppColors.primary.withOpacity(.12),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    Icons.visibility_outlined,
                    'diagnosis_details'.tr,
                    AppColors.primary,
                    () async {
                      final parsed = _toScanResult(item);
                      if (parsed == null) return;
                      final action = await Get.to<String>(
                        () => AnalysisResultView(result: parsed),
                      );
                      // A report is immutable while it is being viewed, so
                      // returning normally keeps the cached list instant.
                      // A new scan is the only path that can change it.
                      if (action == 'rescan') {
                        await Get.to(() => ScanView());
                        await homeController.refreshDiagnosisHistory();
                      }
                    },
                  ),
                ),
                Expanded(
                  child: _buildActionButton(
                    Icons.share_outlined,
                    'diagnosis_share'.tr,
                    AppColors.accent,
                    () => _shareHistoryResult(item),
                  ),
                ),
                Expanded(
                  child: _buildActionButton(
                    Icons.delete_outline_rounded,
                    'diagnosis_delete'.tr,
                    Colors.redAccent,
                    () async {
                      final scanId = _scanId(item);
                      if (scanId.isEmpty) return;

                      final confirm = await Get.dialog<bool>(
                        AlertDialog(
                          backgroundColor: AppColors.background,
                          title: Text(
                            'confirm_delete_title'.tr,
                            style: AppTheme.headingStyle(fontSize: 18),
                          ),
                          content: Text(
                            'confirm_delete_message'.tr,
                            style: AppTheme.bodyStyle(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: Text(
                                'cancel'.tr,
                                style: AppTheme.bodyStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Get.back(result: true),
                              child: Text(
                                'delete'.tr,
                                style: AppTheme.bodyStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await homeController.deleteScan(scanId);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTopBar(),
          const Spacer(),
          AppTheme.glassPanel(
            borderRadius: 16,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    size: 38,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'guest_history_title'.tr,
                  textAlign: TextAlign.center,
                  style: AppTheme.headingStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'guest_history_desc'.tr,
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary.withOpacity(.92),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: AppTheme.goldButton(
                    text: 'sign_in_to_view_history'.tr,
                    onPressed: () => Get.to(() => LoginView()),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTopBar(),
          const Spacer(),
          AppTheme.glassPanel(
            borderRadius: 16,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.history_toggle_off_rounded,
                    size: 38,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'no_diagnosis_history_title'.tr,
                  textAlign: TextAlign.center,
                  style: AppTheme.headingStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'no_diagnosis_history_desc'.tr,
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary.withOpacity(.92),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: AppTheme.goldButton(
                    text: 'start_new_scan'.tr,
                    onPressed: () async {
                      await Get.to(() => ScanView());
                      await homeController.refreshDiagnosisHistory();
                    },
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTopBar(),
          const Spacer(),
          AppTheme.glassPanel(
            borderRadius: 16,
            padding: const EdgeInsets.all(24),
            borderColor: Colors.redAccent.withOpacity(0.5),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  'something_went_wrong'.tr,
                  style: AppTheme.headingStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyStyle(
                    color: AppColors.textSecondary.withOpacity(.9),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: AppTheme.goldButton(
                    text: 'try_again'.tr,
                    onPressed: () => homeController.loadHomeData(),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String urgency) {
    final normalized = urgency.toLowerCase();

    Color color;
    String label;
    IconData icon;

    if (normalized == 'high') {
      color = Colors.redAccent;
      label = 'priority_high'.tr;
      icon = Icons.priority_high_rounded;
    } else if (normalized == 'medium') {
      color = AppColors.accent;
      label = 'priority_medium'.tr;
      icon = Icons.error_outline_rounded;
    } else {
      color = AppColors.primary;
      label = normalized == 'low' ? 'priority_low'.tr : '--';
      icon = Icons.info_outline_rounded;
    }

    return AppTheme.statusBadge(label: label, color: color, icon: icon);
  }

  Widget _buildMiniMetaChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withOpacity(.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Container(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyStyle(
                color: AppColors.textSecondary.withOpacity(.92),
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareHistoryResult(dynamic item) async {
    final result = _toScanResult(item);
    if (result == null) return;

    try {
      AppFeedback.info(
        'pdf_preparing_desc'.tr,
        title: 'pdf_preparing_title'.tr,
      );

      final isArabic = (Get.locale?.languageCode ?? 'en')
          .toLowerCase()
          .startsWith('ar');
      final bytes = await PdfReportService.generateReportBytes(
        result: result,
        isArabic: isArabic,
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
    } catch (e) {
      AppFeedback.error(e.toString(), title: 'error'.tr);
    }
  }

  String _scanId(dynamic item) {
    if (item is Map<String, dynamic>) {
      return item['id']?.toString() ?? '';
    }
    return '';
  }

  String _scanTitle(dynamic item) {
    final title = _toScanResult(item)?.title.trim() ?? '';
    return title.isEmpty ? 'diagnosis_card_title'.tr : title;
  }

  String _scanType(dynamic item) {
    final result = _toScanResult(item);
    return result == null
        ? '--'
        : ReportPresentation.target(
            result,
            (Get.locale?.languageCode ?? 'en').startsWith('ar'),
          );
  }

  String _scanQuality(dynamic item) => ReportPresentation.text(
    _toScanResult(item)?.imageQualityByLang(Get.locale?.languageCode ?? 'en') ??
        '',
  );

  String _scanUrgency(dynamic item) => _toScanResult(item)?.urgency ?? '';

  String _scanDate(dynamic item) =>
      ReportPresentation.date(_toScanResult(item)?.createdAt);

  ScanAiResult? _toScanResult(dynamic item) {
    if (item is ScanAiResult) return item;

    if (item is Map<String, dynamic>) {
      try {
        return ScanAiResult.fromJson(item);
      } catch (_) {
        return null;
      }
    }

    return null;
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String labelKey;
  final IconData icon;

  const _StatItem(this.value, this.labelKey, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 18),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTheme.headingStyle(
              color: AppColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            labelKey.tr,
            textAlign: TextAlign.center,
            style: AppTheme.bodyStyle(
              color: AppColors.textPrimary.withOpacity(.72),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
