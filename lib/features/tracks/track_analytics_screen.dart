import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';
import '../../providers/track_provider.dart';
import '../../data/models/track_model.dart';

class TrackAnalyticsScreen extends StatefulWidget {
  final Track track;
  const TrackAnalyticsScreen({super.key, required this.track});

  @override
  State<TrackAnalyticsScreen> createState() => _TrackAnalyticsScreenState();
}

class _TrackAnalyticsScreenState extends State<TrackAnalyticsScreen> {
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  void _fetchAnalytics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrackProvider>().fetchTrackAnalytics(widget.track.id, days: _selectedDays);
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
          child: Consumer<TrackProvider>(
            builder: (context, provider, _) {
              return Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: provider.isLoading && provider.selectedTrackAnalytics == null
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : _buildContent(provider),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            decoration: NeumorphicTheme.neumorphicDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.track.name,
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Track Analytics',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(TrackProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector
          _buildPeriodSelector(),
          const SizedBox(height: 24),
          
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Plays',
                  provider.selectedTrackAnalytics?.totalPlays.toString() ?? '0',
                  FontAwesomeIcons.play,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Period Plays',
                  _calculatePeriodPlays(provider.selectedTrackAnalytics).toString(),
                  FontAwesomeIcons.chartLine,
                  AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Chart
          _buildChartSection(provider.selectedTrackAnalytics),
          const SizedBox(height: 24),
          
          // Device Breakdown
          _buildDeviceBreakdown(provider.selectedTrackAnalytics),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  int _calculatePeriodPlays(TrackAnalytics? analytics) {
    if (analytics == null) return 0;
    return analytics.dailyStats.fold(0, (sum, item) => sum + item.plays);
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: NeumorphicTheme.neumorphicDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [7, 30, 90].map((d) {
          final isSelected = _selectedDays == d;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDays = d;
                });
                _fetchAnalytics();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$d Days',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.mutedForeground,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.foreground,
              fontSize: 20,
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
    );
  }

  Widget _buildChartSection(TrackAnalytics? analytics) {
    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
      decoration: NeumorphicTheme.neumorphicDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Streaming History',
            style: TextStyle(
              color: AppColors.foreground,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: analytics == null || analytics.dailyStats.isEmpty
                ? const Center(child: Text('No data for this period', style: TextStyle(color: AppColors.mutedForeground)))
                : LineChart(_buildLineChartData(analytics)),
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData(TrackAnalytics analytics) {
    final spots = List.generate(analytics.dailyStats.length, (i) {
      return FlSpot(i.toDouble(), analytics.dailyStats[i].plays.toDouble());
    });

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.border.withOpacity(0.2),
          strokeWidth: 1,
          dashArray: [5, 5],
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            getTitlesWidget: (value, meta) {
              if (value % (analytics.dailyStats.length / 4).ceil() != 0) return const SizedBox();
              int index = value.toInt();
              if (index >= analytics.dailyStats.length) return const SizedBox();
              String date = analytics.dailyStats[index].date.split('-').last;
              return Text(date, style: const TextStyle(color: AppColors.mutedForeground, fontSize: 10));
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              return Text(
                NumberFormat.compact().format(value),
                style: const TextStyle(color: AppColors.mutedForeground, fontSize: 10),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.primary.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceBreakdown(TrackAnalytics? analytics) {
    if (analytics == null || analytics.deviceStats.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicTheme.neumorphicDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device Breakdown',
            style: TextStyle(
              color: AppColors.foreground,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...analytics.deviceStats.map((stat) {
            double percentage = analytics.totalPlays > 0 ? (stat.count / analytics.totalPlays) : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        stat.device.toUpperCase(),
                        style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${(percentage * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(color: AppColors.foreground, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: AppColors.border.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
