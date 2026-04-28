import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart';

/// Email service for sending OTP emails via Gmail SMTP
///
/// SETUP INSTRUCTIONS:
/// 1. Go to Google Account settings
/// 2. Enable 2-Step Verification
/// 3. Generate an App Password: https://myaccount.google.com/apppasswords
/// 4. Use that app password (not your regular Gmail password)
class EmailService {
  // Gmail SMTP Configuration
  // Email: jagadishnaikgerusoppa@gmail.com
  // App Password generated: 2026-01-23
  static const String _gmailUsername = 'jagadishnaikgerusoppa@gmail.com';
  static const String _gmailAppPassword =
      'tvrbaycsarabpgui'; // Spaces removed from: tvrb aycs arab pgui

  /// Send OTP email to user
  Future<bool> sendOTPEmail({
    required String recipientEmail,
    required String otp,
  }) async {
    try {
      debugPrint('📧 Sending OTP email to: $recipientEmail');

      // Configure Gmail SMTP server
      final smtpServer = gmail(_gmailUsername, _gmailAppPassword);

      // Create email message
      final message = Message()
        ..from = const Address(_gmailUsername, 'RuleWise')
        ..recipients.add(recipientEmail)
        ..subject = 'Your RuleWise Login OTP - $otp'
        ..html = _buildOTPEmailHTML(otp);

      // Send email
      final sendReport = await send(message, smtpServer);
      debugPrint('✅ Email sent successfully: ${sendReport.toString()}');

      return true;
    } catch (e) {
      debugPrint('❌ Error sending email: $e');
      return false;
    }
  }

  /// Build HTML email template for OTP
  String _buildOTPEmailHTML(String otp) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body {
      font-family: Arial, sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 600px;
      margin: 0 auto;
      padding: 20px;
    }
    .container {
      background-color: #f9f9f9;
      border-radius: 10px;
      padding: 30px;
      border: 1px solid #e0e0e0;
    }
    .header {
      text-align: center;
      margin-bottom: 30px;
    }
    .logo {
      font-size: 28px;
      font-weight: bold;
      color: #2196F3;
    }
    .otp-box {
      background-color: #2196F3;
      color: white;
      font-size: 32px;
      font-weight: bold;
      text-align: center;
      padding: 20px;
      border-radius: 8px;
      letter-spacing: 8px;
      margin: 20px 0;
    }
    .info {
      background-color: #fff3cd;
      border-left: 4px solid #ffc107;
      padding: 15px;
      margin: 20px 0;
    }
    .footer {
      text-align: center;
      margin-top: 30px;
      font-size: 12px;
      color: #666;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">🛡️ RuleWise</div>
      <p>Your Government Compliance Assistant</p>
    </div>
    
    <h2>Login Verification Code</h2>
    <p>Hello,</p>
    <p>You requested to log in to your RuleWise account. Use the following One-Time Password (OTP) to complete your login:</p>
    
    <div class="otp-box">$otp</div>
    
    <div class="info">
      <strong>⏱️ Valid for 10 minutes</strong><br>
      This OTP will expire in 10 minutes for security reasons.
    </div>
    
    <p><strong>Security Tips:</strong></p>
    <ul>
      <li>Never share this OTP with anyone</li>
      <li>RuleWise will never ask for your OTP via phone or email</li>
      <li>If you didn't request this OTP, please ignore this email</li>
    </ul>
    
    <div class="footer">
      <p>This is an automated email. Please do not reply.</p>
      <p>&copy; 2024 RuleWise - Government Compliance Made Simple</p>
    </div>
  </div>
</body>
</html>
''';
  }
}
