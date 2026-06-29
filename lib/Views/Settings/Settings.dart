import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skincare/Services/auth_service.dart';
import 'package:skincare/Services/app_feedback.dart';
import 'package:skincare/Services/auth_profile_ui.dart';
import 'package:skincare/Services/app_config_service.dart';
import 'package:skincare/Services/routine_notification_service.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:skincare/Utils/AppTheme.dart';
import 'package:skincare/Views/Auth/Login.dart';
import 'package:skincare/Views/History/DiagnosisHistory.dart';
import 'package:skincare/Views/Settings/EditProfile.dart';
import 'package:skincare/Views/Settings/SkinFingerprint.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

  final RxBool isLoading = true.obs;
  final RxString userName = 'Sidar User'.obs;
  final RxString userEmail = ''.obs;
  final RxInt scansCount = 0.obs;
  final RxBool notificationsEnabled = true.obs;
  final RxString preferredLanguage = 'ar'.obs;
  final Rx<TimeOfDay> morningTime = const TimeOfDay(hour: 8, minute: 30).obs;
  final Rx<TimeOfDay> eveningTime = const TimeOfDay(hour: 21, minute: 0).obs;
  final RxString appVersion = '1.0.0 (1)'.obs;
  final RxBool isCheckingUpdates = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      isLoading.value = true;

      final user = _supabase.auth.currentUser;
      if (user == null) {
        userName.value = '';
        userEmail.value = '';
        scansCount.value = 0;
        Get.offAll(() => const LoginView());
        return;
      }

      userEmail.value = user.email ?? '';

      final profile = await _supabase
          .from('profiles')
          .select('full_name, notifications_enabled, preferred_language')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        userName.value = (profile['full_name'] ?? 'Sidar User').toString();
        notificationsEnabled.value = profile['notifications_enabled'] == true;
        preferredLanguage.value = (profile['preferred_language'] ?? 'ar')
            .toString();
      }

      try {
        final localEnabled = await RoutineNotificationService.instance
            .isEnabled();
        if (profile == null) {
          notificationsEnabled.value = localEnabled;
        }
        morningTime.value = await RoutineNotificationService.instance
            .getMorningTime();
        eveningTime.value = await RoutineNotificationService.instance
            .getEveningTime();
        appVersion.value = await AppConfigService.instance
            .getFormattedVersion();
      } catch (_) {}

      final scans = await _supabase
          .from('scan_sessions')
          .select('id')
          .eq('user_id', user.id);

      scansCount.value = scans.length;
    } catch (_) {
      AppFeedback.error('settings_load_failed'.tr, title: 'settings_error'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleNotifications(bool value) async {
    final oldValue = notificationsEnabled.value;
    notificationsEnabled.value = value;

    try {
      await RoutineNotificationService.instance.setEnabled(value);
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await AuthService().saveProfile({'notifications_enabled': value});
      }
    } catch (_) {
      notificationsEnabled.value = oldValue;
      AppFeedback.error('settings_save_failed'.tr, title: 'settings_error'.tr);
    }
  }

  Future<void> setMorningTime(TimeOfDay time) async {
    morningTime.value = time;
    await RoutineNotificationService.instance.updateMorningTime(time);
  }

  Future<void> setEveningTime(TimeOfDay time) async {
    eveningTime.value = time;
    await RoutineNotificationService.instance.updateEveningTime(time);
  }

  Future<void> checkForAppUpdates() async {
    isCheckingUpdates.value = true;
    try {
      final result = await AppConfigService.instance.checkStatus();
      final isAr = (Get.locale?.languageCode ?? 'ar').toLowerCase().startsWith(
        'ar',
      );

      if (result.isMaintenance) {
        AppFeedback.warning(
          isAr
              ? 'النظام مجدول للدخول في وضع الصيانة قريباً.'
              : 'The system is scheduled for maintenance.',
          title: isAr ? 'تنبيه الصيانة' : 'Maintenance Notice',
        );
        return;
      }

      if (result.isForceUpdate || result.isOptionalUpdate) {
        _showUpdateSheet(result);
      } else {
        AppFeedback.success(
          isAr
              ? 'تطبيق سدر محدّث لأحدث إصدار متاح (${result.currentVersion}).'
              : 'You are using the latest version of SIDAR (${result.currentVersion}).',
          title: isAr ? 'أنت على أحدث إصدار' : 'Up to Date',
        );
      }
    } finally {
      isCheckingUpdates.value = false;
    }
  }

  void _showUpdateSheet(AppCheckResult result) {
    final isAr = (Get.locale?.languageCode ?? 'ar').toLowerCase().startsWith(
      'ar',
    );
    final title = isAr
        ? result.config.updateTitleAr
        : result.config.updateTitleEn;
    final message = isAr
        ? result.config.updateMessageAr
        : result.config.updateMessageEn;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    color: AppColors.gold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: AppTheme.appFontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAr
                            ? 'إصدارك: ${result.currentVersion} • الجديد: ${result.config.latestVersion}'
                            : 'Current: ${result.currentVersion} • New: ${result.config.latestVersion}',
                        style: TextStyle(
                          fontFamily: AppTheme.appFontFamily,
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: TextStyle(
                fontFamily: AppTheme.appFontFamily,
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (!result.isForceUpdate)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: AppColors.gold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        isAr ? 'لاحقاً' : 'Later',
                        style: TextStyle(
                          fontFamily: AppTheme.appFontFamily,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (!result.isForceUpdate) const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      AppConfigService.instance.openStoreUrl();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.oliveGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isAr ? 'تحديث الآن 🚀' : 'Update Now 🚀',
                      style: TextStyle(
                        fontFamily: AppTheme.appFontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      isDismissible: !result.isForceUpdate,
      enableDrag: !result.isForceUpdate,
    );
  }

  Future<void> changeLanguage(String languageCode) async {
    final prevLang = preferredLanguage.value;
    preferredLanguage.value = languageCode;

    final locale = languageCode == 'ar'
        ? const Locale('ar', 'SA')
        : const Locale('en', 'US');
    Get.updateLocale(locale);

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await AuthService().saveProfile({'preferred_language': languageCode});
    } catch (_) {
      preferredLanguage.value = prevLang;
      final rollback = prevLang == 'ar'
          ? const Locale('ar', 'SA')
          : const Locale('en', 'US');
      Get.updateLocale(rollback);
      AppFeedback.error(
        'settings_language_save_failed'.tr,
        title: 'settings_error'.tr,
      );
    }
  }

  Future<void> logout() async {
    try {
      await AuthService().signOut();
      Get.delete<SettingsController>(force: true);
      Get.offAll(() => const LoginView());
    } catch (_) {
      AppFeedback.error(
        'settings_logout_failed'.tr,
        title: 'settings_error'.tr,
      );
    }
  }
}

class SettingsView extends StatelessWidget {
  SettingsView({super.key});

  final SettingsController controller = Get.put(SettingsController());

  bool get _isArabic =>
      (Get.locale?.languageCode ?? 'en').toLowerCase().startsWith('ar');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: AppTheme.backgroundGradient(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Executive Profile Card
              _buildProfileCard(),
              const SizedBox(height: 22),

              // Section 1: Clinical Profile & History
              _sectionCard(
                title: _isArabic
                    ? 'الملف الشخصي والسريري'
                    : 'Clinical Profile & History',
                children: [
                  _settingsRow(
                    icon: Icons.person_outline_rounded,
                    iconColor: AppColors.gold,
                    title: 'settings_edit_profile'.tr,
                    subtitle: 'settings_edit_profile_subtitle'.tr,
                    onTap: () async {
                      final saved = await Get.to(() => const EditProfileView());
                      if (saved == true && !controller.isClosed) {
                        await controller.loadSettings();
                      }
                    },
                  ),
                  _settingsRow(
                    icon: Icons.fingerprint_rounded,
                    iconColor: AppColors.primary,
                    title: 'settings_skin_fingerprint'.tr,
                    subtitle: 'settings_skin_fingerprint_subtitle'.tr,
                    onTap: () => Get.to(() => SkinFingerprintView()),
                  ),
                  Obx(
                    () => _settingsRow(
                      icon: Icons.history_edu_rounded,
                      iconColor: AppColors.gold,
                      title: 'settings_diagnosis_history'.tr,
                      subtitle:
                          '${controller.scansCount.value} ${_isArabic ? 'فحوصات وتقارير سريرية' : 'scans and reports'}',
                      showDivider: false,
                      onTap: () => Get.to(() => DiagnosisHistoryView()),
                    ),
                  ),
                ],
              ),

              // Section 2: Preferences & App Behavior
              _sectionCard(
                title: _isArabic ? 'تفضيلات التطبيق' : 'App Preferences',
                children: [
                  // Modern Segmented Language Switcher
                  _buildLanguagePicker(),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 70,
                      end: 16,
                    ),
                    child: Divider(
                      height: 1,
                      thickness: 0.8,
                      color: AppColors.gold.withValues(alpha: 0.12),
                    ),
                  ),
                  // Notifications & Routine Reminders
                  Obx(
                    () => Column(
                      children: [
                        _settingsRow(
                          icon: Icons.notifications_active_outlined,
                          iconColor: AppColors.gold,
                          title: _isArabic
                              ? 'تذكيرات الروتين اليومي'
                              : 'Daily Routine Reminders',
                          subtitle: _isArabic
                              ? 'تنبيهات يومية للروتين الصباحي والمسائي'
                              : 'Daily morning & evening routine alerts',
                          showDivider: controller.notificationsEnabled.value,
                          trailing: Switch(
                            value: controller.notificationsEnabled.value,
                            onChanged: controller.toggleNotifications,
                            activeThumbColor: AppColors.gold,
                            activeTrackColor: AppColors.goldSoft,
                            inactiveThumbColor: AppColors.textSecondary,
                            inactiveTrackColor: Colors.black.withValues(
                              alpha: 0.08,
                            ),
                          ),
                        ),
                        if (controller.notificationsEnabled.value) ...[
                          _settingsRow(
                            icon: Icons.wb_sunny_rounded,
                            iconColor: const Color(0xFFE5A93C),
                            title: _isArabic
                                ? 'الروتين الصباحي'
                                : 'Morning Routine',
                            subtitle: _isArabic
                                ? 'تذكير لحماية وترطيب البشرة صباحاً'
                                : 'Morning protection & hydration reminder',
                            trailing: _timePill(
                              context: context,
                              time: controller.morningTime.value,
                              onTimePicked: (picked) =>
                                  controller.setMorningTime(picked),
                            ),
                            onTap: () => _pickTime(
                              context: context,
                              initialTime: controller.morningTime.value,
                              onPicked: (picked) =>
                                  controller.setMorningTime(picked),
                            ),
                          ),
                          _settingsRow(
                            icon: Icons.nightlight_round,
                            iconColor: const Color(0xFF5C6BC0),
                            title: _isArabic
                                ? 'الروتين المسائي'
                                : 'Evening Routine',
                            subtitle: _isArabic
                                ? 'تذكير للتنظيف والترميم قبل النوم'
                                : 'Nightly skin repair & nourishment reminder',
                            showDivider: false,
                            trailing: _timePill(
                              context: context,
                              time: controller.eveningTime.value,
                              onTimePicked: (picked) =>
                                  controller.setEveningTime(picked),
                            ),
                            onTap: () => _pickTime(
                              context: context,
                              initialTime: controller.eveningTime.value,
                              onPicked: (picked) =>
                                  controller.setEveningTime(picked),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 70,
                      end: 16,
                    ),
                    child: Divider(
                      height: 1,
                      thickness: 0.8,
                      color: AppColors.gold.withValues(alpha: 0.12),
                    ),
                  ),
                  // App Version & Update Check Row
                  Obx(
                    () => _settingsRow(
                      icon: Icons.system_update_rounded,
                      iconColor: AppColors.oliveGreen,
                      title: _isArabic
                          ? 'التحقق من التحديثات'
                          : 'Check for Updates',
                      subtitle: _isArabic
                          ? 'إصدار التطبيق المثبت: ${controller.appVersion.value}'
                          : 'Installed version: ${controller.appVersion.value}',
                      showDivider: false,
                      trailing: controller.isCheckingUpdates.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.gold,
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.oliveGreen.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.oliveGreen.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                              child: Text(
                                _isArabic ? 'فحص الآن' : 'Check',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.oliveGreen,
                                ),
                              ),
                            ),
                      onTap: controller.isCheckingUpdates.value
                          ? null
                          : controller.checkForAppUpdates,
                    ),
                  ),
                ],
              ),

              // Section 3: Security & Account
              _sectionCard(
                title: _isArabic ? 'الأمان والحساب' : 'Security & Account',
                children: [
                  _settingsRow(
                    icon: Icons.lock_outline_rounded,
                    iconColor: AppColors.primary,
                    title: authText('Change password', 'تغيير كلمة المرور'),
                    subtitle: authText(
                      'Update your account password',
                      'تحديث كلمة مرور حسابك بأمان',
                    ),
                    onTap: () => Get.to(() => const PasswordUpdateView()),
                  ),
                  _settingsRow(
                    icon: Icons.delete_outline_rounded,
                    iconColor: Colors.red,
                    isDestructive: true,
                    title: authText('Delete account', 'حذف الحساب'),
                    subtitle: authText(
                      'Permanently remove your account and scans',
                      'حذف الحساب والبيانات نهائيًا',
                    ),
                    showDivider: false,
                    onTap: () async {
                      final deleted = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const DeleteAccountDialog(),
                      );
                      if (deleted != true || !context.mounted) return;
                      Get.delete<SettingsController>(force: true);
                      Get.offAll(() => const LoginView());
                    },
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Sign Out Button
              InkWell(
                onTap: controller.logout,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'settings_logout'.tr,
                        style: TextStyle(
                          fontFamily: AppTheme.appFontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Luxury App Footer
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/sidar-emblem-clean.png',
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.gold,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'SIDAR AI',
                        style: TextStyle(
                          fontFamily: AppTheme.appFontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: AppColors.primary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
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
            width: 30,
            height: 30,
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
            'settings_title'.tr,
            style: TextStyle(
              fontFamily: AppTheme.appFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFFAF8F3),
            AppColors.sageTint.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        final name = controller.userName.value.trim().isNotEmpty
            ? controller.userName.value.trim()
            : 'Sidar User';
        final email = controller.userEmail.value.trim().isNotEmpty
            ? controller.userEmail.value.trim()
            : 'user@sidar.ai';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

        return Column(
          children: [
            Row(
              children: [
                // Avatar with concentric golden ring
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC8A66A), Color(0xFFB89454)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: AppColors.gold, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontFamily: AppTheme.appFontFamily,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Name and Email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontFamily: AppTheme.appFontFamily,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: AppColors.gold,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: TextStyle(
                          fontFamily: AppTheme.appFontFamily,
                          fontSize: 11.5,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Edit button
                InkWell(
                  onTap: () async {
                    final saved = await Get.to(() => const EditProfileView());
                    if (saved == true && !controller.isClosed) {
                      await controller.loadSettings();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isArabic ? 'تعديل' : 'Edit',
                          style: TextStyle(
                            fontFamily: AppTheme.appFontFamily,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Micro Quick Stats Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _profileMiniStat(
                    icon: Icons.biotech_rounded,
                    label: _isArabic ? 'الفحوصات' : 'Scans',
                    value: '${controller.scansCount.value}',
                    color: AppColors.gold,
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: AppColors.gold.withValues(alpha: 0.2),
                  ),
                  _profileMiniStat(
                    icon: Icons.fingerprint_rounded,
                    label: _isArabic ? 'بصمة البشرة' : 'Skin ID',
                    value: _isArabic ? 'نشطة' : 'Active',
                    color: AppColors.primary,
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: AppColors.gold.withValues(alpha: 0.2),
                  ),
                  _profileMiniStat(
                    icon: Icons.shield_rounded,
                    label: _isArabic ? 'الحساب' : 'Account',
                    value: _isArabic ? 'موثق' : 'Verified',
                    color: const Color(0xFF27AE60),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _profileMiniStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTheme.appFontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.appFontFamily,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 6, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.appFontFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppColors.primary.withValues(alpha: 0.75),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.22),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool showDivider = true,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.red.withValues(alpha: 0.10)
                        : iconColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDestructive
                          ? Colors.red.withValues(alpha: 0.25)
                          : iconColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: isDestructive ? Colors.red : iconColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: AppTheme.appFontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDestructive ? Colors.red : AppColors.primary,
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: AppTheme.appFontFamily,
                            fontSize: 11,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.85,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: AppColors.gold.withValues(alpha: 0.7),
                  ),
              ],
            ),
          ),
          if (showDivider)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 68, end: 16),
              child: Divider(
                height: 1,
                thickness: 0.8,
                color: AppColors.gold.withValues(alpha: 0.12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLanguagePicker() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  size: 19,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'settings_language'.tr,
                      style: TextStyle(
                        fontFamily: AppTheme.appFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isArabic
                          ? 'اختر لغة واجهة التطبيق'
                          : 'Choose app display language',
                      style: TextStyle(
                        fontFamily: AppTheme.appFontFamily,
                        fontSize: 11,
                        color: AppColors.textSecondary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final current = controller.preferredLanguage.value;
            return Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _languageSegment(
                      label: 'العربية (AR)',
                      isSelected: current == 'ar',
                      onTap: () => controller.changeLanguage('ar'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _languageSegment(
                      label: 'English (EN)',
                      isSelected: current == 'en',
                      onTap: () => controller.changeLanguage('en'),
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

  Widget _languageSegment({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: isSelected
              ? Border.all(color: AppColors.gold, width: 1.2)
              : Border.all(color: Colors.transparent),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.appFontFamily,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time, bool isArabic) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final isPm = time.period == DayPeriod.pm;
    final period = isArabic ? (isPm ? 'م' : 'ص') : (isPm ? 'PM' : 'AM');
    return '$hour:$minute $period';
  }

  Widget _timePill({
    required BuildContext context,
    required TimeOfDay time,
    required Function(TimeOfDay) onTimePicked,
  }) {
    return InkWell(
      onTap: () => _pickTime(
        context: context,
        initialTime: time,
        onPicked: onTimePicked,
      ),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 14,
              color: AppColors.gold,
            ),
            const SizedBox(width: 5),
            Text(
              _formatTimeOfDay(time, _isArabic),
              style: TextStyle(
                fontFamily: AppTheme.appFontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime({
    required BuildContext context,
    required TimeOfDay initialTime,
    required Function(TimeOfDay) onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.oliveGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.primary,
            ),
            timePickerTheme: TimePickerThemeData(
              dialHandColor: AppColors.gold,
              dialBackgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      onPicked(picked);
    }
  }
}
