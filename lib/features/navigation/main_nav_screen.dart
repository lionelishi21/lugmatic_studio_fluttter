import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../live/live_screen.dart';
import '../live/live_feed_screen.dart';
import '../clashes/clashes_screen.dart';
import '../gifts/gifts_screen.dart';
import '../account/account_screen.dart';
import '../tracks/tracks_list_screen.dart';
import '../messages/messages_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/live_streaming_provider.dart';
import '../../providers/navigation_provider.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _liveGlowController;

  // Tabs: Home | Tracks | [LIVE - center] | Clashes | Messages | Profile
  // Gifts are accessible from the Profile/Account tab
  final List<Widget> _screens = const [
    DashboardScreen(),
    TracksListScreen(),
    LiveScreen(),       // index 2 = Live (center button)
    ClashesScreen(),
    MessagesScreen(),
    AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _liveGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _liveGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isStreaming = context.select<LiveStreamingProvider, bool>(
      (p) => p.isStreaming,
    );
    final navProvider = context.watch<NavigationProvider>();
    final currentIndex = navProvider.selectedIndex.clamp(0, _screens.length - 1);

    // Hide the system bottom bar for full immersion
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Color(0xFF0A0A12),
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: currentIndex,
        isStreaming: isStreaming,
        glowController: _liveGlowController,
        onTap: (i) => navProvider.setIndex(i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom bottom nav with centre Live button
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final bool isStreaming;
  final AnimationController glowController;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.isStreaming,
    required this.glowController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(8, 0, 8, bottom + 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A12),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _NavItem(icon: FontAwesomeIcons.house,   label: 'Home',     index: 0, current: currentIndex, onTap: onTap),
          _NavItem(icon: FontAwesomeIcons.music,   label: 'Tracks',   index: 1, current: currentIndex, onTap: onTap),

          // ── Centre LIVE button ──
          _LiveButton(
            isStreaming: isStreaming,
            isActive: currentIndex == 2,
            glowController: glowController,
            onTap: () => onTap(2),
          ),

          _NavItem(icon: FontAwesomeIcons.fire,    label: 'Clashes',  index: 3, current: currentIndex, onTap: onTap),
          _NavItem(icon: Icons.message_outlined,   label: 'Messages', index: 4, current: currentIndex, onTap: onTap, useRegularIcon: true, activeIcon: Icons.message),
          _NavItem(icon: FontAwesomeIcons.user,    label: 'Profile',  index: 5, current: currentIndex, onTap: onTap),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;
  /// When true, renders a Material [Icon] instead of [FaIcon].
  final bool useRegularIcon;
  /// Optional active-state icon (only used when [useRegularIcon] is true).
  final IconData? activeIcon;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
    this.useRegularIcon = false,
    this.activeIcon,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    final resolvedIcon = (active && activeIcon != null) ? activeIcon! : icon;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: active ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: useRegularIcon
                  ? Icon(
                      resolvedIcon,
                      size: 20,
                      color: active ? AppColors.primary : const Color(0xFF5A5A6E),
                    )
                  : FaIcon(
                      icon,
                      size: 18,
                      color: active ? AppColors.primary : const Color(0xFF5A5A6E),
                    ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? AppColors.primary : const Color(0xFF5A5A6E),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveButton extends StatelessWidget {
  final bool isStreaming;
  final bool isActive;
  final AnimationController glowController;
  final VoidCallback onTap;

  const _LiveButton({
    required this.isStreaming,
    required this.isActive,
    required this.glowController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: glowController,
              builder: (_, __) {
                final glow = isStreaming
                    ? (glowController.value * 16 + 8)
                    : (isActive ? 12.0 : 0.0);
                final glowColor = isStreaming
                    ? Colors.red.withOpacity(0.5 + glowController.value * 0.3)
                    : AppColors.primary.withOpacity(0.3);

                return Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isStreaming
                          ? [const Color(0xFFFF4444), const Color(0xFFCC0000)]
                          : [AppColors.primary, AppColors.primaryDim],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor,
                        blurRadius: glow,
                        spreadRadius: glow / 4,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        isStreaming
                            ? FontAwesomeIcons.towerBroadcast
                            : FontAwesomeIcons.video,
                        color: isStreaming ? Colors.white : Colors.black,
                        size: 22,
                      ),
                      if (isStreaming)
                        Positioned(
                          top: 6, right: 6,
                          child: Container(
                            width: 9, height: 9,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              isStreaming ? 'LIVE' : 'Go Live',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isStreaming ? Colors.red : AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
