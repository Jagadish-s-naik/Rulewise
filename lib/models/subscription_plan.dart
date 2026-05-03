enum SubscriptionTier {
  free,
  protection,
  businessShield,
  enterprise,
}

class SubscriptionFeature {
  static const String viewCompliance = 'view_only_compliance';
  static const String riskMonitor = 'risk_monitor';
  static const String guidedAcquisition = 'guided_acquisition';
  static const String renewalAutomation = 'renewal_automation';
  static const String monthlyReports = 'monthly_reports';
  static const String emergencyMode = 'emergency_mode';
  static const String lawChangeRadar = 'law_change_radar';
  static const String fineSimulator = 'fine_simulator';
  static const String timelineView = 'timeline_view';
  static const String growthAdvisor = 'growth_advisor';
  static const String multiBusiness = 'multi_business';
  static const String unlimitedAi = 'unlimited_ai';
}

extension SubscriptionTierExtension on SubscriptionTier {
  String get name {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.protection:
        return 'Protection';
      case SubscriptionTier.businessShield:
        return 'Business Shield';
      case SubscriptionTier.enterprise:
        return 'Enterprise';
    }
  }

  int get priceInr {
    switch (this) {
      case SubscriptionTier.free:
        return 0;
      case SubscriptionTier.protection:
        return 249;
      case SubscriptionTier.businessShield:
        return 399;
      case SubscriptionTier.enterprise:
        return 999;
    }
  }

  bool get isPremium => this != SubscriptionTier.free;

  bool hasFeature(String feature) {
    switch (this) {
      case SubscriptionTier.free:
        return feature == SubscriptionFeature.viewCompliance;

      case SubscriptionTier.protection:
        return [
          SubscriptionFeature.viewCompliance,
          SubscriptionFeature.riskMonitor,
          SubscriptionFeature.guidedAcquisition,
          SubscriptionFeature.renewalAutomation,
        ].contains(feature);

      case SubscriptionTier.businessShield:
      case SubscriptionTier.enterprise:
        return true; // Business Shield and above have everything
    }
  }

  int get aiQueriesPerWeek {
    switch (this) {
      case SubscriptionTier.free:
        return 3;
      case SubscriptionTier.protection:
        return 15;
      case SubscriptionTier.businessShield:
        return 50;
      case SubscriptionTier.enterprise:
        return 9999; // Unlimited
    }
  }

  int get maxDocuments {
    switch (this) {
      case SubscriptionTier.free:
        return 5;
      case SubscriptionTier.protection:
        return 20;
      case SubscriptionTier.businessShield:
      case SubscriptionTier.enterprise:
        return 9999; // Unlimited
    }
  }
}
