import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/license_model.dart';
import '../models/compliance_status.dart';
import '../models/compliance_metrics.dart';
import '../models/user_license_model.dart';
import '../models/risk_profile.dart';

class ComplianceService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<LicenseModel> _applicableLicenses = [];
  List<ComplianceStatus> _complianceStatuses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<LicenseModel> get applicableLicenses => _applicableLicenses;
  List<ComplianceStatus> get complianceStatuses => _complianceStatuses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch applicable licenses based on user profile
  Future<void> fetchApplicableLicenses({
    required String state,
    required String city,
    required String businessType,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Query Firestore for applicable licenses
      final querySnapshot = await _firestore
          .collection('compliance_data')
          .doc(state)
          .collection('cities')
          .doc(city)
          .collection('business_types')
          .doc(businessType)
          .collection('licenses')
          .get();

      _applicableLicenses = querySnapshot.docs
          .map((doc) => LicenseModel.fromFirestore(doc.id, doc.data()))
          .toList();

      // Fallback if no data found (Development/Demo mode)
      if (_applicableLicenses.isEmpty) {
        _applicableLicenses = [
          LicenseModel(
            id: 'gst_reg',
            name: 'GST Registration',
            officialName: 'Goods and Services Tax Registration',
            department: 'Tax Department',
            description:
                'Mandatory tax registration for businesses with turnover > 20L.',
            isMandatory: true,
            renewalCycle: 'N/A (Life-time)',
            fee: 0,
            penaltyPerMonth: 10000,
            gracePeriodDays: 0,
            applicationUrl: 'https://reg.gst.gov.in',
            helpline: '1800-123-456',
            requiredDocuments: [
              'PAN Card',
              'Aadhar Card',
              'Rent Agreement',
              'Bank Details'
            ],
            processingTime: '7 working days',
          ),
          LicenseModel(
            id: 'fssai_basic',
            name: 'FSSAI Basic',
            officialName: 'FSSAI Basic Registration',
            department: 'Food Safety Authority',
            description:
                'Required for all food business operators with turnover < 12L.',
            isMandatory: true,
            renewalCycle: '1-5 Years',
            fee: 100,
            penaltyPerMonth: 100,
            gracePeriodDays: 30,
            applicationUrl: 'https://foscos.fssai.gov.in',
            helpline: '1800-112-100',
            requiredDocuments: ['Photo', 'ID Proof', 'Proof of Premises'],
            processingTime: '7 working days',
          ),
          LicenseModel(
            id: 'trade_license',
            name: 'Trade License',
            officialName: 'Municipal Trade License',
            department: 'Municipal Corporation',
            description: 'Permission to carry out specific trade or business.',
            isMandatory: true,
            renewalCycle: 'Yearly',
            fee: 5000,
            penaltyPerMonth: 500,
            gracePeriodDays: 30,
            applicationUrl: 'https://muni.gov.in',
            helpline: '080-2222-3333',
            requiredDocuments: [
              'Property Tax Receipt',
              'ID Proof',
              'Lease Deed'
            ],
            processingTime: '30 days',
          ),
          LicenseModel(
            id: 'shop_act',
            name: 'Shop Act',
            officialName: 'Shop & Establishment Act Registration',
            department: 'Labour Department',
            description:
                'Registration for shops, hotels, and commercial establishments.',
            isMandatory: true,
            renewalCycle: 'Yearly',
            fee: 2500,
            penaltyPerMonth: 1000,
            gracePeriodDays: 15,
            applicationUrl: 'https://labour.gov.in',
            helpline: '155214',
            requiredDocuments: [
              'Aadhar',
              'Photo',
              'Shop Photo',
              'Employee Details'
            ],
            processingTime: '15 days',
          ),
          LicenseModel(
            id: 'pro_tax',
            name: 'Professional Tax',
            officialName: 'Professional Tax Registration (PTR)',
            department: 'State Government',
            description:
                'State tax on professions, trades, callings and employments.',
            isMandatory: true,
            renewalCycle: 'Yearly',
            fee: 2500,
            penaltyPerMonth: 200,
            gracePeriodDays: 30,
            applicationUrl: 'https://ptax.gov.in',
            helpline: '1800-TAX-HELP',
            requiredDocuments: ['Incorporation Cert', 'PAN', 'Bank Statement'],
            processingTime: '1 day',
          ),
        ];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to fetch licenses: $e';
      notifyListeners();
    }
  }

  // Get compliance status for all applicable licenses
  Future<void> getComplianceStatus() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Fetch user's licenses
      final userLicensesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('user_licenses')
          .get();

      final userLicensesMap = {
        for (var doc in userLicensesSnapshot.docs)
          doc.data()['license_id'] as String: doc.data()
      };

      // Create compliance status for each applicable license
      _complianceStatuses = _applicableLicenses.map((license) {
        final userLicenseData = userLicensesMap[license.id];
        return ComplianceStatus(
          license: license,
          userLicenseData: userLicenseData,
        );
      }).toList();

      _calculateMetrics(); // Update metrics for the dashboard

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to get compliance status: $e';
      notifyListeners();
    }
  }

  ComplianceMetrics? _metrics;
  ComplianceMetrics? get metrics => _metrics;

  // Calculate high-level compliance metrics
  void _calculateMetrics() {
    if (_complianceStatuses.isEmpty) {
      _metrics = ComplianceMetrics(
        totalRequired: 0,
        active: 0,
        expired: 0,
        expiringSoon: 0,
        notAcquired: 0,
      );
      return;
    }

    int total = _complianceStatuses.length;
    int active = 0;
    int expired = 0;
    int expiringSoon = 0;
    int notAcquired = 0;

    for (var status in _complianceStatuses) {
      if (status.isExpired) {
        expired++;
      } else if (status.isExpiringSoon) {
        expiringSoon++;
        // Count as active if only expiring soon, but track separately
        active++;
      } else if (status.userStatus == 'active') {
        active++;
      } else {
        notAcquired++;
      }
    }

    // Calculate user licenses list for risk profile
    final userLicenses = _complianceStatuses
        .where((s) => s.userLicenseData != null)
        .map((s) => UserLicenseModel.fromMap(
              s.license.id, // Use license ID as temporary ID
              s.userLicenseData!,
            ))
        .toList();

    // Calculate weighted risk score
    final riskProfile = calculateRiskProfile(userLicenses);

    _metrics = ComplianceMetrics(
      totalRequired: total,
      active: active,
      expired: expired,
      expiringSoon: expiringSoon,
      notAcquired: notAcquired,
      overrideScore: riskProfile.overallScore,
    );
  }

  RiskProfile calculateRiskProfile(List<UserLicenseModel> userLicenses) {
    if (_applicableLicenses.isEmpty) {
      return RiskProfile.initial();
    }

    double currentScore = 100.0;
    List<RiskFactor> factors = [];
    final userLicenseMap = {for (var ul in userLicenses) ul.licenseId: ul};

    for (var license in _applicableLicenses) {
      final userLicense = userLicenseMap[license.id];

      // CRITICAL: Missing Mandatory License
      if (userLicense == null) {
        if (license.isMandatory) {
          currentScore -= 25.0; // Heavy penalty for missing mandatory
          factors.add(RiskFactor(
            description: 'Missing mandatory: ${license.name}',
            impact: -25.0,
            isCritical: true,
          ));
        } else {
          currentScore -= 10.0;
          factors.add(RiskFactor(
            description: 'Missing recommended: ${license.name}',
            impact: -10.0,
          ));
        }
      } else {
        // License exists, check status
        if (userLicense.isExpired) {
          currentScore -= 20.0;
          factors.add(RiskFactor(
            description: 'Expired: ${license.name}',
            impact: -20.0,
            isCritical: true,
          ));
        } else if (userLicense.isExpiringSoon) {
          currentScore -= 5.0;
          factors.add(RiskFactor(
            description: 'Expiring soon: ${license.name}',
            impact: -5.0,
          ));
        }
      }
    }

    // Clamp score
    currentScore = currentScore.clamp(0.0, 100.0);

    // Determine level
    RiskLevel level;
    if (currentScore >= 70) {
      level = RiskLevel.safe;
    } else if (currentScore >= 30) {
      level = RiskLevel.warning;
    } else {
      level = RiskLevel.highRisk;
    }

    return RiskProfile(
      overallScore: currentScore,
      level: level,
      riskFactors: factors,
      lastCalculated: DateTime.now(),
    );
  }

  // Legacy support for older widgets until strict deprecation
  ComplianceMetrics calculateComplianceMetrics(
      List<UserLicenseModel> userLicenses) {
    // Legacy support: We might want to use riskProfile later for stricter metrics
    // final riskProfile = calculateRiskProfile(userLicenses);

    int active = 0;
    int expired = 0;
    int expiringSoon = 0;
    int notAcquired = 0;

    final userLicenseMap = {for (var ul in userLicenses) ul.licenseId: ul};

    for (var license in _applicableLicenses) {
      final userLicense = userLicenseMap[license.id];
      if (userLicense == null) {
        notAcquired++;
      } else if (userLicense.isExpired) {
        expired++;
      } else if (userLicense.isExpiringSoon) {
        expiringSoon++;
      } else {
        active++;
      }
    }

    return ComplianceMetrics(
      totalRequired: _applicableLicenses.length,
      active: active,
      expired: expired,
      expiringSoon: expiringSoon,
      notAcquired: notAcquired,
    );
  }

  // Add user license
  Future<void> addUserLicense({
    required String licenseId,
    required String licenseNumber,
    required DateTime issueDate,
    required DateTime expiryDate,
    String? documentUrl,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('user_licenses')
          .add({
        'license_id': licenseId,
        'license_number': licenseNumber,
        'issue_date': Timestamp.fromDate(issueDate),
        'expiry_date': Timestamp.fromDate(expiryDate),
        'status': 'active',
        'document_url': documentUrl,
        'created_at': FieldValue.serverTimestamp(),
      });

      // Refresh compliance status
      await getComplianceStatus();
    } catch (e) {
      _errorMessage = 'Failed to add license: $e';
      notifyListeners();
    }
  }
}
