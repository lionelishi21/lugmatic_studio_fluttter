import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';
import '../../data/services/gift_service.dart';

class GiftsScreen extends StatefulWidget {
  const GiftsScreen({super.key});

  @override
  State<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends State<GiftsScreen> {
  final _giftService = GiftService();
  List<dynamic> _gifts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  Future<void> _loadGifts() async {
    try {
      final gifts = await _giftService.getMyGifts();
      setState(() {
        _gifts = gifts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gifts & Earnings')),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.screenGradient),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadGifts,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                   // Summary Card
                  _buildSummaryCard(),
                  const SizedBox(height: 32),

                  const Text(
                    'Recent Gifts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (_gifts.isEmpty)
                    const Center(child: Text('No gifts received yet.'))
                  else
                    ..._gifts.map((gift) => _buildGiftItem(gift)).toList(),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: NeumorphicTheme.neumorphicDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.card,
      ),
      child: Column(
        children: [
          const Text('Total Coins Received', style: TextStyle(color: AppColors.mutedForeground)),
          const SizedBox(height: 8),
          const Text(
            '45,000', // Dynamic balance later
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Withdraw to Stripe'),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftItem(dynamic gift) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicTheme.neumorphicDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.surfaceSubtle,
            child: const Icon(Icons.person, color: AppColors.mutedForeground),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gift['senderName'] ?? 'Anonymous Fan',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  gift['message'] ?? 'Sent you a gift!',
                  style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            '+${gift['amount']} 🪙',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
