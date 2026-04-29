# Contributing to RuleWise

Thank you for your interest in contributing to RuleWise! This guide will help you get started.

---

## 📋 Table of Contents

1. [Code of Conduct](#-code-of-conduct)
2. [Getting Started](#-getting-started)
3. [Development Workflow](#-development-workflow)
4. [Coding Standards](#-coding-standards)
5. [Pull Request Process](#-pull-request-process)
6. [Adding New Features](#-adding-new-features)
7. [Bug Reports](#-bug-reports)
8. [Testing](#-testing)
9. [Documentation](#-documentation)
10. [Community](#-community)

---

## 📜 Code of Conduct

This project adheres to a **Contributor Code of Conduct**. By participating, you are expected to:

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive feedback
- Accept responsibility and apologize for mistakes

**Unacceptable behavior:** Harassment, discrimination, trolling, or personal attacks.

---

## 🚀 Getting Started

### Prerequisites

Before contributing, ensure you have:

- **Flutter SDK** 3.2.0+ ([install](https://flutter.dev/docs/get-started/install))
- **Dart** knowledge (syntax, async/await, null safety)
- **Git** proficiency (branches, commits, PRs)
- **Firebase** basics (Auth, Firestore, Storage)
- A **GitHub account**

### One-Time Setup

```bash
# 1. Fork the repository on GitHub

# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/Rulewise.git
cd RuleWise

# 3. Add upstream remote (original repo)
git remote add upstream https://github.com/Jagadish-s-naik/Rulewise.git

# 4. Install dependencies
flutter pub get

# 5. Setup Firebase (run once)
flutterfire configure --project=rulewise-4ec59

# 6. Copy environment template
cp .env.example .env
# Edit .env with your development keys (Groq, Firebase, etc.)

# 7. Run the app
flutter run
```

---

## 🔄 Development Workflow

### 1. Keep Your Fork Updated

```bash
# Fetch latest changes from upstream
git fetch upstream

# Merge into your local main
git checkout main
git merge upstream/main

# Push to your fork
git push origin main
```

### 2. Create a Feature Branch

```bash
# Create and switch to new branch
git checkout -b feature/your-feature-name

# Or for a bug fix
git checkout -b fix/issue-description
```

**Branch naming conventions:**
- `feature/add-growth-advisor` - New feature
- `fix/dashboard-crash-on-null` - Bug fix
- `refactor/ai-service-cleanup` - Code refactoring
- `docs/update-readme` - Documentation only
- `chore/update-dependencies` - Maintenance tasks

### 3. Make Changes

- Write clean, readable code
- Follow the project structure
- Add tests if applicable
- Update documentation

### 4. Commit Changes

```bash
# Stage files
git add lib/services/your_changed_file.dart

# Commit with descriptive message
git commit -m "feat: add AI context-aware response generation

- Implement context builder with user profile
- Add license data injection into prompt
- Include location-specific government portals
- Add fallback local intelligence engine"

# Or for bug fix
git commit -m "fix: resolve null pointer in dashboard widget

- Add null check for complianceMetrics
- Handle case when user has no licenses yet
- Add unit test for edge case"
```

**Conventional Commits format:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style (formatting, no logic change)
- `refactor:` Code restructuring
- `test:` Add or update tests
- `chore:` Maintenance tasks

### 5. Push and Create PR

```bash
# Push to your fork
git push origin feature/your-feature-name

# Then open GitHub and create Pull Request:
# 1. Go to original RuleWise repository
# 2. Click "Pull Requests" → "New Pull Request"
# 3. Choose your fork/branch as head
# 4. Fill PR template
# 5. Submit
```

---

## 🎯 Coding Standards

### Dart Style Guide

Follow [Effective Dart](https://dart.dev/guides/language/effective-dart):

```dart
// GOOD ✅
class UserService {
  Future<void> fetchUser(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }
    
    final user = await _api.getUser(userId);
    if (!mounted) return;
    setState(() => _user = user);
  }
}

// BAD ❌
class UserService{
  Future<void> fetchUser(String id)async{
    if(id.isEmpty)throw Exception('error');
    final u=await _api.getUser(id);_user=u;
  }
}
```

### Key Rules

1. **Naming Conventions**
   - Files: `snake_case.dart` (e.g., `ai_service.dart`)
   - Classes: `PascalCase` (e.g., `ComplianceService`)
   - Methods/variables: `camelCase` (e.g., `complianceScore`)
   - Constants: `SCREAMING_SNAKE_CASE` (e.g., `MAX_RETRIES`)
   - Private members: prefix with `_` (e.g., `_userId`)

2. **Files < 200 lines** - Keep files small and focused
3. **Methods < 30 lines** - Extract complex logic
4. **Class constructor** - Required parameters first, optional named last
5. **Use `const` constructors** - Whenever possible for performance

### Flutter Best Practices

```dart
// ✅ DO: Use mounted check after async operations
Future<void> loadData() async {
  setState(() => _loading = true);
  await _fetchData();
  if (!mounted) return;  // Prevents setState after dispose
  setState(() => _loading = false);
}

// ✅ DO: Dispose controllers in StatefulWidget
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}

// ✅ DO: Use const widgets for performance
const Text('Hello', style: TextStyle(fontSize: 16));

// ❌ DON'T: Use BuildContext across async gaps without mounted check
Future<void> risky() async {
  await someOperation();
  Navigator.of(context).pop(); // Might crash if widget disposed!
}

// ❌ DON'T: Use magic numbers
// BAD
setState(() => _count = 5);  // What does 5 mean?

// GOOD
static const int maxRetries = 5;
setState(() => _count = maxRetries);
```

### Provider Pattern

```dart
// 1. Extend ChangeNotifier
class AuthService extends ChangeNotifier {
  User? _user;
  
  User? get user => _user;
  
  Future<void> signIn() async {
    // business logic
    _user = result;
    notifyListeners();  // Notify listeners
  }
}

// 2. Provide at app level (main.dart)
ChangeNotifierProvider(
  create: (_) => AuthService(),
)

// 3. Consume in UI
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    return Text('Hello ${authService.user?.name}');
  }
}
```

### Error Handling

```dart
// ✅ DO: Try-catch with user-friendly messages
try {
  await _api.fetchData();
} on ApiException catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.friendlyMessage)),
    );
  }
} catch (e) {
  debugPrint('Unexpected error: $e');
}

// ✅ DO: Use custom exception classes
class InsufficientBalanceException implements Exception {
  final double currentBalance;
  final double requiredAmount;
  
  String get friendlyMessage =>
      'Insufficient balance. You need ₹${requiredAmount - currentBalance} more.';
}
```

---

## 🔍 Pull Request Process

### Before Submitting PR

1. **Run linting & formatting**
   ```bash
   flutter analyze
   flutter format .
   ```

2. **Test on real device/emulator**
   ```bash
   flutter run --release
   ```

3. **Check for breaking changes** - Will this break existing functionality?

4. **Update docs** - README, inline comments, any new API usage

5. **Self-review** - Check your own code for improvements

### PR Template

Fill out the PR template with:

**Description:** What does this PR do?
**Motivation:** Why is this change needed?
**Type:** Feature / Fix / Refactor / Documentation
**Screenshots:** (if UI changes)
**Testing:** Steps to test
**Checklist:**
- [ ] Code follows Dart style guide
- [ ] Self-reviewed code
- [ ] Added tests (if applicable)
- [ ] Updated documentation
- [ ] No breaking changes (or documented)
- [ ] `flutter analyze` passes

### Review Process

1. **Automated checks** run (lint, test if configured)
2. **Maintainer review** - At least one maintainer will review
3. **Address feedback** - Make requested changes
4. **Squash commits** - Before merging, PR may be squashed
5. **Merge** - Maintainer merges to `main`

**Typical review time:** 1-3 business days

---

## 🌟 Adding New Features

### Adding a New Screen

1. Create file: `lib/screens/feature/feature_screen.dart`
2. Update routes in `lib/main.dart` or navigation service
3. Add to export in `lib/screens/feature/index.dart` (optional)
4. Update `README.md` with new screen

### Adding a New Service

1. Create file: `lib/services/new_feature_service.dart`
2. Extend `ChangeNotifier` if state management needed
3. Register in `MultiProvider` in `main.dart`
4. Add unit tests in `test/services/`

### Adding a New License Type

1. Edit `lib/data/government_license_data.dart`
2. Add license object with all required fields
3. Run seeder: `flutter run lib/seed_firestore.dart`
4. Update documentation with new license category

### Integrating New External API

1. Add package to `pubspec.yaml`
2. Create service: `lib/services/new_api_service.dart`
3. Add to `.env.example` with documentation
4. Implement error handling with `ApiErrorHandler`
5. Add offline fallback if critical

---

## 🐛 Bug Reports

### Before Opening Issue

1. **Search existing issues** - Maybe already reported/fixed
2. **Check closed issues** - Solution might exist
3. **Update app** - Bug may be fixed in latest version

### Issue Template

When opening bug report, include:

```markdown
## Bug Description
Clear description of what's happening

## Steps to Reproduce
1. Go to '...'
2. Tap on '....'
3. See error

## Expected Behavior
What should happen instead

## Screenshots/Video
If applicable, attach screenshots

## Device Info
- Device: [e.g., Pixel 6 Pro]
- OS: [e.g., Android 14]
- App Version: [e.g., 1.0.0]

## Console Logs
```
Paste relevant error logs here
```

## Additional Context
Anything else that might help
```

---

## ✅ Testing

### Running Tests

```bash
# All tests
flutter test

# Specific file
flutter test test/services/auth_service_test.dart

# With coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Writing Tests

```dart
// test/services/compliance_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rulewise/services/compliance_service.dart';

void main() {
  group('ComplianceService', () {
    late ComplianceService service;
    
    setUp(() {
      service = ComplianceService();
    });
    
    test('should calculate compliance score correctly', () {
      // Arrange
      final licenses = [
        LicenseModel(status: 'active'),
        LicenseModel(status: 'expired'),
      ];
      
      // Act
      final score = service.calculateScore(licenses);
      
      // Assert
      expect(score, equals(50.0));  // 1 active out of 2 = 50%
    });
    
    test('should return zero when no licenses', () {
      final score = service.calculateScore([]);
      expect(score, equals(0.0));
    });
  });
}
```

**Testing guidelines:**
- Unit tests for services, utilities, models
- Widget tests for complex UI components
- Integration tests for critical user flows (login → dashboard → license)
- Mock external APIs using `mockito` or `mocktail`

---

## 📖 Documentation

### Code Documentation

Add documentation comments for:

```dart
/// A service that manages user authentication and authorization.
/// 
/// This service handles:
/// - Phone and email sign-in
/// - Session management
/// - Token refresh
/// - Multi-factor authentication
class AuthService extends ChangeNotifier {
  /// Current authenticated user, null if not logged in
  User? get currentUser => _user;
  
  /// Signs in a user with phone number
  /// 
  /// [phoneNumber] must be in E.164 format (+91XXXXXXXXXX)
  /// Returns a [UserId] that must be verified with [verifyOTP]
  Future<String> signInWithPhone(String phoneNumber) async {
    // implementation
  }
}
```

**Use dart doc:**
```bash
dart doc .
open doc/api/index.html
```

### README Updates

When adding features:
- Update feature list
- Add new screenshots
- Update installation/setup steps
- Document new environment variables

---

## 🔧 Development Tips

### Hot Reload vs Hot Restart

- **Hot Reload** (r) - Most changes, fast
- **Hot Restart** (R) - Full restart, needed for main.dart changes
- **Full restart** (q then r) - Clean rebuild

### Debugging

```dart
// Add debug logs
debugPrint('User ID: $userId');
debugPrintStack(label: 'Custom stack trace');

// Use DevTools
flutter pub global activate devtools
flutter pub global run devtools

// Check widget rebuilds
MaterialApp(
  debugShowCheckedModeBanner: false,
  debugShowMaterialGrid: false,
);
```

### Performance Profiling

```bash
# Performance overlay
flutter run --profile

# DevTools performance tab
flutter pub global run devtools

# Memory profiling
flutter run --profile -d chrome --dart-define=FLUTTER_WEB_USE_SKIA=true
```

---

## 🤝 Finding Issues to Work On

- **Good first issue** label - Beginner-friendly tasks
- **Help wanted** label - Community contributions welcome
- Look for `TODO:` comments in code
- Check issues with no assignee

**Before starting work:**
1. Comment on issue: "I'd like to work on this"
2. Wait for maintainer assignment
3. Create branch referencing issue number: `feature/issue-42`

---

## 🏆 Recognition

Contributors will be:
- Listed in `CONTRIBUTORS.md`
- Mentioned in release notes
- Invited to private contributor group
- Eligible for **RuleWise Partner** benefits (premium access, swag)

---

## ❓ Questions?

- **Discord**: [Join our server](https://discord.gg/rulewise) (optional)
- **Email**: dev@rulewise.in
- **GitHub Discussions**: Ask general questions

---

**Happy coding! 🚀**

*Every contribution makes government compliance easier for Indian businesses.*

<!--
## Quick Contribution Checklist

- [ ] Forked and created feature branch
- [ ] Followed Dart style guide
- [ ] Added tests (if applicable)
- [ ] Updated documentation
- [ ] Ran `flutter analyze` - no errors
- [ ] Tested on real device
- [ ] Filled PR template completely
-->
