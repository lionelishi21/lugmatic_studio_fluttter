import 'package:flutter/foundation.dart';
import '../data/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<dynamic> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _service.getNotifications();
      _unreadCount = await _service.getUnreadCount();
    } catch (e) {
      // Error handled silently or via error field
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final success = await _service.markAsRead(id);
    if (success) {
      final index = _notifications.indexWhere((n) => n['_id'] == id);
      if (index != -1 && _notifications[index]['isRead'] != true) {
        _notifications[index]['isRead'] = true;
        _unreadCount = (_unreadCount - 1).clamp(0, 999);
        notifyListeners();
      }
    }
  }

  Future<void> markAllAsRead() async {
    final success = await _service.markAllAsRead();
    if (success) {
      for (var n in _notifications) {
        n['isRead'] = true;
      }
      _unreadCount = 0;
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String id) async {
    final success = await _service.deleteNotification(id);
    if (success) {
      final n = _notifications.firstWhere((n) => n['_id'] == id, orElse: () => null);
      if (n != null && n['isRead'] != true) {
        _unreadCount = (_unreadCount - 1).clamp(0, 999);
      }
      _notifications.removeWhere((n) => n['_id'] == id);
      notifyListeners();
    }
  }
}
