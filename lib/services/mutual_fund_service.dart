import '../config/api_config.dart';
import 'base_api_service.dart';

/// Model for mutual fund data
class MutualFundData {
  final String schemeName;
  final String schemeCode;
  final double nav;
  final DateTime date;
  final String fundHouse;

  MutualFundData({
    required this.schemeName,
    required this.schemeCode,
    required this.nav,
    required this.date,
    required this.fundHouse,
  });

  factory MutualFundData.fromJson(Map<String, dynamic> json) {
    return MutualFundData(
      schemeName: json['scheme_name'] ?? '',
      schemeCode: json['scheme_code'] ?? '',
      nav: (json['nav'] ?? 0).toDouble(),
      date: DateTime.parse(json['date']),
      fundHouse: json['fund_house'] ?? '',
    );
  }
}

/// Service for Indian Mutual Fund API
class MutualFundService extends BaseApiService {
  MutualFundService()
      : super(
          baseUrl: ApiConfig.mutualFundBaseUrl,
        );

  /// Get mutual fund NAV by scheme code
  Future<MutualFundData?> getMutualFundNAV(String schemeCode) async {
    if (!ApiConfig.enableMutualFund) {
      return null;
    }

    try {
      final response = await get(
        '/mf/$schemeCode',
        useCache: true,
        cacheDuration: const Duration(hours: 24),
      );

      if (response['data'] != null && response['data'].isNotEmpty) {
        return MutualFundData.fromJson(response['data'][0]);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get all mutual funds (for search/recommendations)
  Future<List<MutualFundData>> getAllMutualFunds() async {
    if (!ApiConfig.enableMutualFund) {
      return [];
    }

    try {
      final response = await get(
        '/mf',
        useCache: true,
        cacheDuration: const Duration(days: 7),
      );

      final List<dynamic> funds = response['data'] ?? [];
      return funds.map((json) => MutualFundData.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get recommended funds for compliance savings
  /// This is a simple implementation - can be enhanced with ML/AI
  Future<List<MutualFundData>> getRecommendedFunds({
    double investmentAmount = 10000,
    String riskProfile = 'moderate', // low, moderate, high
  }) async {
    if (!ApiConfig.enableMutualFund) {
      return [];
    }

    try {
      // For now, return top performing debt funds (suitable for compliance savings)
      // In production, this would use a more sophisticated recommendation engine
      final allFunds = await getAllMutualFunds();

      // Filter debt funds (safer for compliance savings)
      final debtFunds = allFunds.where((fund) {
        final name = fund.schemeName.toLowerCase();
        return name.contains('debt') ||
            name.contains('liquid') ||
            name.contains('gilt');
      }).toList();

      // Sort by NAV (simple metric, can be improved)
      debtFunds.sort((a, b) => b.nav.compareTo(a.nav));

      // Return top 5
      return debtFunds.take(5).toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if API is available
  static bool get isAvailable => ApiConfig.enableMutualFund;
}
