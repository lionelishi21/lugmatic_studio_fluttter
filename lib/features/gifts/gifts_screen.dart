import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';
import '../account/payout_settings_screen.dart';

class GiftsScreen extends StatefulWidget {
  const GiftsScreen({super.key});

  @override
  State<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends State<GiftsScreen> {
  final _apiClient = ApiClient();
  List<dynamic> _gifts = [];
  int _totalCoins = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  Future<void> _loadGifts() async {
    try {
      final response = await _apiClient.dio.get(
        '/gifts/history',
        queryParameters: {'type': 'received', 'limit': 50},
      );
      final data = (response.data['data'] as List?) ?? [];
      final total = data.fold<int>(0, (sum, g) {
        final amount = g['gift']?['value'] ?? g['coins'] ?? 0;
        return sum + (amount is int ? amount : (amount as num).toInt());
      });
      if (mounted) {
        setState(() {
          _gifts = data;
          _totalCoins = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
                    _buildSummaryCard(),
                    const SizedBox(height: 32),
                    const Text(
                      'Recent Gifts',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (_gifts.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: Column(
                            children: [
                              Icon(Icons.card_giftcard, size: 56, color: AppColors.muted),
                              const SizedBox(height: 12),
                              Text('No gifts received yet.', style: TextStyle(color: AppColors.mutedForeground)),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._gifts.map((gift) => _buildGiftItem(gift)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, color: AppColors.primary, size: 28),
              const SizedBox(width: 8),
              Text(
                _totalCoins.toString(),
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PayoutSettingsScreen()),
            ),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: const Text('Withdraw / Payout Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftItem(dynamic gift) {
    final sender = gift['sender'];
    final senderName = sender != null
        ? '${sender['firstName'] ?? ''} ${sender['lastName'] ?? ''}'.trim()
        : 'Anonymous Fan';
    final giftName = gift['gift']?['name'] ?? 'Gift';
    final giftImage = gift['gift']?['image'];
    final coins = gift['gift']?['value'] ?? gift['coins'] ?? 0;
    final createdAt = gift['createdAt'] != null
        ? DateTime.tryParse(gift['createdAt'].toString())?.toLocal()
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicTheme.neumorphicDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Gift image or avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: giftImage != null
                ? ClipOval(child: Image.network(giftImage, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.card_giftcard, color: AppColors.primary, size: 22)))
                : const Icon(Icons.card_giftcard, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senderName.isNotEmpty ? senderName : 'Anonymous Fan',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sent you a $giftName',
                  style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                ),
                if (createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _timeAgo(createdAt),
                    style: const TextStyle(color: AppColors.mutedForeground, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.monetization_on, color: AppColors.primary, size: 14),
              const SizedBox(width: 3),
              Text(
                '+$coins',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
