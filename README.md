# RuleWise 🏛️

**Production-ready government compliance assistant for Indian businesses**

RuleWise is a comprehensive Flutter mobile application that helps Indian businesses manage government compliance requirements. It tracks licenses, sends renewal reminders, provides AI-powered compliance guidance, and integrates with official government APIs.

---

## 📱 Features

### Core Compliance Management
- **License Tracking** - Track 100+ government licenses across categories (GST, FSSAI, Shops & Establishment, Professional Tax, Import/Export, etc.)
- **Smart Renewal Automation** - Automatic renewal predictions and deadline tracking
- **Compliance Timeline** - Visual timeline of all compliance events and deadlines
- **Document Vault** - Secure storage for license documents with OCR scanning
- **Compliance Score** - Real-time compliance health metric with actionable insights

### AI Assistant
- **Context-Aware AI** - Powered by Groq LLM for lightning-fast responses
- **Personalized Guidance** - Answers based on user's business profile, location, and existing licenses
- **Document Analysis** - OCR-powered document extraction and validation
- **Offline Fallback** - Local intelligence engine for basic queries without API dependency

### Government Integration
- **API Setu Integration** - Real-time GST, PAN, and other tax validations
- **Razorpay IFSC Validation** - Bank account verification
- **Open Government India** - Access to public government data
- **Mutual Fund API** - For certain business compliance checks
- **Tax Data API** - Tax-related compliance information

### Subscription & Payments
- **Freemium Model** - Free tier with 5 AI queries/week
- **Premium Tiers** - Growth (₹499/month) and Protection (₹999/month)
- **Razorpay Integration** - Secure payment processing
- **Trial Period** - 7-day free trial for premium features

### Notifications & Alerts
- **Push Notifications** - Firebase Cloud Messaging for renewal reminders
- **Email Alerts** - SMTP-based email notifications
- **Local Notifications** - Scheduled compliance reminders
- **Emergency Mode** - Quick access to critical compliance information

### Business Growth Advisor
- **Expansion Analysis** - AI-powered business expansion recommendations
- **Gap Detection** - Identifies missing licenses for current business state
- **Roadmap Generation** - Step-by-step compliance roadmap for growth
- **Cost Estimation** - Calculates licensing costs for expansion

---

## 🛠️ Tech Stack

### Frontend
- **Flutter 3.2+** - Cross-platform mobile framework
- **Provider** - State management
- **Google Fonts** - Typography (Inter, Playfair Display)
- **Material Design 3** - Modern UI components

### Backend & Cloud
- **Firebase Core** - App initialization and configuration
- **Firebase Auth** - Phone & email authentication
- **Cloud Firestore** - Primary database for user data, licenses, compliance records
- **Firebase Storage** - Document storage
- **Firebase Messaging** - Push notifications
- **Cloud Functions** (optional) - Server-side business logic

### AI & Machine Learning
- **Groq API** - LLM inference (llama-3.3-70b-versatile model)
- **Google ML Kit** - On-device text recognition (OCR)

### APIs & Services
- **API Setu** - Government API gateway
- **Razorpay** - Payment processing
- **Open Government India** - Public datasets
- **Mutual Fund API** - Financial compliance data
- **Mailer** - Email sending

### Local Storage
- **Hive** - Offline data caching
- **Shared Preferences** - User settings
- **Path Provider** - File system access

### DevOps & Build
- **Workmanager** - Background task scheduling
- **Permission Handler** - Runtime permissions
- **URL Launcher** - External links and dialogs

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point & initialization
├── firebase_options.dart         # Firebase platform configuration
├── theme/
│   └── app_theme.dart           # Light/dark theme definitions
├── config/
│   └── api_config.dart          # API endpoints & keys (from .env)
├── models/                      # Data models
│   ├── license_model.dart
│   ├── user_license_model.dart
│   ├── subscription_plan.dart
│   ├── compliance_status.dart
│   ├── compliance_metrics.dart
│   ├── notification_model.dart
│   ├── extracted_data_model.dart
│   └── renewal_automation_model.dart
├── services/                    # Business logic & API calls
│   ├── auth_service.dart
│   ├── compliance_service.dart
│   ├── profile_service.dart
│   ├── user_license_service.dart
│   ├── subscription_service.dart
│   ├── payment_service.dart
│   ├── notification_service.dart
│   ├── ai_service.dart
│   ├── context_aware_ai_service.dart
│   ├── ocr_service.dart
│   ├── validation_service.dart
│   ├── api_setu_service.dart
│   ├── ifsc_validation_service.dart
│   ├── vat_validation_service.dart
│   ├── tax_data_service.dart
│   ├── mutual_fund_service.dart
│   ├── open_gov_india_service.dart
│   ├── law_change_radar_service.dart
│   ├── report_generation_service.dart
│   ├── smart_renewal_service.dart
│   ├── emergency_mode_service.dart
│   ├── fcm_service.dart
│   ├── background_service.dart
│   ├── firestore_seeding_service.dart
│   ├── master_data_seeding_service.dart
│   ├── emergency_data_seeder.dart
│   ├── base_api_service.dart
│   ├── api_cache_service.dart
│   ├── storage_service.dart
│   ├── email_service.dart
│   ├── fine_simulator_service.dart
│   ├── government_portal_service.dart
│   └── utils/
│       ├── api_error_handler.dart
│       ├── firestore_seeder.dart
│       ├── sample_data_helper.dart
│       └── url_helper.dart
├── screens/                     # UI screens
│   ├── splash_screen.dart
│   ├── main_screen.dart
│   ├── auth/
│   │   ├── login_choice_screen.dart
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   ├── phone_login_screen.dart
│   │   ├── email_login_screen.dart
│   │   ├── otp_verification_screen.dart
│   │   └── unified_login_screen.dart
│   ├── dashboard/
│   │   ├── dashboard_screen.dart
│   │   └── widgets/
│   │       ├── compliance_score_card.dart
│   │       ├── compliance_alerts_widget.dart
│   │       ├── license_status_card.dart
│   │       ├── quick_action_grid.dart
│   │       ├── financial_insights_widget.dart
│   │       ├── tax_calculator_widget.dart
│   │       ├── risk_monitor_widget.dart
│   │       ├── executive_summary_panel.dart
│   │       └── premium_risk_gauge.dart
│   ├── profile/
│   │   ├── profile_menu_screen.dart
│   │   ├── profile_setup_screen.dart
│   │   ├── profile_completion_wizard.dart
│   │   ├── aadhaar_validation_screen.dart
│   │   ├── pan_validation_screen.dart
│   │   ├── bank_verification_screen.dart
│   │   ├── gst_validation_screen.dart
│   │   └── pan_validation_screen.dart
│   ├── license/
│   │   ├── all_licenses_screen.dart
│   │   ├── license_details_screen.dart
│   │   ├── add_license_screen.dart
│   │   ├── edit_license_screen.dart
│   │   ├── license_application_wizard.dart
│   │   ├── document_upload_screen.dart
│   │   ├── document_preparation_guide.dart
│   │   └── document_vault_screen.dart
│   ├── subscription/
│   │   ├── subscription_upgrade_screen.dart
│   │   └── premium_promo_screen.dart
│   ├── renewal/
│   │   └── smart_renewal_screen.dart
│   ├── timeline/
│   │   ├── compliance_timeline_screen.dart
│   │   └── timeline_view_screen.dart
│   ├── reports/
│   │   └── monthly_reports_screen.dart
│   ├── ai/
│   │   └── ai_assistant_screen.dart
│   ├── notifications/
│   │   └── notifications_screen.dart
│   ├── settings/
│   │   ├── settings_screen.dart
│   │   ├── notification_settings_screen.dart
│   │   └── api_key_config_screen.dart
│   ├── growth/
│   │   └── growth_advisor_screen.dart
│   ├── law_updates/
│   │   ├── law_updates_screen.dart
│   │   └── law_change_radar_screen.dart
│   ├── emergency/
│   │   └── emergency_mode_screen.dart
│   ├── fine_simulator/
│   │   └── fine_simulator_screen.dart
│   ├── admin/
│   │   ├── data_seeding_screen.dart
│   │   ├── admin_seeding_screen.dart
│   │   └── test_data_seeder_screen.dart
│   ├── debug/
│   │   ├── firebase_diagnostic_screen.dart
│   │   └── quick_firebase_test.dart
│   ├── legal/
│   │   ├── terms_screen.dart
│   │   └── privacy_screen.dart
│   └── test/
│       └── test_data_seeder_screen.dart
├── widgets/                      # Reusable UI components
│   ├── alert_banner.dart
│   ├── metric_card.dart
│   ├── compliance_score_widget.dart
│   ├── premium_components.dart
│   └── legal_widgets.dart
├── utils/                        # Utility functions
│   ├── firestore_seeder.dart
│   ├── sample_data_helper.dart
│   └── url_helper.dart
├── scripts/                      # CLI scripts
│   ├── seed_database.dart
│   └── update_license_urls.dart
├── data/                         # Static data
│   ├── indian_compliance_data.dart
│   └── government_license_data.dart
└── seed_firestore.dart           # Firestore data seeding

assets/
├── .env                          # Environment variables (gitignored)
└── firebase.json                 # Firebase configuration
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** 3.2.0 or higher
- **Dart** SDK 3.2.0+
- **Android Studio** or **VS Code** with Flutter extension
- **Firebase Account** (free tier)
- **Groq API Key** (free, unlimited)
- **Git**

### Installation

#### 1. Clone the Repository

```bash
git clone https://github.com/Jagadish-s-naik/Rulewise.git
cd RuleWise
```

#### 2. Install Flutter Dependencies

```bash
flutter pub get
```

#### 3. Firebase Setup

##### Create a Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project" → Name it "RuleWise"
3. Enable Google Analytics (optional)
4. Click "Create Project"

##### Android Setup
1. In Firebase Console, add Android app
2. Package name: `com.example.rulewise`
3. Download `google-services.json`
4. Place it in `android/app/`
5. Run: `flutterfire configure` (or follow manual setup)

##### iOS Setup
1. In Firebase Console, add iOS app
2. Bundle ID: `com.example.rulewise`
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/`
5. Run: `flutterfire configure`

##### Web Setup (optional)
1. In Firebase Console, add Web app
2. Copy Firebase config
3. Update `lib/firebase_options.dart`

**Run Firebase configuration:**
```bash
flutterfire configure --project=rulewise-4ec59
```

#### 4. Environment Variables

Create a `.env` file in the project root:

```env
# Firebase
FIREBASE_API_KEY=your_firebase_web_api_key
FIREBASE_AUTH_DOMAIN=rulewise-4ec59.firebaseapp.com
FIREBASE_PROJECT_ID=rulewise-4ec59
FIREBASE_STORAGE_BUCKET=rulewise-4ec59.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id

# Groq AI
GROQ_API_KEY=gsk_your_actual_groq_key_here

# API Setu (optional)
API_SETU_KEY=your_api_setu_key
API_SETU_BASE_URL=https://apisetu.gov.in/api
ENABLE_API_SETU=true

# Open Government India (optional)
OPEN_GOV_INDIA_KEY=your_key
OPEN_GOV_INDIA_BASE_URL=https://api.data.gov.in
ENABLE_OPEN_GOV_INDIA=true

# Razorpay IFSC (optional)
RAZORPAY_IFSC_BASE_URL=https://ifsc.razorpay.com

# Mutual Fund API (optional)
MUTUAL_FUND_BASE_URL=https://api.mfapi.in
ENABLE_MUTUAL_FUND=true

# Tax Data API (optional)
TAX_DATA_API_KEY=your_key
TAX_DATA_BASE_URL=https://api.apilayer.com/tax_data
ENABLE_TAX_DATA=true

# VAT Validation (optional)
VAT_VALIDATION_API_KEY=your_key
VAT_VALIDATION_BASE_URL=https://vat.abstractapi.com/v1
ENABLE_VAT_VALIDATION=true

# Mailer (for emails)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_app_password

# Razorpay
RAZORPAY_KEY_ID=your_key_id
RAZORPAY_KEY_SECRET=your_key_secret
```

**Get Groq API Key:**
1. Visit https://console.groq.com/keys
2. Sign in with Google
3. Click "Create API Key"
4. Copy the key (starts with `gsk_...`)
5. Add to `.env` as `GROQ_API_KEY=gsk_your_key_here`

#### 5. Update Libraries

```bash
# For Android
cd android
./gradlew clean
cd ..

# For iOS
cd ios
pod install
cd ..
```

#### 6. Run the App

```bash
# Check connected devices
flutter devices

# Run on connected device/emulator
flutter run

# Or run in release mode
flutter run --release
```

---

## ⚙️ Configuration

### API Configuration

All API endpoints and keys are loaded from `.env` via `lib/config/api_config.dart`. Update this file to customize which APIs are enabled.

```dart
static bool get enableApiSetu => dotenv.env['ENABLE_API_SETU']?.toLowerCase() == 'true';
static bool get enableMutualFund => dotenv.env['ENABLE_MUTUAL_FUND']?.toLowerCase() == 'true';
```

### Subscription Plans

Configure premium tiers in `lib/services/subscription_service.dart`:

```dart
static const Map<Tier, PlanConfig> planConfigs = {
  Tier.growth: PlanConfig(
    price: 49900, // ₹499 in paise
    aiQueriesPerWeek: 50,
    features: [...]
  ),
  Tier.protection: PlanConfig(
    price: 99900, // ₹999 in paise
    aiQueriesPerWeek: 200,
    features: [...]
  ),
};
```

### License Categories

License data is stored in `lib/data/government_license_data.dart` and seeded to Firestore via `lib/seed_firestore.dart`. To add/modify licenses:

```bash
# Update data file
dart lib/data/government_license_data.dart

# Seed to Firestore (admin only)
flutter run lib/seed_firestore.dart
```

### Notification Settings

Configure FCM topics and notification channels in `lib/services/notification_service.dart` and `lib/services/fcm_service.dart`.

---

## 🎯 Key Screens

| Screen | Purpose |
|--------|---------|
| **Splash Screen** | App initialization & Firebase check |
| **Login/Register** | Phone/email authentication |
| **Dashboard** | Overview of compliance status, alerts, quick actions |
| **AI Assistant** | Chat-based compliance Q&A with context |
| **All Licenses** | Browse 107+ government licenses |
| **License Details** | Individual license info, fees, requirements |
| **Timeline** | Visual compliance calendar |
| **Renewals** | Smart renewal predictions & tracking |
| **Reports** | Monthly compliance reports (PDF) |
| **Profile** | User profile & business verification |
| **Subscription** | Premium upgrade & payment |
| **Settings** | App preferences & API key config |
| **Growth Advisor** | Business expansion compliance roadmap |
| **Law Updates** | Recent regulation changes |
| **Emergency Mode** | Quick access to critical info |
| **Document Vault** | Store & manage license documents |

---

## 🔧 Development

### Code Style

This project follows the official [Flutter style guide](https://flutter.dev/docs/development/tools/analysis). Run lint checks:

```bash
flutter analyze
```

Format code:
```bash
flutter format .
```

### State Management

Uses **Provider** pattern. Key providers in `main.dart`:

- `AuthService` - Authentication state
- `ComplianceService` - Compliance data & calculations
- `SubscriptionService` - Premium tier & payment state
- `ProfileService` - User profile & business details
- `NotificationService` - Push notification handling
- `UserLicenseService` - License management

### Error Handling

- Network errors: Handled by `ApiErrorHandler` in `lib/utils/api_error_handler.dart`
- API failures: Graceful fallbacks to cached data
- Offline mode: App works without internet using local Hive cache

### Testing

```bash
# Unit tests
flutter test

# Widget tests
flutter test --platform=chrome

# Integration tests
flutter test integration_test/
```

---

## 📊 Database Schema

### Firestore Collections

```
users/{userId}                    # User profile & settings
  ├── business_name
  ├── business_type
  ├── location (city, state)
  ├── subscription_tier (free/growth/protection)
  ├── is_premium
  ├── ai_queries_this_week
  ├── has_used_trial
  ├── trial_started_at
  ├── created_at
  └── updated_at

user_licenses/{licenseId}         # User's licenses
  ├── userId
  ├── licenseId (reference)
  ├── license_number
  ├── status (active/expired/pending)
  ├── issue_date
  ├── expiry_date
  ├── renewal_reminder_sent
  ├── document_url (Firebase Storage)
  └── metadata

compliance_records/{recordId}    # Compliance tracking
  ├── userId
  ├── date
  ├── compliance_score
  ├── active_count
  ├── expired_count
  ├── expiring_soon_count
  └── not_acquired_count

notifications/{notificationId}   # Notification history
  ├── userId
  ├── type (renewal/update/ai)
  ├── title
  ├── message
  ├── read
  ├── action_url
  └── created_at

renewal_predictions/{predictionId} # AI renewal predictions
  ├── userId
  ├── licenseId
  ├── predicted_renewal_date
  ├── confidence_score
  ├── estimated_fee
  └── created_at
```

### Local Storage (Hive)

```
rulewise_box
├── user_profile
├── business_type
├── selected_licenses
├── compliance_metrics
├── last_sync_timestamp
└── ai_queries_remaining
```

---

## 🔒 Security

### Secrets Management

- **NEVER** commit API keys or Firebase credentials to Git
- Use `.env` file (already in `.gitignore`)
- For production, use environment variables on the build server
- Firebase credentials are auto-generated by `flutterfire configure`

### Sensitive Files (Gitignored)
```
.env
*.json (firebase service accounts)
*.key
*.pem
firebase-adminsdk*.json
serviceAccountKey.json
```

### Data Privacy
- User data stored in Firestore with security rules
- Only authenticated users can access their data
- Document files stored in Firebase Storage with strict ACLs
- GDPR-compliant data handling (right to delete)

---

## 🚀 Deployment

### Android Release

```bash
# Update version in pubspec.yaml
version: 1.0.1

# Build APK
flutter build apk --release

# Or build App Bundle (for Play Store)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

**Before publishing:**
- Update `android/app/build.gradle` with your keystore
- Set `versionCode` and `versionName`
- Add Play Store listing screenshots
- Configure content rating

### iOS Release

```bash
# Update version in pubspec.yaml
version: 1.0.1

# Build IPA
flutter build ios --release

# Open Xcode for final signing & upload
open ios/Runner.xcworkspace
```

### Web Build (optional)

```bash
flutter build web --release
# Output: build/web/
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Firebase Not Initializing
```
Warning: Firebase initialization failed
```
**Solution:** Run `flutterfire configure` again. Ensure Firebase project exists.

#### 2. Groq API Key Not Working
**Check:**
- Key is added to `.env` 
- Key starts with `gsk_`
- No quotes around key in `.env`

#### 3. Android Build Fails
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

#### 4. iOS Pod Install Fails
```bash
cd ios
pod deintegrate
pod cache clean --all
pod install
cd ..
```

#### 5. Permission Errors
- Android: Check `android/app/src/main/AndroidManifest.xml`
- iOS: Check `ios/Runner/Info.plist`
- Request runtime permissions in code

---

## 🧪 Testing the AI Assistant

1. Add your Groq API key to `.env`
2. Run `flutter run`
3. Navigate to **AI Assistant** from main menu
4. Ask: *"How do I get a trade license for a restaurant in Bangalore?"*
5. Should get detailed, location-specific answer

**Expected behavior:**
- If API key is valid: Fast response (< 2 seconds)
- If key missing: Fallback to local intelligence (basic keyword matching)

---

## 📈 Performance

### Optimization Tips
- **ListViews**: Use `ListView.builder` for long lists (all license lists)
- **Images**: Use `cached_network_image` for remote images
- **State Updates**: Use `mounted` check after `await` calls
- **Database Queries**: Index Firestore fields: `userId`, `licenseId`, `expiry_date`
- **Pagination**: Load compliance records in batches of 50

### Monitoring
- **Firebase Crashlytics**: Track app crashes (optional)
- **Sentry**: Error monitoring (if integrated)
- **Analytics**: Google Analytics for Firebase (optional)

---

## 🤝 Contributing

We welcome contributions! Please read our contributing guidelines:

1. **Fork** the repository
2. **Create feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit changes**: `git commit -m 'Add amazing feature'`
4. **Push**: `git push origin feature/amazing-feature`
5. **Open Pull Request**

### Development Guidelines
- Follow Flutter's [effective Dart](https://dart.dev/guides/language/effective-dart) style
- Write tests for new features
- Update documentation
- Ensure `flutter analyze` passes
- Run `flutter format .` before committing

---

## 📄 License

This project is licensed under the **MIT License** - see below:

```
MIT License

Copyright (c) 2025 RuleWise

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 Acknowledgments

- **Groq** - For providing free, fast AI inference
- **Firebase** - Backend infrastructure
- **Flutter** - Amazing cross-platform framework
- **API Setu** - Government API gateway
- **Indian Government** - Open data initiatives
- **Contributors** - Who help make compliance easier for Indian businesses

---

## 📞 Support

- **Email**: support@rulewise.in
- **Website**: https://rulewise.in
- **GitHub Issues**: https://github.com/Jagadish-s-naik/Rulewise/issues
- **Telegram**: @RuleWiseSupport (optional)

---

## 🗺️ Roadmap

### v1.1 (Q2 2025)
- [ ] Multi-language support (Hindi, Tamil, Bengali)
- [ ] Advanced report generation (PDF export)
- [ ] Calendar integration (Google Calendar, Outlook)
- [ ] Bulk license import via CSV

### v1.2 (Q3 2025)
- [ ] Payroll compliance integration
- [ ] Tax filing deadline tracker
- [ ] Partner portal for CAs & consultants
- [ ] White-label for enterprise clients

### v1.3 (Q4 2025)
- [ ] Blockchain-based document verification
- [ ] AI-powered penalty prediction
- [ ] Smart contract auto-renewal
- [ ] Marketplace for compliance services

---

## 📸 Screenshots

*(To be added)*

| Splash Screen | Login | Dashboard |
|---------------|-------|-----------|
| *(screenshot)* | *(screenshot)* | *(screenshot)* |

| License List | AI Assistant | Timeline |
|--------------|--------------|----------|
| *(screenshot)* | *(screenshot)* | *(screenshot)* |

| Profile | Subscription | Settings |
|---------|-------------|----------|
| *(screenshot)* | *(screenshot)* | *(screenshot)* |

---

**Made with ❤️ in India for Indian businesses**

*RuleWise - Never miss a compliance deadline again*
