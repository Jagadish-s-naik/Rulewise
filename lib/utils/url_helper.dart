import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper function to open URLs with automatic https:// prefix
Future<bool> openUrl(String url) async {
  try {
    if (url.trim().isEmpty) {
      debugPrint('⚠️ openUrl: Empty URL provided');
      return false;
    }

    // Trim and clean the URL
    String formattedUrl = url.trim();
    
    // Add https:// if URL doesn't have a scheme
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }

    final uri = Uri.parse(formattedUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  } catch (e) {
    debugPrint('❌ openUrl Error: $e');
    return false;
  }
}
