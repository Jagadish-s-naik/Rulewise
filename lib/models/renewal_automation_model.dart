import 'package:cloud_firestore/cloud_firestore.dart';

class RenewalAutomation {
  final String licenseId;
  final bool enabled;
  final DateTime? lastReminderSent;
  final DateTime? nextActionDate;
  final List<String> completedSteps;
  final Map<String, dynamic> metadata;

  RenewalAutomation({
    required this.licenseId,
    required this.enabled,
    this.lastReminderSent,
    this.nextActionDate,
    this.completedSteps = const [],
    this.metadata = const {},
  });

  factory RenewalAutomation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RenewalAutomation(
      licenseId: data['license_id'] ?? '',
      enabled: data['enabled'] ?? false,
      lastReminderSent: data['last_reminder_sent'] != null
          ? (data['last_reminder_sent'] as Timestamp).toDate()
          : null,
      nextActionDate: data['next_action_date'] != null
          ? (data['next_action_date'] as Timestamp).toDate()
          : null,
      completedSteps: List<String>.from(data['completed_steps'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'license_id': licenseId,
      'enabled': enabled,
      'last_reminder_sent': lastReminderSent != null
          ? Timestamp.fromDate(lastReminderSent!)
          : null,
      'next_action_date':
          nextActionDate != null ? Timestamp.fromDate(nextActionDate!) : null,
      'completed_steps': completedSteps,
      'metadata': metadata,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  RenewalAutomation copyWith({
    String? licenseId,
    bool? enabled,
    DateTime? lastReminderSent,
    DateTime? nextActionDate,
    List<String>? completedSteps,
    Map<String, dynamic>? metadata,
  }) {
    return RenewalAutomation(
      licenseId: licenseId ?? this.licenseId,
      enabled: enabled ?? this.enabled,
      lastReminderSent: lastReminderSent ?? this.lastReminderSent,
      nextActionDate: nextActionDate ?? this.nextActionDate,
      completedSteps: completedSteps ?? this.completedSteps,
      metadata: metadata ?? this.metadata,
    );
  }
}
