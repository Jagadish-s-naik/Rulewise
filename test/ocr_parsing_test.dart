import 'package:flutter_test/flutter_test.dart';
import 'package:rulewise/services/ocr_service.dart';
import 'package:rulewise/models/extracted_data_model.dart';

void main() {
  late OCRService ocrService;

  setUp(() {
    ocrService = OCRService();
  });

  group('OCR Parsing Tests', () {
    test('Should extract FSSAI license number correctly', () {
      const rawText = '''
        FSSAI LICENSE
        Lic No: 12345678901234
        Date of Issue: 01/01/2023
        Valid Until: 31/12/2025
      ''';

      final result = ocrService.parseText(rawText);

      expect(result.licenseNumber, '12345678901234');
      expect(result.issueDate, isNotNull);
      expect(result.expiryDate, isNotNull);
      expect(result.expiryDate?.year, 2025);
    });

    test('Should extract GST number correctly', () {
      const rawText = '''
        GST REGISTRATION
        GSTIN: 27AAAAA0000A1Z5
        Registration Date: 15-05-2022
      ''';

      final result = ocrService.parseText(rawText);

      expect(result.licenseNumber, '27AAAAA0000A1Z5');
      expect(result.issueDate, isNotNull);
      expect(result.issueDate?.day, 15);
    });

    test('Should handle mixed formats and garbage text', () {
      const rawText = '''
        SOME RANDOM TEXT
        EXPIRY: 10/10/2030
        Random words 12345
        REG NO: 98765432101234
      ''';

      final result = ocrService.parseText(rawText);

      expect(result.licenseNumber, '98765432101234');
      expect(result.expiryDate?.year, 2030);
    });

    test('Should handle multiple dates and pick correctly', () {
      const rawText = '''
        FSSAI
        ISSUE: 01/01/2020
        EXPIRY: 01/01/2025
      ''';

      final result = ocrService.parseText(rawText);

      expect(result.issueDate?.year, 2020);
      expect(result.expiryDate?.year, 2025);
    });
  });
}
