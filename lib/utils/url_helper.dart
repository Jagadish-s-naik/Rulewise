import 'package:url_launcher/url_launcher.dart';

/// Helper function to open URLs with automatic https:// prefix
Future<bool> openUrl(String url) async {
  try {
    // Add https:// if URL doesn't have a scheme
    String formattedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      formattedUrl = 'https://$url';
    }

    final uri = Uri.parse(formattedUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
}
