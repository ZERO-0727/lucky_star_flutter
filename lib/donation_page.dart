import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DonationPage extends StatefulWidget {
  const DonationPage({Key? key}) : super(key: key);

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  String? _selectedAmount;
  String _selectedPaymentMethod = 'Credit Card';
  final TextEditingController _customAmountController = TextEditingController();

  final List<String> _presetAmounts = ['\$5', '\$10', '\$30', '\$50'];

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  void _onPresetAmountSelected(String amount) {
    setState(() {
      _selectedAmount = amount;
      _customAmountController.clear();
    });
  }

  void _onCustomAmountChanged(String value) {
    setState(() {
      if (value.isNotEmpty) {
        _selectedAmount = null;
      }
    });
  }

  void _onPaymentMethodSelected(String method) {
    setState(() {
      _selectedPaymentMethod = method;
    });
  }

  void _donateNow() {
    String amountToDonate = _selectedAmount ?? (_customAmountController.text.isNotEmpty ? '\$${_customAmountController.text}' : '\$0');
    if (amountToDonate == '\$0' && (_customAmountController.text.isEmpty && _selectedAmount == null) ) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a donation amount.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Thank you for your $amountToDonate donation via $_selectedPaymentMethod!')),
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isCustomAmountEntered = _customAmountController.text.isNotEmpty;
    final bool isAmountSelected = _selectedAmount != null || isCustomAmountEntered;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Support Lucky Star'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Support Lucky Star',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Your support helps us grow and fulfill more global dreams. Thank you for believing in Lucky Star!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSecondaryContainer),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Select an amount:',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  alignment: WrapAlignment.center,
                  children: _presetAmounts.map((amount) {
                    bool isSelected = _selectedAmount == amount;
                    return ElevatedButton(
                      onPressed: () => _onPresetAmountSelected(amount),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? const Color(0xFF7153DF) : theme.colorScheme.surface,
                        foregroundColor: isSelected ? Colors.white : theme.colorScheme.onSurface,
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF7153DF) : theme.dividerColor,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Custom amount (optional):',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _customAmountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    hintText: 'Enter your amount in USD...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF7153DF), width: 2),
                    ),
                  ),
                  onChanged: _onCustomAmountChanged,
                ),
                const SizedBox(height: 32),
                Text(
                  'Choose a payment method:',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.credit_card),
                        label: const Text('Credit Card'),
                        onPressed: () => _onPaymentMethodSelected('Credit Card'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedPaymentMethod == 'Credit Card' ? const Color(0xFF7153DF) : theme.colorScheme.surface,
                          foregroundColor: _selectedPaymentMethod == 'Credit Card' ? Colors.white : theme.colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                             side: BorderSide(
                                color: _selectedPaymentMethod == 'Credit Card' ? const Color(0xFF7153DF) : theme.dividerColor,
                                width: 1.5
                            )
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.circle_outlined),
                        label: const Text('Worldcoin'),
                        onPressed: () => _onPaymentMethodSelected('Worldcoin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedPaymentMethod == 'Worldcoin' ? const Color(0xFF7153DF) : theme.colorScheme.surface,
                          foregroundColor: _selectedPaymentMethod == 'Worldcoin' ? Colors.white : theme.colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                             side: BorderSide(
                                color: _selectedPaymentMethod == 'Worldcoin' ? const Color(0xFF7153DF) : theme.dividerColor,
                                width: 1.5
                            )
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: isAmountSelected ? _donateNow : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7153DF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ).copyWith(
                     backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.disabled)) {
                            return Colors.grey[300];
                          }
                          return const Color(0xFF7153DF);
                        },
                      ),
                      foregroundColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.disabled)) {
                            return Colors.grey[700];
                          }
                          return Colors.white;
                        },
                      ),
                  ),
                  child: const Text('Donate Now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
