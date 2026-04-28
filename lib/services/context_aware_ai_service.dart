import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/license_model.dart';
import '../models/user_license_model.dart';
import '../models/risk_profile.dart';

class ContextAwareAIService {
  // Replace with your actual API key
  static const String _apiKey = 'YOUR_OPENAI_API_KEY';
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  /// Ask AI with full user context injection
  Future<String> askWithContext({
    required String userQuery,
    required String city,
    required String state,
    required String businessType,
    required List<LicenseModel> applicableLicenses,
    required List<UserLicenseModel> userLicenses,
    required RiskProfile riskProfile,
  }) async {
    try {
      // Build context-rich prompt
      final contextPrompt = _buildContextPrompt(
        userQuery: userQuery,
        city: city,
        state: state,
        businessType: businessType,
        applicableLicenses: applicableLicenses,
        userLicenses: userLicenses,
        riskProfile: riskProfile,
      );

      // Call OpenAI API
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a compliance assistant for Indian businesses. '
                  'Provide specific, actionable advice based on the user context. '
                  'Reference exact fees, penalties, and deadlines. '
                  'Do NOT provide generic legal advice.',
            },
            {
              'role': 'user',
              'content': contextPrompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['choices'][0]['message']['content'] as String;
        return answer;
      } else {
        debugPrint('AI API error: ${response.statusCode} - ${response.body}');
        return 'Sorry, I could not process your request. Please try again.';
      }
    } catch (e) {
      debugPrint('Error calling AI: $e');
      return 'An error occurred. Please check your connection and try again.';
    }
  }

  /// Build comprehensive context prompt
  String _buildContextPrompt({
    required String userQuery,
    required String city,
    required String state,
    required String businessType,
    required List<LicenseModel> applicableLicenses,
    required List<UserLicenseModel> userLicenses,
    required RiskProfile riskProfile,
  }) {
    final userLicenseIds = userLicenses.map((ul) => ul.licenseId).toSet();
    final activeLicenses =
        applicableLicenses.where((l) => userLicenseIds.contains(l.id)).toList();
    final missingLicenses = applicableLicenses
        .where((l) => !userLicenseIds.contains(l.id))
        .toList();

    final buffer = StringBuffer();

    buffer.writeln('USER CONTEXT:');
    buffer.writeln('- Location: $city, $state');
    buffer.writeln('- Business Type: ${_formatBusinessType(businessType)}');
    buffer.writeln('- Compliance Score: ${riskProfile.overallScore.round()}%');
    buffer.writeln('- Risk Level: ${_formatRiskLevel(riskProfile.level)}');
    buffer.writeln();

    buffer.writeln('ACTIVE LICENSES (${activeLicenses.length}):');
    for (var license in activeLicenses) {
      buffer.writeln('- ${license.name}');
    }
    buffer.writeln();

    buffer.writeln('MISSING LICENSES (${missingLicenses.length}):');
    for (var license in missingLicenses) {
      buffer.writeln('- ${license.name}: Fee ₹${license.fee}, '
          'Penalty ₹${license.penaltyPerMonth}/month');
    }
    buffer.writeln();

    buffer.writeln('COMPLIANCE DATABASE (Applicable Licenses):');
    for (var license in applicableLicenses) {
      buffer.writeln('- ${license.name}:');
      buffer.writeln('  * Fee: ₹${license.fee}');
      buffer.writeln('  * Renewal: ${license.renewalCycle}');
      buffer.writeln('  * Penalty: ₹${license.penaltyPerMonth}/month');
      buffer.writeln('  * Mandatory: ${license.isMandatory ? "YES" : "No"}');
      buffer.writeln('  * Department: ${license.department}');
    }
    buffer.writeln();

    if (riskProfile.riskFactors.isNotEmpty) {
      buffer.writeln('CURRENT RISK FACTORS:');
      for (var factor in riskProfile.riskFactors) {
        buffer.writeln('- ${factor.description} (Impact: ${factor.impact})');
      }
      buffer.writeln();
    }

    buffer.writeln('USER QUESTION:');
    buffer.writeln(userQuery);
    buffer.writeln();

    buffer.writeln('INSTRUCTIONS:');
    buffer.writeln('1. Answer using ONLY the context above');
    buffer.writeln('2. Reference exact fees, penalties, and deadlines');
    buffer.writeln('3. Provide specific next steps');
    buffer.writeln(
        '4. If asking about a license, mention which department issues it');
    buffer.writeln('5. If user is missing critical licenses, warn them');
    buffer.writeln('6. Keep answer concise and actionable');

    return buffer.toString();
  }

  String _formatBusinessType(String type) {
    return type.replaceAll('_', ' ').split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _formatRiskLevel(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return 'SAFE';
      case RiskLevel.warning:
        return 'WARNING';
      case RiskLevel.highRisk:
        return 'HIGH RISK';
    }
  }

  /// Track AI usage for subscription limits
  Future<void> trackUsage(String userId) async {
    // This would increment usage counter in Firestore
    // Implementation depends on your subscription tracking system
  }

  /// Check if user can make AI query based on subscription
  Future<bool> canMakeQuery(String userId, String subscriptionTier) async {
    // Implementation would check:
    // - Free: 1 query/week
    // - Protection: 5 queries/week
    // - Business Shield+: Unlimited

    // For now, return true
    return true;
  }
}
