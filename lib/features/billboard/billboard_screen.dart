import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';

class BillboardScreen extends StatefulWidget {
  const BillboardScreen({super.key});

  @override
  State<BillboardScreen> createState() => _BillboardScreenState();
}

class _BillboardScreenState extends State<BillboardScreen> {
  final _api = ApiClient();
  List<dynamic> _songs = [];
  bool _isLoading = true;
  String? _error;
  String _period = 'week'; // week | month | all

  static const _tabs = ['Weekly', 'Monthly', 'All Time'];
  static const _periods = ['week', 'month', 'all'];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await _api.dio.get('/song/billboard', queryParameters: {'period': _period});
      final data = res.data;
      List<dynamic> songs;
      if (data is List) {
        songs = data;
      } else if (data is Map && data['data'] != null) {
        songs = data['data'] as List<dynamic>;
      } else {
        songs = [];
      }
      if (mounted) setState(() { _songs = songs; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _selectPeriod(int index) {
    if (_periods[index] == _period) return;
    setState(() => _period = _periods[index]);
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = _periods.indexOf(_period);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Pinned AppBar with emerald gradient accent
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF34D399), Color(0xFF10B981)],
                  ).createShader(bounds),
                  child: const FaIcon(FontAwesomeIcons.trophy, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Billboard',
                  style: TextStyle(
                    color: AppColors.foreground,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Container(
                color: AppColors.background,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: List.generate(_tabs.length, (i) {
                      final isSelected = i == selectedTab;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _selectPeriod(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [Color(0xFF34D399), Color(0xFF10B981)],
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _tabs[i],
                              style: TextStyle(
                                color: isSelected ? Colors.black : AppColors.mutedForeground,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),

          // Body
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF34D399))),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    Text('Failed to load', style: const TextStyle(color: AppColors.mutedForeground)),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _fetch,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF34D399),
                        side: const BorderSide(color: Color(0xFF34D399)),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_songs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FontAwesomeIcons.chartBar, color: AppColors.muted, size: 56),
                    const SizedBox(height: 20),
                    const Text(
                      'No chart data yet',
                      style: TextStyle(color: AppColors.mutedForeground, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Come back after some plays are recorded',
                      style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _BillboardRow(rank: i + 1, song: _songs[i]),
                  childCount: _songs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _BillboardRow extends StatelessWidget {
  final int rank;
  final dynamic song;

  const _BillboardRow({required this.rank, required this.song});

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final coverUrl = song['coverArtUrl'] as String?;
    final trackName = (song['name'] ?? 'Unknown') as String;
    final artistName = (song['artist']?['name'] ?? '') as String;
    final playCount = (song['playCount'] ?? 0) as int;
    final genreName = (song['genre']?['name'] ?? '') as String;

    // Rank colours: gold/silver/bronze for top 3, emerald otherwise
    final Color rankColor;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700); // gold
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // silver
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // bronze
    } else {
      rankColor = AppColors.mutedForeground;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: NeumorphicTheme.neumorphicDecoration(
        borderRadius: BorderRadius.circular(16),
        color: rank == 1 ? const Color(0xFF1A1E14) : AppColors.card,
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Text(
                  '$rank',
                  style: TextStyle(
                    color: isTop3 ? rankColor : AppColors.mutedForeground,
                    fontWeight: isTop3 ? FontWeight.w900 : FontWeight.bold,
                    fontSize: isTop3 ? 18 : 15,
                  ),
                ),
                if (rank == 1)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: FaIcon(FontAwesomeIcons.trophy, size: 10, color: Color(0xFFFFD700)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Cover art
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: coverUrl != null
                ? Image.network(
                    coverUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(width: 14),

          // Track info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trackName,
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      artistName,
                      style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                    ),
                    if (genreName.isNotEmpty) ...[
                      const Text('  ·  ', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                      Text(
                        genreName,
                        style: const TextStyle(color: AppColors.mutedForeground, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Play count
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.headphones, size: 11, color: AppColors.mutedForeground),
              const SizedBox(width: 5),
              Text(
                NumberFormat.compact().format(playCount),
                style: TextStyle(
                  color: isTop3 ? rankColor : AppColors.mutedForeground,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 48,
    height: 48,
    color: AppColors.muted,
    child: const Center(child: FaIcon(FontAwesomeIcons.music, color: AppColors.primary, size: 16)),
  );
}
