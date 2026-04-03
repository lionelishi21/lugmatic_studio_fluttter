import 'dart:async';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import '../data/services/live_stream_service.dart';
import '../data/services/socket_service.dart';
import '../data/services/clash_service.dart';

class LiveStreamingProvider extends ChangeNotifier {
  final LiveStreamService _liveService = LiveStreamService();
  final SocketService _socketService = SocketService();
  final ClashService _clashService = ClashService();

  bool _isStreaming = false;
  bool _isBusy = false;
  Room? _room;
  String? _streamId;
  Map<String, dynamic>? _summary;
  
  final List<Map<String, dynamic>> _messages = [];
  int _viewerCount = 0;
  int _totalCoins = 0;
  DateTime? _liveSince;
  Timer? _timer;
  String _elapsedTime = '0:00';

  bool _isMicOn = true;
  bool _isCameraOn = true;
  Map<String, dynamic>? _lastGift;
  Map<String, dynamic>? _activeClash;

  StreamSubscription? _chatSub;
  StreamSubscription? _giftSub;
  StreamSubscription? _viewerSub;
  StreamSubscription? _clashInvSub;
  StreamSubscription? _clashStartSub;
  StreamSubscription? _clashScoreSub;
  StreamSubscription? _clashEndSub;

  // Getters
  bool get isStreaming => _isStreaming;
  bool get isBusy => _isBusy;
  Room? get room => _room;
  String? get streamId => _streamId;
  Map<String, dynamic>? get summary => _summary;
  List<Map<String, dynamic>> get messages => _messages;
  int get viewerCount => _viewerCount;
  int get totalCoins => _totalCoins;
  String get elapsedTime => _elapsedTime;
  bool get isMicOn => _isMicOn;
  bool get isCameraOn => _isCameraOn;
  Map<String, dynamic>? get lastGift => _lastGift;
  Map<String, dynamic>? get activeClash => _activeClash;

  void clearSummary() {
    _summary = null;
    notifyListeners();
  }

  Future<void> startStreaming(String title) async {
    _isBusy = true;
    notifyListeners();

    try {
      final stream = await _liveService.createStream(title: title);
      _streamId = stream['_id'];
      
      final tokenData = await _liveService.getStreamToken(_streamId!);
      final String url = tokenData['url'];
      final String token = tokenData['token'];

      _room = Room();
      await _room!.connect(url, token);
      
      await _room!.localParticipant?.setCameraEnabled(true);
      await _room!.localParticipant?.setMicrophoneEnabled(true);

      _setupSocketListeners(_streamId!);
      _liveSince = DateTime.now();
      _startTimer();

      _isStreaming = true;
      _isBusy = false;
      _summary = null;
      notifyListeners();
    } catch (e) {
      _isBusy = false;
      notifyListeners();
      rethrow;
    }
  }

  void _setupSocketListeners(String streamId) {
    _cancelSubscriptions();
    
    _chatSub = _socketService.chatMessages.listen((msg) {
      _messages.add(msg);
      notifyListeners();
    });

    _giftSub = _socketService.giftReceived.listen((gift) {
      _messages.add(gift);
      _totalCoins += (gift['giftValue'] as num?)?.toInt() ?? 0;
      _lastGift = gift;
      notifyListeners();
      
      Future.delayed(const Duration(seconds: 4), () {
        if (_lastGift == gift) {
          _lastGift = null;
          notifyListeners();
        }
      });
    });

    _viewerSub = _socketService.viewerCount.listen((count) {
      _viewerCount = count;
      notifyListeners();
    });

    _clashInvSub = _socketService.clashInvitation.listen((data) {
      // Logic for showing dialog should probably remain in UI or use a stream
      // We'll expose this as a stream or a broadcast for the UI to listen to
    });

    _clashStartSub = _socketService.clashStarted.listen((data) {
      _activeClash = data;
      notifyListeners();
    });

    _clashScoreSub = _socketService.clashScore.listen((data) {
      if (_activeClash != null) {
        _activeClash!['challengerScore'] = data['challengerScore'];
        _activeClash!['opponentScore'] = data['opponentScore'];
        notifyListeners();
      }
    });

    _clashEndSub = _socketService.clashEnded.listen((data) {
      _activeClash = null;
      notifyListeners();
    });

    _socketService.joinStream(streamId);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_liveSince != null) {
        final diff = DateTime.now().difference(_liveSince!);
        _elapsedTime = _formatDuration(diff);
        notifyListeners();
      }
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    if (d.inHours > 0) {
      return "${d.inHours}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
    }
    return "${d.inMinutes}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  Future<void> stopStreaming() async {
    if (_streamId == null) return;
    
    _isBusy = true;
    notifyListeners();
    
    try {
      final summary = await _liveService.endStream(_streamId!);
      await _room?.disconnect();
      _socketService.leaveStream(_streamId!);
      _timer?.cancel();

      _isStreaming = false;
      _isBusy = false;
      _room = null;
      _summary = summary;
      _messages.clear();
      _viewerCount = 0;
      _totalCoins = 0;
      _activeClash = null;
      _elapsedTime = '0:00';
      notifyListeners();
    } catch (e) {
      _isBusy = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleMic() async {
    if (_room == null) return;
    _isMicOn = !_isMicOn;
    await _room!.localParticipant?.setMicrophoneEnabled(_isMicOn);
    notifyListeners();
  }

  Future<void> toggleCamera() async {
    if (_room == null) return;
    _isCameraOn = !_isCameraOn;
    await _room!.localParticipant?.setCameraEnabled(_isCameraOn);
    notifyListeners();
  }

  void sendChat(String message) {
    if (_streamId == null || message.trim().isEmpty) return;
    _socketService.sendChat(_streamId!, message.trim());
  }

  void _cancelSubscriptions() {
    _chatSub?.cancel();
    _giftSub?.cancel();
    _viewerSub?.cancel();
    _clashInvSub?.cancel();
    _clashStartSub?.cancel();
    _clashScoreSub?.cancel();
    _clashEndSub?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cancelSubscriptions();
    _room?.disconnect();
    super.dispose();
  }

  // Helper for UI to handle clash invitations
  Stream<Map<String, dynamic>> get clashInvitations => _socketService.clashInvitation;

  Future<void> acceptClash(String clashId) async {
    await _clashService.acceptClash(clashId);
  }

  Future<void> rejectClash(String clashId) async {
    await _clashService.rejectClash(clashId);
  }
}
