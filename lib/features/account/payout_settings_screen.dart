import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';
import '../../providers/auth_provider.dart';
import '../../data/services/artist_service.dart';

class PayoutSettingsScreen extends StatefulWidget {
  const PayoutSettingsScreen({super.key});

  @override
  State<PayoutSettingsScreen> createState() => _PayoutSettingsScreenState();
}

class _PayoutSettingsScreenState extends State<PayoutSettingsScreen> {
  final _artistService = ArtistService();
  String _selectedMethod = 'paypal';
  
  // Controllers for various methods
  final _paypalEmailController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _accNumberController = TextEditingController();
  final _jamdexWalletController = TextEditingController();
  final _trnController = TextEditingController();
  final _idNumberController = TextEditingController();
  String _accType = 'savings';
  String _idType = 'nis';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPayoutData();
  }

  void _loadPayoutData() {
    final user = context.read<AuthProvider>().user;
    final payout = user?['payoutInfo'];
    final verification = user?['verificationDocuments'];

    if (payout != null) {
      setState(() {
        _selectedMethod = payout['method'] ?? 'paypal';
        _paypalEmailController.text = payout['paypalEmail'] ?? '';
        if (payout['jamaicanBank'] != null) {
          _bankNameController.text = payout['jamaicanBank']['bankName'] ?? '';
          _branchNameController.text = payout['jamaicanBank']['branchName'] ?? '';
          _accNumberController.text = payout['jamaicanBank']['accountNumber'] ?? '';
          _accType = payout['jamaicanBank']['accountType'] ?? 'savings';
        }
        if (payout['jamdex'] != null) {
          _jamdexWalletController.text = payout['jamdex']['walletAddress'] ?? '';
          _trnController.text = payout['jamdex']['trn'] ?? '';
        }
      });
    }

    if (verification != null) {
      setState(() {
        _idNumberController.text = verification['idNumber'] ?? '';
        _idType = verification['idType'] ?? 'nis';
      });
    }
  }

  Future<void> _savePayoutSettings() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final artistId = auth.user?['artistId'] ?? auth.user?['_id'];
      
      final payoutData = {
        'method': _selectedMethod,
        'payoutInfo': {
          'method': _selectedMethod,
          'paypalEmail': _paypalEmailController.text,
          'jamaicanBank': {
            'bankName': _bankNameController.text,
            'branchName': _branchNameController.text,
            'accountNumber': _accNumberController.text,
            'accountType': _accType,
          },
          'jamdex': {
            'walletAddress': _jamdexWalletController.text,
            'trn': _trnController.text,
          }
        },
        'verificationDocuments': {
          'idType': _idType,
          'idNumber': _idNumberController.text,
        }
      };
      
      await _artistService.updateProfile(artistId.toString(), payoutData);
      await auth.getMe();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payout settings saved'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payout & Verification')),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.screenGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Payout Method'),
              const SizedBox(height: 16),
              _buildMethodSelector(),
              const SizedBox(height: 24),
              
              if (_selectedMethod == 'paypal') _buildPaypalFields(),
              if (_selectedMethod == 'jamaican_bank') _buildJamaicanBankFields(),
              if (_selectedMethod == 'jamdex') _buildJamdexFields(),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Verification (Required)'),
              const SizedBox(height: 16),
              _buildVerificationFields(),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePayoutSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.2),
    );
  }

  Widget _buildMethodSelector() {
    final methods = [
      {'id': 'paypal', 'label': 'PayPal', 'icon': Icons.payment},
      {'id': 'jamaican_bank', 'label': 'Jamaican Bank', 'icon': Icons.account_balance},
      {'id': 'jamdex', 'label': 'JAMDEX', 'icon': Icons.currency_bitcoin},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: methods.map((m) {
        final isSelected = _selectedMethod == m['id'];
        return GestureDetector(
          onTap: () => setState(() => _selectedMethod = m['id'] as String),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: NeumorphicTheme.neumorphicDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.card,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(m['icon'] as IconData, size: 18, color: isSelected ? AppColors.primary : AppColors.mutedForeground),
                const SizedBox(width: 8),
                Text(
                  m['label'] as String,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.mutedForeground,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaypalFields() {
    return _buildInput('PayPal Email', _paypalEmailController, Icons.email_outlined);
  }

  Widget _buildJamaicanBankFields() {
    return Column(
      children: [
        _buildDropdown('Bank Name', _bankNameController.text, ['NCB', 'Scotiabank', 'Sagicor', 'JMMB', 'FGB', 'Other'], (val) {
          setState(() => _bankNameController.text = val!);
        }),
        const SizedBox(height: 16),
        _buildInput('Branch Name', _branchNameController, Icons.location_on_outlined),
        const SizedBox(height: 16),
        _buildInput('Account Number', _accNumberController, Icons.numbers),
        const SizedBox(height: 16),
        _buildDropdown('Account Type', _accType, ['savings', 'checking'], (val) {
          setState(() => _accType = val!);
        }),
      ],
    );
  }

  Widget _buildJamdexFields() {
    return Column(
      children: [
        _buildInput('Wallet Address / Lynk Email', _jamdexWalletController, Icons.wallet_outlined),
        const SizedBox(height: 16),
        _buildInput('TRN (9 digits)', _trnController, Icons.badge_outlined),
      ],
    );
  }

  Widget _buildVerificationFields() {
    return Column(
      children: [
        _buildDropdown('ID Type', _idType, ['nis', 'drivers_license', 'passport'], (val) {
          setState(() => _idType = val!);
        }),
        const SizedBox(height: 16),
        _buildInput('ID Number', _idNumberController, Icons.numbers),
        if (_trnController.text.isEmpty) ...[
          const SizedBox(height: 16),
          _buildInput('TRN (if not provided above)', _trnController, Icons.badge_outlined),
        ],
      ],
    );
  }

  Widget _buildInput(String label, TextEditingController controller, IconData icon) {
    return Container(
      decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(16), color: AppColors.card),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.foreground),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.mutedForeground),
          prefixIcon: Icon(icon, color: AppColors.mutedForeground),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(16), color: AppColors.card),
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : items.first,
        decoration: InputDecoration(labelText: label, border: InputBorder.none, labelStyle: const TextStyle(color: AppColors.mutedForeground)),
        dropdownColor: AppColors.card,
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(color: AppColors.foreground)))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
