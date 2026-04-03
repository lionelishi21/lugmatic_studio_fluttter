import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';
import '../../providers/auth_provider.dart';
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
        context.read<DashboardProvider>().fetchDashboardData(artistId.toString());
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
          child: Consumer2<AuthProvider, DashboardProvider>(
            builder: (context, auth, dashboard, _) {
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
                      _buildStatsGrid(dashboard.artistStats, dashboard.artistEarnings),
                    const SizedBox(height: 32),

                    // Recent Uploads / Activity Section Header
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
                        TextButton(
                          onPressed: () {},
                          child: const Text('View All'),
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

  Widget _buildStatsGrid(ArtistStats? stats, ArtistEarnings? earnings) {
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
            AppColors.primary),
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
            Colors.orangeAccent),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
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
