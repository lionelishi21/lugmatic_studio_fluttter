import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

// Background message handler — must be top-level
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  debugPrint('FCM background: ${message.notification?.title}');
}

class FcmService {
  FcmService({required this.apiClient});

  final Dio apiClient;

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Register token with API
    final token = await messaging.getToken();
    if (token != null) await _registerToken(token);

    // Refresh token
    messaging.onTokenRefresh.listen(_registerToken);

    // Foreground messages — show a banner via overlay
    FirebaseMessaging.onMessage.listen(_showInAppBanner);

    // Tap on notification when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // App opened from a terminated state via notification
    final initial = await messaging.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);
  }

  Future<void> _registerToken(String token) async {
    try {
      await apiClient.post(
        '/user/fcm-token',
        data: {'token': token, 'platform': 'mobile'},
      );
    } catch (_) {}
  }

  void _showInAppBanner(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    debugPrint('FCM foreground: ${notification.title}');
    // In-app banners are handled via the notification overlay in main.dart
    // The snackbar approach requires a navigator key — handled externally if needed
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] ?? '';
    debugPrint('FCM tap: type=$type data=$data');
    // Route based on type — extend as needed
    // e.g. type == 'clash' → navigate to clashes screen
  }
}
