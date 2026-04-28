import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/tax_data_service.dart';
import '../../../theme/app_theme.dart';

class TaxCalculatorWidget extends StatefulWidget {
  const TaxCalculatorWidget({super.key});

  @override
  State<TaxCalculatorWidget> createState() => _TaxCalculatorWidgetState();
}

class _TaxCalculatorWidgetState extends State<TaxCalculatorWidget> {
  final _amountController = TextEditingController();
  final _taxDataService = TaxDataService();

  double? _gstRate;
  TaxCalculation? _calculation;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _calculateTax() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (TaxDataService.isAvailable) {
        // Use real API
        final calculation = await _taxDataService.calculateTax(
          amount: amount,
          taxType: 'GST',
          additionalParams: {'gst_rate': _gstRate ?? 18.0},
        );

        if (mounted && calculation != null) {
          setState(() {
            _calculation = calculation;
            _isLoading = false;
          });
        } else if (mounted) {
          // API returned null, use fallback
          _useFallbackCalculation(amount);
        }
      } else {
        // Fallback calculation
        _useFallbackCalculation(amount);
      }
    } catch (e) {
      debugPrint('Tax calculation error: $e');
      if (mounted) {
        _useFallbackCalculation(amount);
      }
    }
  }

  void _useFallbackCalculation(double amount) {
    final rate = _gstRate ?? 18.0;
    final gstAmount = amount * (rate / 100);

    setState(() {
      _calculation = TaxCalculation(
        baseAmount: amount,
        taxAmount: gstAmount,
        totalAmount: amount + gstAmount,
        breakdown: {
          'CGST': gstAmount / 2,
          'SGST': gstAmount / 2,
          'GST_RATE': rate,
        },
      );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calculate,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Quick Tax Calculator',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Amount Input
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: 'Amount (₹)',
              hintText: '10000',
              prefixIcon: const Icon(Icons.currency_rupee),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onSubmitted: (_) => _calculateTax(),
          ),

          const SizedBox(height: 12),

          // GST Rate Selector
          Row(
            children: [
              const Text(
                'GST Rate:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [5.0, 12.0, 18.0, 28.0].map((rate) {
                    final isSelected = _gstRate == rate;
                    return ChoiceChip(
                      label: Text('${rate.toInt()}%'),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _gstRate = selected ? rate : null);
                      },
                      selectedColor:
                          AppTheme.primaryBlue.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppTheme.primaryBlue
                            : Colors.grey[700],
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Calculate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _calculateTax,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Calculate'),
            ),
          ),

          // Results
          if (_calculation != null) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _buildResultRow(
              'Base Amount',
              '₹${_calculation!.baseAmount.toStringAsFixed(2)}',
              isBold: false,
            ),
            const SizedBox(height: 8),
            _buildResultRow(
              'CGST (${(_calculation!.breakdown['GST_RATE']! / 2).toStringAsFixed(1)}%)',
              '₹${_calculation!.breakdown['CGST']!.toStringAsFixed(2)}',
              isBold: false,
            ),
            const SizedBox(height: 8),
            _buildResultRow(
              'SGST (${(_calculation!.breakdown['GST_RATE']! / 2).toStringAsFixed(1)}%)',
              '₹${_calculation!.breakdown['SGST']!.toStringAsFixed(2)}',
              isBold: false,
            ),
            if (_calculation!.breakdown.containsKey('IGST') &&
                _calculation!.breakdown['IGST']! > 0) ...[
              const SizedBox(height: 8),
              _buildResultRow(
                'IGST (${_calculation!.breakdown['GST_RATE']!.toStringAsFixed(1)}%)',
                '₹${_calculation!.breakdown['IGST']!.toStringAsFixed(2)}',
                isBold: false,
              ),
            ],
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _buildResultRow(
              'Total Amount',
              '₹${_calculation!.totalAmount.toStringAsFixed(2)}',
              isBold: true,
              color: AppTheme.primaryBlue,
            ),
          ],

          if (!TaxDataService.isAvailable && _calculation == null) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Using standard GST rates',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
