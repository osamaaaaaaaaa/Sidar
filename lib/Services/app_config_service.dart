import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

enum AppStatusType { normal, maintenance, forceUpdate, optionalUpdate }

class AppCheckResult {
  final AppStatusType status;
  final String currentVersion;
  final AppRemoteConfig config;

  const AppCheckResult({
    required this.status,
    required this.currentVersion,
    required this.config,
  });

  bool get isMaintenance => status == AppStatusType.maintenance;
  bool get isForceUpdate => status == AppStatusType.forceUpdate;
  bool get isOptionalUpdate => status == AppStatusType.optionalUpdate;
  bool get isNormal => status == AppStatusType.normal;
}

class AppRemoteConfig {
  final String minSupportedVersion;
  final String latestVersion;
  final bool forceUpdate;
  final bool maintenanceMode;
  final String maintenanceTitleAr;
  final String maintenanceTitleEn;
  final String maintenanceMessageAr;
  final String maintenanceMessageEn;
  final String updateTitleAr;
  final String updateTitleEn;
  final String updateMessageAr;
  final String updateMessageEn;
  final String androidStoreUrl;
  final String iosStoreUrl;
  final String privacyPolicyUrl;

  const AppRemoteConfig({
    this.minSupportedVersion = '1.0.0',
    this.latestVersion = '1.0.0',
    this.forceUpdate = false,
    this.maintenanceMode = false,
    this.maintenanceTitleAr = 'التطبيق قيد الصيانة المجدولة',
    this.maintenanceTitleEn = 'App Under Maintenance',
    this.maintenanceMessageAr =
        'نقوم حالياً بإجراء تحديثات وتحسينات لضمان أفضل تجربة لك. سنعود للعمل قريباً جداً.',
    this.maintenanceMessageEn =
        'We are currently performing scheduled maintenance to enhance your experience. We will be back shortly.',
    this.updateTitleAr = 'تحديث جديد متوفر لتطبيق سدر',
    this.updateTitleEn = 'New SIDAR Update Available',
    this.updateMessageAr =
        'يتوفر إصدار جديد يحتوي على تحسينات ومزايا هامة لتحليل البشرة وتجربة الاستخدام.',
    this.updateMessageEn =
        'A new version with important improvements and features is available.',
    this.androidStoreUrl =
        'https://play.google.com/store/apps/details?id=com.sidarai.app',
    this.iosStoreUrl = 'https://apps.apple.com/app/id6440000000',
    this.privacyPolicyUrl = '',
  });

  factory AppRemoteConfig.fromJson(Map<String, dynamic> json) {
    return AppRemoteConfig(
      minSupportedVersion: (json['min_supported_version'] ?? '1.0.0')
          .toString(),
      latestVersion: (json['latest_version'] ?? '1.0.0').toString(),
      forceUpdate: json['force_update'] == true,
      maintenanceMode: json['maintenance_mode'] == true,
      maintenanceTitleAr:
          (json['maintenance_title_ar'] ?? 'التطبيق قيد الصيانة المجدولة')
              .toString(),
      maintenanceTitleEn:
          (json['maintenance_title_en'] ?? 'App Under Maintenance').toString(),
      maintenanceMessageAr:
          (json['maintenance_message_ar'] ??
                  'نقوم حالياً بإجراء تحديثات وتحسينات لضمان أفضل تجربة لك. سنعود للعمل قريباً جداً.')
              .toString(),
      maintenanceMessageEn:
          (json['maintenance_message_en'] ??
                  'We are currently performing scheduled maintenance to enhance your experience. We will be back shortly.')
              .toString(),
      updateTitleAr: (json['update_title_ar'] ?? 'تحديث جديد متوفر لتطبيق سدر')
          .toString(),
      updateTitleEn: (json['update_title_en'] ?? 'New SIDAR Update Available')
          .toString(),
      updateMessageAr:
          (json['update_message_ar'] ??
                  'يتوفر إصدار جديد يحتوي على تحسينات ومزايا هامة لتحليل البشرة وتجربة الاستخدام.')
              .toString(),
      updateMessageEn:
          (json['update_message_en'] ??
                  'A new version with important improvements and features is available.')
              .toString(),
      androidStoreUrl:
          (json['android_store_url'] ??
                  'https://play.google.com/store/apps/details?id=com.sidarai.app')
              .toString(),
      iosStoreUrl:
          (json['ios_store_url'] ?? 'https://apps.apple.com/app/id6440000000')
              .toString(),
      privacyPolicyUrl: (json['privacy_policy_url'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'min_supported_version': minSupportedVersion,
    'latest_version': latestVersion,
    'force_update': forceUpdate,
    'maintenance_mode': maintenanceMode,
    'maintenance_title_ar': maintenanceTitleAr,
    'maintenance_title_en': maintenanceTitleEn,
    'maintenance_message_ar': maintenanceMessageAr,
    'maintenance_message_en': maintenanceMessageEn,
    'update_title_ar': updateTitleAr,
    'update_title_en': updateTitleEn,
    'update_message_ar': updateMessageAr,
    'update_message_en': updateMessageEn,
    'android_store_url': androidStoreUrl,
    'ios_store_url': iosStoreUrl,
    'privacy_policy_url': privacyPolicyUrl,
  };
}

/// Central service for checking app versioning, forced updates, and maintenance status.
class AppConfigService {
  AppConfigService._();
  static final AppConfigService instance = AppConfigService._();

  static const String configRowKey = 'mobile_app_config';

  AppRemoteConfig _cachedConfig = const AppRemoteConfig();
  String _cachedVersion = '1.0.0';
  String _cachedBuildNumber = '1';
  bool _hasFetchedVersion = false;

  /// Fetch current app version from package_info_plus
  Future<String> getCurrentVersion() async {
    if (_hasFetchedVersion) return _cachedVersion;
    try {
      final info = await PackageInfo.fromPlatform();
      _cachedVersion = info.version;
      _cachedBuildNumber = info.buildNumber;
      _hasFetchedVersion = true;
    } catch (_) {
      _cachedVersion = '1.0.0';
      _cachedBuildNumber = '1';
    }
    return _cachedVersion;
  }

  /// Get formatted version with build number e.g. "1.0.0 (1)"
  Future<String> getFormattedVersion() async {
    await getCurrentVersion();
    return '$_cachedVersion ($_cachedBuildNumber)';
  }

  /// Fetch remote configuration from Supabase platform_settings table
  Future<AppRemoteConfig> fetchRemoteConfig({bool forceRefresh = false}) async {
    try {
      final response = await Supabase.instance.client
          .from('platform_settings')
          .select('value')
          .eq('key', configRowKey)
          .maybeSingle();

      if (response != null && response['value'] != null) {
        final val = response['value'];
        if (val is Map<String, dynamic>) {
          _cachedConfig = AppRemoteConfig.fromJson(val);
        } else if (val is Map) {
          _cachedConfig = AppRemoteConfig.fromJson(
            Map<String, dynamic>.from(val),
          );
        }
      }
    } catch (_) {
      // Fallback to cached or default configuration on network/table errors
    }
    return _cachedConfig;
  }

  /// Perform full status check: Maintenance Mode -> Force Update -> Optional Update -> Normal
  Future<AppCheckResult> checkStatus({String? overrideCurrentVersion}) async {
    final currentVersion = overrideCurrentVersion ?? await getCurrentVersion();
    final config = await fetchRemoteConfig();

    // 1. Check Maintenance Mode
    if (config.maintenanceMode) {
      return AppCheckResult(
        status: AppStatusType.maintenance,
        currentVersion: currentVersion,
        config: config,
      );
    }

    // 2. Check Force Update: current version is below minimum supported version, or force_update flag is true
    final isBelowMin =
        compareVersions(currentVersion, config.minSupportedVersion) < 0;
    final isBelowLatest =
        compareVersions(currentVersion, config.latestVersion) < 0;

    if (isBelowMin || (config.forceUpdate && isBelowLatest)) {
      return AppCheckResult(
        status: AppStatusType.forceUpdate,
        currentVersion: currentVersion,
        config: config,
      );
    }

    // 3. Check Optional Soft Update
    if (isBelowLatest) {
      return AppCheckResult(
        status: AppStatusType.optionalUpdate,
        currentVersion: currentVersion,
        config: config,
      );
    }

    // 4. Normal operational status
    return AppCheckResult(
      status: AppStatusType.normal,
      currentVersion: currentVersion,
      config: config,
    );
  }

  /// Compares two semver strings: returns -1 if v1 < v2, 1 if v1 > v2, 0 if equal
  static int compareVersions(String v1, String v2) {
    final clean1 = v1.split('+').first.trim();
    final clean2 = v2.split('+').first.trim();

    final parts1 = clean1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = clean2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = parts1.length > parts2.length
        ? parts1.length
        : parts2.length;
    for (int i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }
    return 0;
  }

  /// Launch the relevant app store to download the update
  Future<bool> openStoreUrl({String? customUrl}) async {
    final config = _cachedConfig;
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final urlString =
        customUrl ?? (isIos ? config.iosStoreUrl : config.androidStoreUrl);
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
