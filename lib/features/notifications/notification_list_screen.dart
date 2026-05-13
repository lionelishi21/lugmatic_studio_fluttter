import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';
import '../../providers/notification_provider.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () => context.read<NotificationProvider>().markAllAsRead(),
            child: const Text('Clear All', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (provider.notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(),
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final n = provider.notifications[index];
                return _buildNotificationItem(n);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined, color: AppColors.mutedForeground.withOpacity(0.2), size: 80),
          const SizedBox(height: 24),
          const Text('No notifications yet', style: TextStyle(color: AppColors.mutedForeground, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(dynamic n) {
    final bool isRead = n['isRead'] ?? false;
    final String type = n['type'] ?? 'system';
    
    IconData icon;
    Color iconColor;
    
    switch (type) {
      case 'gift':
        icon = FontAwesomeIcons.gift;
        iconColor = Colors.roseAccent;
        break;
      case 'earnings':
        icon = FontAwesomeIcons.coins;
        iconColor = Colors.amberAccent;
        break;
      case 'follow':
        icon = FontAwesomeIcons.userPlus;
        iconColor = Colors.blueAccent;
        break;
      case 'comment':
        icon = FontAwesomeIcons.comment;
        iconColor = Colors.emeraldAccent;
        break;
      default:
        icon = Icons.notifications_outlined;
        iconColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          context.read<NotificationProvider>().markAsRead(n['_id']);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: NeumorphicTheme.neumorphicDecoration(
          borderRadius: BorderRadius.circular(16),
        ).copyWith(
          color: isRead ? AppColors.card.withOpacity(0.5) : AppColors.card,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        n['title'] ?? 'Notification',
                        style: TextStyle(
                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          fontSize: 14,
                          color: isRead ? AppColors.mutedForeground : AppColors.foreground,
                        ),
                      ),
                      Text(
                        _formatDate(n['createdAt']),
                        style: const TextStyle(color: AppColors.mutedForeground, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n['message'] ?? '',
                    style: TextStyle(
                      color: isRead ? AppColors.mutedForeground : AppColors.foreground.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr);
    return DateFormat.jm().format(date);
  }
}
