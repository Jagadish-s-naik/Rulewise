# Changelog

All notable changes to the RuleWise project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2025-04-29

### 🎉 Initial Release

**Welcome to RuleWise v1.0 - The production-ready government compliance assistant!**

#### ✨ Added
- **Core Compliance Management**
  - License tracking for 100+ Indian government licenses
  - Smart renewal predictions with deadline tracking
  - Compliance score dashboard with health metrics
  - Document vault with OCR scanning
  - Compliance timeline visualization

- **AI Assistant**
  - Context-aware AI powered by Groq LLM
  - Business profile-aware responses
  - 107+ licenses in context window
  - Local fallback intelligence (offline mode)
  - Ask questions in natural language

- **Government API Integration**
  - API Setu integration (GST, PAN validation)
  - Razorpay IFSC validation
  - Open Government India data access
  - Mutual Fund API for compliance checks
  - Tax Data API integration
  - VAT validation service

- **Authentication & Profile**
  - Phone number + OTP authentication
  - Email/password login option
  - Profile completion wizard
  - Aadhaar validation
  - PAN validation
  - Bank account verification (IFSC)
  - GST validation

- **Subscription & Payments**
  - Freemium model (5 AI queries/week free)
  - Growth plan: ₹499/month (50 AI queries)
  - Protection plan: ₹999/month (200 AI queries)
  - 7-day free trial
  - Razorpay payment integration
  - Subscription management

- **Notifications**
  - Firebase Cloud Messaging (FCM)
  - Local notifications for reminders
  - Email alerts via SMTP
  - Renewal reminders (7 days before expiry)
  - Emergency mode alerts

- **Advanced Features**
  - Business Growth Advisor AI
  - Expansion compliance roadmap
  - Gap analysis for missing licenses
  - Fine simulator for penalty estimation
  - Law updates radar
  - Monthly compliance reports (PDF)
  - Smart renewal automation
  - License application wizard
  - Document preparation guide

- **Developer Features**
  - Firebase diagnostic screen
  - API key configuration UI
  - Debug tools
  - Admin data seeding
  - Firebase Firestore integration
  - Background services
  - Offline-first architecture

- **UI/UX**
  - Material Design 3
  - Light & dark theme support
  - Responsive layout for phones & tablets
  - Smooth animations
  - Accessibility support
  - Premium UI components

#### 🔧 Configuration
- Environment variable support via `.env`
- Firebase configuration wizard
- Groq AI API key integration
- Multi-API key management
- Debug mode toggle

#### 📁 Project Structure
- Model-View-ViewModel (MVVM) inspired architecture
- Provider state management
- Service layer abstraction
- Repository pattern for data sources
- Separate configuration files
- Modular screen organization

#### 🔒 Security
- Firebase authentication
- Firestore security rules
- API key protection (.gitignore)
- Sensitive data exclusion
- Secure payment processing

#### 🚀 DevOps
- Git workflow with feature branches
- Commit message conventions
- Linting rules (Dart analyzer)
- Code formatting
- GitHub repository setup
- CI/CD ready structure

#### 📚 Documentation
- Comprehensive README
- Environment configuration template
- Contributing guidelines
- Code comments
- Setup instructions for all platforms

---

## [Unreleased]

### 🔜 Planned for v1.1 (Q2 2025)

#### ✨ New Features
- [ ] Multi-language support (Hindi, Tamil, Bengali, Telugu, Marathi)
- [ ] Advanced PDF report generation with branding
- [ ] Google Calendar / Outlook integration
- [ ] Bulk license import via CSV
- [ ] Voice input for AI assistant
- [ ] QR code scanner for GSTIN
- [ ] Advanced analytics dashboard
- [ ] CA/Consultant portal
- [ ] Team collaboration features
- [ ] WhatsApp notifications

#### 🛠️ Improvements
- [ ] Firebase Remote Config for dynamic updates
- [ ] A/B testing framework
- [ ] In-app feedback system
- [ ] Offline AI model (TFLite)
- [ ] Biometric authentication
- [ ] App shortcuts (Android)
- [ ] Widget support
- [ ] Siri shortcuts (iOS)

#### 🔧 Technical
- [ ] Migration to Riverpod (state management)
- [ ] GraphQL integration
- [ ] Real-time compliance monitoring
- [ ] Web dashboard for admins
- [ ] PWA support
- [ ] Microservices backend (optional)

---

## [1.0.0-rc.1] - 2025-04-15

### 🎯 Release Candidate 1

#### Added
- Basic license tracking
- Simple AI assistant (Groq)
- User authentication
- Dashboard with compliance score
- Basic profile management
- Firestore backend
- Initial notification system

#### Known Issues
- Limited license data (only 50 licenses)
- No subscription system
- No payment integration
- Missing many validation screens
- No offline mode

---

## [0.9.0] - 2025-03-01

### 🎨 Beta Release

#### Added
- UI/UX design complete
- Material Design 3 implementation
- Theme system
- Navigation prototype
- License listing screen
- Login/signup screens
- Settings screen

#### Fixed
- Design inconsistencies
- Color scheme issues
- Font spacing problems

---

## [0.1.0] - 2025-01-15

### 🏗️ Alpha Release

#### Added
- Project initialization
- Flutter project setup
- Firebase integration
- Basic architecture
- Data models defined
- Service layer skeleton

---

## Versioning Scheme

**RuleWise follows Semantic Versioning (SemVer):**

```
MAJOR.MINOR.PATCH   (1.0.0)
↑     ↑     ↑
↑     ↑     └─ PATCH: Bug fixes, minor changes (backward compatible)
↑     └─ MINOR: New features (backward compatible)
└─ MAJOR: Breaking changes
```

### Pre-release versions
- `1.0.0-alpha.1` - Early testing, unstable
- `1.0.0-beta.1` - Feature complete, testing phase
- `1.0.0-rc.1` - Release candidate, nearly stable
- `1.0.0` - General Availability (stable)

---

## 📊 Release Statistics

| Version | Date | Highlights | Downloads |
|---------|------|------------|-----------|
| 1.0.0   | 2025-04-29 | Production launch, AI, APIs | TBD |
| 0.9.0   | 2025-03-01 | Beta release, UI complete | 150 |
| 0.1.0   | 2025-01-15 | Alpha, basic structure | 50 |

---

## 🔄 Upgrade Guide

### From 0.9.x to 1.0.0

**Breaking Changes:**
1. `.env` file structure changed - update your config
2. Firebase rules updated - redeploy
3. API Setu integration added - register for API key

**Migration Steps:**
```bash
# Backup your data
flutter run lib/export_user_data.dart

# Update code
git pull origin main

# Update dependencies
flutter pub upgrade

# Update .env from template
cp .env.example .env
# Edit with your actual keys

# Migrate Firestore data (if needed)
flutter run lib/scripts/migrate_v1_to_v2.dart

# Run
flutter run
```

---

## 🙏 Credits

Each version includes contributions from amazing developers. See [CONTRIBUTING.md](CONTRIBUTING.md) for how to join.

---

**Note**: For security reasons, we do not disclose detailed security fixes in this changelog. Security patches are backported tostable releases.
