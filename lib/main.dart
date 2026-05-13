import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/live_streaming_provider.dart';
import 'providers/track_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/podcast_provider.dart';
import 'providers/notification_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/navigation/main_nav_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => LiveStreamingProvider()),
        ChangeNotifierProvider(create: (_) => TrackProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => PodcastProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const LugmaticArtistApp(),
    ),
  );
}

class LugmaticArtistApp extends StatelessWidget {
  const LugmaticArtistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lugmatic Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            return const MainNavScreen();
          }
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const MainNavScreen(),
      },
    );
  }
}
