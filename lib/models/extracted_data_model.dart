class ExtractedDataModel {
  final String? licenseNumber;
  final DateTime? expiryDate;
  final DateTime? issueDate;
  final double confidence;
  final String rawText;

  ExtractedDataModel({
    this.licenseNumber,
    this.expiryDate,
    this.issueDate,
    required this.confidence,
    required this.rawText,
  });

  bool get hasHighConfidence => confidence > 0.8;
  bool get hasData => licenseNumber != null || expiryDate != null;

  @override
  String toString() {
    return 'ExtractedDataModel(number: $licenseNumber, expiry: $expiryDate)';
  }
}
