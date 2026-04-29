import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService._(this._remoteConfig);

  static Future<RemoteConfigService> init() async {
    final remoteConfig = FirebaseRemoteConfig.instance;

    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1), // Decrease during development if needed
    ));

    // Set default values
    await remoteConfig.setDefaults(const {
      'free_tier_query_limit': 10,
      'basic_tier_query_limit': 100,
      'emergency_alert_enabled': false,
      'emergency_alert_message': '',
    });

    try {
      await remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint('Failed to fetch remote config: $e');
    }

    return RemoteConfigService._(remoteConfig);
  }

  int get freeTierQueryLimit => _remoteConfig.getInt('free_tier_query_limit');
  int get basicTierQueryLimit => _remoteConfig.getInt('basic_tier_query_limit');
  bool get isEmergencyAlertEnabled => _remoteConfig.getBool('emergency_alert_enabled');
  String get emergencyAlertMessage => _remoteConfig.getString('emergency_alert_message');
}
