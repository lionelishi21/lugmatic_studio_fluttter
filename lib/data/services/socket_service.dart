import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api/api_client.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final _storage = const FlutterSecureStorage();
  
  // Stream controllers for real-time updates
  final _streamStateController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final _giftReceivedController = StreamController<Map<String, dynamic>>.broadcast();
  final _viewerCountController = StreamController<int>.broadcast();
  final _clashInvitationController = StreamController<Map<String, dynamic>>.broadcast();
  final _clashStartedController = StreamController<Map<String, dynamic>>.broadcast();
  final _clashScoreController = StreamController<Map<String, dynamic>>.broadcast();
  final _clashEndedController = StreamController<Map<String, dynamic>>.broadcast();
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get streamState => _streamStateController.stream;
  Stream<Map<String, dynamic>> get chatMessages => _chatMessageController.stream;
  Stream<Map<String, dynamic>> get giftReceived => _giftReceivedController.stream;
  Stream<int> get viewerCount => _viewerCountController.stream;
  Stream<Map<String, dynamic>> get clashInvitation => _clashInvitationController.stream;
  Stream<Map<String, dynamic>> get clashStarted => _clashStartedController.stream;
  Stream<Map<String, dynamic>> get clashScore => _clashScoreController.stream;
  Stream<Map<String, dynamic>> get clashEnded => _clashEndedController.stream;
  Stream<Map<String, dynamic>> get onNotification => _notificationController.stream;

  Future<void> connect() async {
    if (_socket?.connected == true) return;

    final token = await _storage.read(key: 'accessToken');
    if (token == null) return;

    final String socketUrl = ApiClient.baseUrl.replaceAll('/api', '');

    _socket = IO.io(socketUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .enableReconnection()
      .build());

    _socket!.onConnect((_) {
      print('Socket connected: ${_socket!.id}');
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
    });

    // Stream handlers
    _socket!.on('stream:state', (data) => _streamStateController.add(Map<String, dynamic>.from(data)));
    _socket!.on('stream:chat-message', (data) => _chatMessageController.add(Map<String, dynamic>.from(data)));
    _socket!.on('stream:gift-received', (data) => _giftReceivedController.add(Map<String, dynamic>.from(data)));
    _socket!.on('stream:viewer-joined', (data) => _viewerCountController.add(data['currentViewers']));
    _socket!.on('stream:viewer-left', (data) => _viewerCountController.add(data['currentViewers']));
    
    // Clash handlers
    _socket!.on('clash:invitation', (data) => _clashInvitationController.add(Map<String, dynamic>.from(data)));
    _socket!.on('clash:started', (data) => _clashStartedController.add(Map<String, dynamic>.from(data)));
    _socket!.on('clash:score-update', (data) => _clashScoreController.add(Map<String, dynamic>.from(data)));
    _socket!.on('clash:ended', (data) => _clashEndedController.add(Map<String, dynamic>.from(data)));
    _socket!.on('notification:new', (data) {
      print('[Socket] New notification: $data');
      _notificationController.add(Map<String, dynamic>.from(data));
    });
  }

  void joinStream(String streamId) {
    _socket?.emit('stream:join', {'streamId': streamId});
  }

  void leaveStream(String streamId) {
    _socket?.emit('stream:leave', {'streamId': streamId});
  }

  void sendChat(String streamId, String message) {
    _socket?.emit('stream:chat', {'streamId': streamId, 'message': message});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void dispose() {
    _streamStateController.close();
    _chatMessageController.close();
    _giftReceivedController.close();
    _viewerCountController.close();
    _clashInvitationController.close();
    _clashStartedController.close();
    _clashScoreController.close();
    _clashEndedController.close();
    _notificationController.close();
  }
}
