import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';
import '../../data/services/support_service.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _service = SupportService();
  final _formKey = GlobalKey<FormState>();
  
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'technical';
  
  bool _isSubmitting = false;

  final List<Map<String, String>> _faqs = [
    { 'q': 'Revenue Discrepancy', 'a': 'Earnings are processed monthly. Once you reach the \$50 threshold, you can request a payout.' },
    { 'q': 'Mastering Standards', 'a': 'We support MP3 and WAV files up to 50MB per track for the best quality playback.' },
    { 'q': 'Transmission Latency', 'a': 'Go to the Live section, set your title, and click Go Live.' },
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _service.createSupportTicket(
        subject: _subjectController.text.trim(),
        category: _selectedCategory,
        message: _messageController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket created! We will get back to you soon.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit ticket: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Support', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildFAQSection(),
            const SizedBox(height: 40),
            _buildTicketForm(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.help_outline, color: AppColors.primary, size: 32),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Command Assistance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('We\'re here to help you navigate and succeed.', style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Frequent Solutions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ..._faqs.map((faq) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            title: Text(faq['q']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.foreground)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedAlignment: Alignment.topLeft,
            children: [
              Text(faq['a']!, style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildTicketForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Submit a Ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          const Text('Category', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                dropdownColor: AppColors.card,
                isExpanded: true,
                items: ['technical', 'billing', 'copyright', 'feature', 'other'].map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c.toUpperCase(), style: const TextStyle(color: AppColors.foreground, fontSize: 13)),
                )).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          _buildTextField(
            controller: _subjectController,
            label: 'Subject',
            hint: 'What\'s the issue?',
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          
          const SizedBox(height: 20),
          _buildTextField(
            controller: _messageController,
            label: 'Message',
            hint: 'Describe your operational bottleneck...',
            maxLines: 5,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSubmitting 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Text('DISPATCH TICKET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, int maxLines = 1, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: AppColors.foreground, fontSize: 14),
          decoration: NeumorphicTheme.neumorphicInputDecoration(label: 'Message', hint: hint),
        ),
      ],
    );
  }
}
