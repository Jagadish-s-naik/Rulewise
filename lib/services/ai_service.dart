import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rulewise/config/api_config.dart';
import '../models/license_model.dart';



class AIService {
  // Get your FREE Groq API key from: https://console.groq.com/keys
  // It's FREE, UNLIMITED, and MUCH FASTER than Gemini!
  // IMPORTANT: Replace the placeholder below with your actual Groq API key
  static const String _apiUrl =
      'https://api.groq.com/openai/v1/chat/completions';


  /// Ask a question with full user context
  Future<String> askQuestion({
    required String question,
    required Map<String, dynamic> userProfile,
    required List<LicenseModel> applicableLicenses,
  }) async {
    // 1. Resolve API Key (Priority: SharedPreferences > ApiConfig)
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('groq_api_key');
    final activeApiKey = (savedKey != null && savedKey.isNotEmpty) 
        ? savedKey 
        : ApiConfig.groqApiKey;

    // 2. Check for Mock Mode
    bool isMockMode = ApiConfig.enableAIServiceMock || 
                     activeApiKey.isEmpty || 
                     activeApiKey.contains('PLACEHOLDER') ||
                     !activeApiKey.startsWith('gsk_');

    if (isMockMode) {
      // Use Local Intelligence Fallback (Offline Mode)
      await Future.delayed(const Duration(seconds: 2)); // Simulate thinking
      return _getLocalIntelligenceResponse(
          question, applicableLicenses, userProfile);
    }



    try {
      final contextPrompt = _buildContextPrompt(
        question: question,
        userProfile: userProfile,
        licenses: applicableLicenses,
      );

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $activeApiKey',
          'Content-Type': 'application/json',
        },


        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'user', 'content': contextPrompt}
          ],
          'temperature': 0.7,
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ??
            'Unable to generate response.';
      } else {
        // Fallback on error
        return _getLocalIntelligenceResponse(
            question, applicableLicenses, userProfile);
      }
    } catch (e) {
      // Fallback on network error
      return _getLocalIntelligenceResponse(
          question, applicableLicenses, userProfile);
    }
  }

  /// FEATURE: Local Intelligence Engine
  /// Generates context-aware answers without needing an external API.
  /// Uses keyword matching against the User's actual data.
  String _getLocalIntelligenceResponse(
    String question,
    List<LicenseModel> licenses,
    Map<String, dynamic> userProfile,
  ) {
    final q = question.toLowerCase();

    // 1. Check for specific license questions
    for (final license in licenses) {
      if (q.contains(license.name.toLowerCase()) ||
          (license.officialName.isNotEmpty &&
              q.contains(license.officialName.toLowerCase())) ||
          q.contains('fee') ||
          q.contains('cost') ||
          q.contains('document')) {
        // precise matching logic
        if (q.contains(license.name.toLowerCase()) ||
            q.contains('all licenses')) {
          return '''
Here are the details for **${license.name}**:

*   **Official Name**: ${license.officialName}
*   **Why Needed**: ${license.description}
*   **Department**: ${license.department}
*   **Fee**: ₹${license.fee} (${license.renewalCycle})
*   **Processing Time**: ${license.processingTime}
*   **Documents Required**:
${license.requiredDocuments.map((d) => '    • $d').join('\n')}

You can apply online at: ${license.applicationUrl}
''';
        }
      }
    }

    // 2. Overview questions
    if (q.contains('license') ||
        q.contains('compliance') ||
        q.contains('list')) {
      final list = licenses
          .map((l) => '• **${l.name}**: ₹${l.fee} (${l.renewalCycle})')
          .join('\n');
      return '''
Based on your profile (${userProfile['location']?['city']}, ${userProfile['business_type']}), here are the ${licenses.length} compliance requirements found:

$list

You can ask me for specific details about any of these!
''';
    }

    // 3. Generic Fallback
    return '''
I can help you with compliance for your **${_formatBusinessType(userProfile['business_type'] ?? '')}** in **${userProfile['location']?['city']}**.

I have access to details for:
${licenses.map((l) => '• ${l.name}').join('\n')}

Try asking:
"How much is the Trade License fee?"
"What documents do I need for GST?"
"How do I apply for FSSAI?"
''';
  }

  String _buildContextPrompt({
    required String question,
    required Map<String, dynamic> userProfile,
    required List<LicenseModel> licenses,
  }) {
    final businessName = userProfile['business_name'] ?? 'Unknown';
    final businessType = userProfile['business_type'] ?? 'Unknown';
    final city = userProfile['location']?['city'] ?? 'Unknown';
    final state = userProfile['location']?['state'] ?? 'Unknown';

    return '''
You are RuleWise AI, an expert government compliance assistant for Indian businesses.

=== USER BUSINESS PROFILE ===
Business Name: $businessName
Business Type: ${_formatBusinessType(businessType)}
Location: ${_formatLocation(city)}, ${_formatLocation(state)}

=== APPLICABLE GOVERNMENT LICENSES (${licenses.length} total) ===
${_formatLicensesForContext(licenses)}

=== YOUR ROLE ===
You must provide SPECIFIC, ACTIONABLE guidance based on the user's exact business profile and location.

CRITICAL RULES:
1. Always reference the user's specific location ($city, $state)
2. Cite actual license names, fees, and departments from the context above
3. Provide real government portal URLs and helpline numbers
4. Give step-by-step instructions, not generic advice
5. If asked about a license, explain:
   - What it is
   - Why it's required for their business type
   - Exact fee amount
   - Where to apply (URL)
   - Required documents
   - Processing time
   - Helpline number
6. Never say "consult a professional" - YOU are the professional
7. Format responses clearly with bullet points and sections

=== USER QUESTION ===
$question

=== YOUR RESPONSE ===
(Provide detailed, context-aware guidance below)
''';
  }

  String _formatBusinessType(String type) {
    final Map<String, String> typeNames = {
      'retail_shop': 'Retail Shop',
      'food_beverage': 'Food & Beverage',
      'service_provider': 'Service Provider',
      'manufacturing': 'Manufacturing',
    };
    return typeNames[type] ?? type;
  }

  String _formatLocation(String location) {
    return location.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _formatLicensesForContext(List<LicenseModel> licenses) {
    if (licenses.isEmpty) {
      return 'No licenses loaded. Please ensure user profile is complete.';
    }

    final buffer = StringBuffer();
    for (var i = 0; i < licenses.length; i++) {
      final license = licenses[i];
      buffer.writeln('''
${i + 1}. ${license.name} (${license.officialName})
   - Department: ${license.department}
   - Fee: ₹${license.fee}/${license.renewalCycle}
   - Mandatory: ${license.isMandatory ? 'Yes' : 'No'}
   - Apply at: ${license.applicationUrl}
   - Helpline: ${license.helpline}
   - Processing: ${license.processingTime}
   - Documents: ${license.requiredDocuments.join(', ')}
''');
    }
    return buffer.toString();
  }
}
