import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/risk_profile.dart';

class LicenseModel {
  final String id;
  final String name;
  final String officialName;
  final String department;
  final String description;
  final RiskLevel
      riskLevel; // NEW: Risk Level associated with missing/expired license
  final int fee;
  final String renewalCycle;
  final int penaltyPerMonth;
  final int gracePeriodDays;
  final String applicationUrl;
  final String helpline;
  final List<String> requiredDocuments;
  final String processingTime;
  final bool isMandatory;

  // NEW: Verification & Legal Compliance Fields
  final String sourceUrl; // Official government source
  final DateTime lastVerified; // When data was last verified
  final String verificationNotes; // Notes about data verification
  final String whyRequired; // Why this license is legally required
  final List<ApplicationStep> applicationSteps; // Step-by-step guide

  LicenseModel({
    required this.id,
    required this.name,
    required this.officialName,
    required this.department,
    required this.description,
    required this.fee,
    required this.renewalCycle,
    required this.penaltyPerMonth,
    required this.gracePeriodDays,
    required this.applicationUrl,
    required this.helpline,
    required this.requiredDocuments,
    required this.processingTime,
    required this.isMandatory,
    this.riskLevel = RiskLevel.safe, // Default to safe
    this.sourceUrl = '',
    DateTime? lastVerified,
    this.verificationNotes = '',
    this.whyRequired = '',
    this.applicationSteps = const [],
  }) : lastVerified = lastVerified ?? DateTime.now();

  factory LicenseModel.fromFirestore(String id, Map<String, dynamic> data) {
    return LicenseModel(
      id: id,
      name: data['name'] ?? '',
      officialName: data['official_name'] ?? '',
      department: data['department'] ?? '',
      description: data['description'] ?? '',
      fee: data['fee'] ?? 0,
      renewalCycle: data['renewal_cycle'] ?? 'Yearly',
      penaltyPerMonth: data['penalty_per_month'] ?? 0,
      gracePeriodDays: data['grace_period_days'] ?? 0,
      applicationUrl: data['application_url'] ?? '',
      helpline: data['helpline'] ?? '',
      requiredDocuments: List<String>.from(data['required_documents'] ?? []),
      processingTime: data['processing_time'] ?? '',
      isMandatory: data['is_mandatory'] ?? false,
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.toString() == 'RiskLevel.${data['risk_level'] ?? 'safe'}',
        orElse: () => RiskLevel.safe,
      ),
      sourceUrl: data['source_url'] ?? '',
      lastVerified: data['last_verified'] != null
          ? (data['last_verified'] as Timestamp).toDate()
          : null,
      verificationNotes: data['verification_notes'] ?? '',
      whyRequired: data['why_required'] ?? '',
      applicationSteps: (data['application_steps'] as List<dynamic>?)
              ?.map((step) =>
                  ApplicationStep.fromMap(step as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'official_name': officialName,
      'department': department,
      'description': description,
      'fee': fee,
      'renewal_cycle': renewalCycle,
      'penalty_per_month': penaltyPerMonth,
      'grace_period_days': gracePeriodDays,
      'application_url': applicationUrl,
      'helpline': helpline,
      'required_documents': requiredDocuments,
      'processing_time': processingTime,
      'is_mandatory': isMandatory,
      'risk_level': riskLevel.name,
      'source_url': sourceUrl,
      'last_verified': Timestamp.fromDate(lastVerified),
      'verification_notes': verificationNotes,
      'why_required': whyRequired,
      'application_steps':
          applicationSteps.map((step) => step.toMap()).toList(),
    };
  }
}

/// Application step for guided compliance workflow
class ApplicationStep {
  final int stepNumber;
  final String title;
  final String description;
  final List<String> requiredDocuments;
  final String? externalLink;

  ApplicationStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.requiredDocuments,
    this.externalLink,
  });

  factory ApplicationStep.fromMap(Map<String, dynamic> map) {
    return ApplicationStep(
      stepNumber: map['step_number'] ?? 0,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      requiredDocuments: List<String>.from(map['required_documents'] ?? []),
      externalLink: map['external_link'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'step_number': stepNumber,
      'title': title,
      'description': description,
      'required_documents': requiredDocuments,
      'external_link': externalLink,
    };
  }
}
