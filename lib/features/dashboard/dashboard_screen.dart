import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/track_provider.dart';
import '../../providers/navigation_provider.dart';
import '../tracks/track_analytics_screen.dart';
import '../../providers/dashboard_provider.dart';
import '../../data/models/dashboard_models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final artistId = auth.user?['artistId'] ?? auth.user?['_id'];
      if (artistId != null) {
        final id = artistId.toString();
        context.read<DashboardProvider>().fetchDashboardData(id);
        context.read<TrackProvider>().fetchTracks(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.screenGradient,
        ),
        child: SafeArea(
          child: Consumer3<AuthProvider, DashboardProvider, TrackProvider>(
            builder: (context, auth, dashboard, trackProvider, _) {
              final navProvider = context.read<NavigationProvider>();
              
              if (dashboard.isLoading) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              if (dashboard.error != null) {
                return Center(
                  child: Text(
                    dashboard.error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }

              final artistName = dashboard.artistDetails?.name ?? auth.user?['name'] ?? 'Artist';
              final profileUrl = dashboard.artistDetails?.profilePicture ?? dashboard.artistDetails?.image ?? auth.user?['profilePicture'];

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              artistName,
                              style: TextStyle(
                                color: AppColors.foreground,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.card,
                          backgroundImage: profileUrl != null ? NetworkImage(profileUrl) : null,
                          child: profileUrl == null ? const Icon(Icons.person, color: AppColors.primary) : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Stats Grid
                    if (dashboard.artistStats != null || dashboard.artistEarnings != null)
                      _buildStatsGrid(dashboard.artistStats, dashboard.artistEarnings, navProvider),
                    const SizedBox(height: 32),

                    // My Tracks Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Tracks',
                          style: TextStyle(
                            color: AppColors.foreground,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () => navProvider.setIndex(1),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Horizontal Tracks List
                    if (trackProvider.tracks.isNotEmpty)
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: trackProvider.tracks.length > 5 ? 5 : trackProvider.tracks.length,
                          itemBuilder: (context, index) {
                            final track = trackProvider.tracks[index];
                            return _buildTrackCard(track);
                          },
                        ),
                      )
                    else if (trackProvider.isLoading)
                      const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()))
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: NeumorphicTheme.neumorphicDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.music_note_outlined, color: AppColors.mutedForeground, size: 32),
                            SizedBox(height: 8),
                            Text(
                              'No tracks uploaded yet',
                              style: TextStyle(color: AppColors.mutedForeground, fontSize: 14),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Recent Activity Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Activity',
                          style: TextStyle(
                            color: AppColors.foreground,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // List
                    if (dashboard.artistEarnings?.history != null && dashboard.artistEarnings!.history.isNotEmpty)
                      ...dashboard.artistEarnings!.history.take(5).map((t) => _buildRecentActivityItem(t))
                    else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'No recent activity found.',
                            style: TextStyle(color: AppColors.mutedForeground),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(ArtistStats? stats, ArtistEarnings? earnings, NavigationProvider navProvider) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final numberFormatter = NumberFormat.compact();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
            'Total Plays', 
            stats != null ? numberFormatter.format(stats.totalPlays) : '0', 
            FontAwesomeIcons.play, 
            AppColors.primary,
            onTap: () => navProvider.setIndex(1)),
        _buildStatCard(
            'Monthly Listeners', 
            stats != null ? numberFormatter.format(stats.monthlyListeners) : '0', 
            FontAwesomeIcons.headphones, 
            AppColors.secondary),
        _buildStatCard(
            'Followers', 
            stats != null ? numberFormatter.format(stats.socialMediaFollowers) : '0', 
            FontAwesomeIcons.users, 
            Colors.blueAccent),
        _buildStatCard(
            'Earnings', 
            earnings != null ? currencyFormatter.format(earnings.totalEarnings) : '\$0', 
            FontAwesomeIcons.wallet, 
            Colors.orangeAccent,
            onTap: () => navProvider.setIndex(4)), // index 4 is Gifts/Earnings
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: NeumorphicTheme.neumorphicDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color.withAlpha(204), size: 18),
                const Icon(Icons.arrow_forward_ios, color: AppColors.mutedForeground, size: 10),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackCard(track) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrackAnalyticsScreen(track: track),
          ),
        );
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(12),
        decoration: NeumorphicTheme.neumorphicDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: track.coverArtUrl != null || track.coverArt != null
                  ? Image.network(
                      track.coverArtUrl ?? track.coverArt!,
                      height: 80,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) => _buildPlaceholderCover(),
                    )
                  : _buildPlaceholderCover(),
            ),
            const SizedBox(height: 8),
            Text(
              track.name,
              style: const TextStyle(
                color: AppColors.foreground,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(FontAwesomeIcons.play, color: AppColors.primary, size: 8),
                const SizedBox(width: 4),
                Text(
                  NumberFormat.compact().format(track.playCount),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(FontAwesomeIcons.music, color: AppColors.primary, size: 20),
    );
  }

  Widget _buildRecentActivityItem(Transaction transaction) {
    IconData icon;
    Color iconColor;

    if (transaction.type == 'gift_received') {
      icon = FontAwesomeIcons.gift;
      iconColor = AppColors.secondary;
    } else if (transaction.type == 'payout') {
      icon = FontAwesomeIcons.wallet;
      iconColor = Colors.orangeAccent;
    } else {
      icon = FontAwesomeIcons.moneyBillTransfer;
      iconColor = AppColors.primary;
    }

    final dateFormat = DateFormat.yMMMd().add_jm();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicTheme.neumorphicDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  dateFormat.format(transaction.createdAt),
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            (transaction.amount > 0 ? '+' : '') + NumberFormat.currency(symbol: '\$').format(transaction.amount),
            style: TextStyle(
              color: transaction.amount > 0 ? AppColors.secondary : AppColors.foreground,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }
}
