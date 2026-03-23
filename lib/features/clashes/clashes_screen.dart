import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';
import '../../data/services/clash_service.dart';

class ClashesScreen extends StatefulWidget {
  const ClashesScreen({super.key});

  @override
  State<ClashesScreen> createState() => _ClashesScreenState();
}

class _ClashesScreenState extends State<ClashesScreen> {
  final _clashService = ClashService();
  List<dynamic> _clashes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClashes();
  }

  Future<void> _loadClashes() async {
    try {
      final clashes = await _clashService.getActiveClashes();
      setState(() {
        _clashes = clashes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Clashes')),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.screenGradient),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadClashes,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                   // Active Clashes
                  if (_clashes.isEmpty)
                    _buildEmptyState()
                  else
                    ..._clashes.map((clash) => _buildClashCard(clash)).toList(),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.bolt, size: 80, color: AppColors.muted),
        const SizedBox(height: 24),
        const Text(
          'No Active Clashes',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {},
          child: const Text('View Competition Rules'),
        ),
      ],
    );
  }

  Widget _buildClashCard(dynamic clash) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: NeumorphicTheme.neumorphicDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Header (Round / Title)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clash['title'] ?? 'Weekly Clash #42',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text('Round 2 of 4', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('LIVE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),

          // Competition Visual (vs)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildArtistPreview('Artist One', '45%'),
                const Text('VS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                _buildArtistPreview('Artist Two', '55%'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Footer (Join / Vote)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.card,
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    child: const Text('Enter Competition'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Vote Live'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistPreview(String name, String percentage) {
    return Column(
      children: [
        const CircleAvatar(radius: 32, backgroundColor: AppColors.primary),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(percentage, style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
