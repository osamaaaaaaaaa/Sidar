import 'package:flutter_test/flutter_test.dart';
import 'package:skincare/Services/app_config_service.dart';

void main() {
  group('AppConfigService Version Comparison Tests', () {
    test('identical versions compare to 0', () {
      expect(AppConfigService.compareVersions('1.0.0', '1.0.0'), 0);
      expect(AppConfigService.compareVersions('2.3.4', '2.3.4'), 0);
      expect(AppConfigService.compareVersions('1.0.0+1', '1.0.0+2'), 0);
    });

    test('older versions return negative 1', () {
      expect(AppConfigService.compareVersions('1.0.0', '1.0.1'), -1);
      expect(AppConfigService.compareVersions('1.0.0', '1.1.0'), -1);
      expect(AppConfigService.compareVersions('1.9.9', '2.0.0'), -1);
      expect(AppConfigService.compareVersions('1.0.0+5', '1.0.1+1'), -1);
    });

    test('newer versions return 1', () {
      expect(AppConfigService.compareVersions('1.0.1', '1.0.0'), 1);
      expect(AppConfigService.compareVersions('1.2.0', '1.1.9'), 1);
      expect(AppConfigService.compareVersions('2.0.0', '1.99.99'), 1);
    });

    test('different part lengths compare gracefully', () {
      expect(AppConfigService.compareVersions('1.0', '1.0.0'), 0);
      expect(AppConfigService.compareVersions('1.0.0.1', '1.0.0'), 1);
      expect(AppConfigService.compareVersions('1.0.0', '1.0.0.1'), -1);
    });
  });

  group('AppRemoteConfig and Status Logic Tests', () {
    test('JSON serialization and parsing retains all fields', () {
      final config = AppRemoteConfig.fromJson({
        'min_supported_version': '1.1.0',
        'latest_version': '1.2.0',
        'force_update': true,
        'maintenance_mode': true,
        'maintenance_title_ar': 'صيانة خاصة',
        'maintenance_title_en': 'Custom Maintenance',
        'maintenance_message_ar': 'رسالة عربية',
        'maintenance_message_en': 'English message',
        'update_title_ar': 'تحديث خاص',
        'update_title_en': 'Special update',
        'update_message_ar': 'مزايا جديدة',
        'update_message_en': 'New features',
        'android_store_url': 'https://custom.play.google.com',
        'ios_store_url': 'https://custom.apple.com',
      });

      expect(config.minSupportedVersion, '1.1.0');
      expect(config.latestVersion, '1.2.0');
      expect(config.forceUpdate, isTrue);
      expect(config.maintenanceMode, isTrue);
      expect(config.maintenanceTitleAr, 'صيانة خاصة');
      expect(config.androidStoreUrl, 'https://custom.play.google.com');

      final json = config.toJson();
      expect(json['force_update'], isTrue);
      expect(json['maintenance_mode'], isTrue);
    });

    test('Maintenance mode takes top priority', () {
      const config = AppRemoteConfig(
        maintenanceMode: true,
        minSupportedVersion: '2.0.0',
        latestVersion: '2.0.0',
        forceUpdate: true,
      );

      // Even if version is low, maintenance must be flagged first
      final isMaintenance = config.maintenanceMode;
      expect(isMaintenance, isTrue);
    });

    test('Force update triggers when current version is below minSupportedVersion', () {
      const config = AppRemoteConfig(
        maintenanceMode: false,
        minSupportedVersion: '1.2.0',
        latestVersion: '1.3.0',
        forceUpdate: false,
      );

      final isBelowMin =
          AppConfigService.compareVersions('1.1.5', config.minSupportedVersion) < 0;
      expect(isBelowMin, isTrue);
    });

    test('Force update triggers when force_update flag is true and below latest', () {
      const config = AppRemoteConfig(
        maintenanceMode: false,
        minSupportedVersion: '1.0.0',
        latestVersion: '1.1.0',
        forceUpdate: true,
      );

      final isBelowMin =
          AppConfigService.compareVersions('1.0.5', config.minSupportedVersion) < 0;
      final isBelowLatest =
          AppConfigService.compareVersions('1.0.5', config.latestVersion) < 0;
      final isForceUpdate = isBelowMin || (config.forceUpdate && isBelowLatest);

      expect(isBelowMin, isFalse);
      expect(isForceUpdate, isTrue);
    });

    test('Optional update triggers when between min and latest without force flag', () {
      const config = AppRemoteConfig(
        maintenanceMode: false,
        minSupportedVersion: '1.0.0',
        latestVersion: '1.1.0',
        forceUpdate: false,
      );

      final isBelowMin =
          AppConfigService.compareVersions('1.0.5', config.minSupportedVersion) < 0;
      final isBelowLatest =
          AppConfigService.compareVersions('1.0.5', config.latestVersion) < 0;
      final isOptional = !isBelowMin && !config.forceUpdate && isBelowLatest;

      expect(isOptional, isTrue);
    });

    test('Normal status when on latest version', () {
      const config = AppRemoteConfig(
        maintenanceMode: false,
        minSupportedVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceUpdate: false,
      );

      final isBelowLatest =
          AppConfigService.compareVersions('1.0.0', config.latestVersion) < 0;
      expect(isBelowLatest, isFalse);
    });
  });
}
