import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/extracted_data_model.dart';


class OCRService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<ExtractedDataModel> scanImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      String rawText = recognizedText.text;
      debugPrint("OCR Raw Text: $rawText");

      return parseText(rawText);

    } catch (e) {
      debugPrint("OCR Error: $e");
      return ExtractedDataModel(confidence: 0, rawText: '');
    }
  }

  @visibleForTesting
  ExtractedDataModel parseText(String text) {

    String? licenseNumber;
    DateTime? expiryDate;
    DateTime? issueDate;
    double confidence = 0.5; // Base confidence

    final lines = text.split('\n');

    // Regex Patterns
    // 1. Dates (dd/mm/yyyy, dd-mm-yyyy, yyyy-mm-dd)
    final datePattern = RegExp(
        r'\b(?:(?:0[1-9]|[12][0-9]|3[01])[-/.](?:0[1-9]|1[012])[-/.](?:19|20)\d\d)\b');

    // 2. FSSAI License Pattern (14 digits)
    final fssaiPattern = RegExp(r'\b1\d{13}\b');

    // 3. GST Pattern (15 chars)
    final gstPattern =
        RegExp(r'\b\d{2}[A-Z]{5}\d{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}\b');

    for (var line in lines) {
      String cleanLine = line.trim().toUpperCase();

      // Find License Number
      if (licenseNumber == null) {
        if (fssaiPattern.hasMatch(cleanLine)) {
          licenseNumber = fssaiPattern.stringMatch(cleanLine);
          confidence += 0.2;
        } else if (gstPattern.hasMatch(cleanLine)) {
          licenseNumber = gstPattern.stringMatch(cleanLine);
          confidence += 0.2;
        } else if (cleanLine.contains('LIC NO') ||
            cleanLine.contains('LICENSE NO') ||
            cleanLine.contains('REG NO')) {
          // Fallback: look for the next number in this line or next line
          // Simple heuristic: grabbing the longest digit sequence in this line
          final digitMatch = RegExp(r'\d{5,}').firstMatch(cleanLine);
          if (digitMatch != null) {
            licenseNumber = digitMatch.group(0);
            confidence += 0.1;
          }
        }
      }

      // Find Dates
      final dateMatches = datePattern.allMatches(line);
      for (var match in dateMatches) {
        String dateStr =
            match.group(0)!.replaceAll('-', '/').replaceAll('.', '/');
        try {
          // Normalize to yyyy-mm-dd for parsing if needed, but standard parse handles typical formats
          // Simple parser helper
          List<String> parts = dateStr.split('/');
          if (parts.length == 3) {
            // Assuming DD/MM/YYYY
            int day = int.parse(parts[0]);
            int month = int.parse(parts[1]);
            int year = int.parse(parts[2]);
            DateTime dt = DateTime(year, month, day);

            // Heuristics for Expiry vs Issue
            if (cleanLine.contains('EXP') ||
                cleanLine.contains('VALID') ||
                cleanLine.contains('UNTIL')) {
              expiryDate = dt;
              confidence += 0.2;
            } else if (cleanLine.contains('ISSUE') ||
                cleanLine.contains('DATE')) {
              issueDate = dt;
            } else {
              // If completely unknown, assume future date is expiry
              if (dt.isAfter(DateTime.now())) {
                expiryDate ??= dt;
              } else {
                issueDate ??= dt;
              }
            }
          }
        } catch (e) {
          // Ignore parse errors
        }
      }
    }

    return ExtractedDataModel(
      licenseNumber: licenseNumber,
      expiryDate: expiryDate,
      issueDate: issueDate,
      confidence: confidence > 1.0 ? 1.0 : confidence,
      rawText: text,
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}
