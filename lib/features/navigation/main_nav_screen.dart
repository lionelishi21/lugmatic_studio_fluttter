import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../live/live_screen.dart';
import '../live/live_feed_screen.dart';
import '../gifts/gifts_screen.dart';
import '../account/account_screen.dart';
import '../tracks/tracks_list_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/live_streaming_provider.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TracksListScreen(),
    const LiveFeedScreen(),
    const LiveScreen(),
    const GiftsScreen(),
    const AccountScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final liveStreaming = context.watch<LiveStreamingProvider>();
    
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.mutedForeground,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.house, size: 20),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.music, size: 20),
              label: 'Tracks',
            ),
            const BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.fire, size: 20),
              label: 'Clash',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(FontAwesomeIcons.towerBroadcast, size: 20),
                  if (liveStreaming.isStreaming)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Live',
            ),
            const BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.gift, size: 20),
              label: 'Gifts',
            ),
            const BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.user, size: 20),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}

