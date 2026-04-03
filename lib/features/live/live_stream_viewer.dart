import 'dart:async';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:collection/collection.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../data/services/live_stream_service.dart';
import '../../data/services/socket_service.dart';
import '../../data/services/gift_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';

class LiveStreamViewer extends StatefulWidget {
  final String streamId;
  final String hostName;
  final String title;
  final String description;
  final String? hostImage;
  final bool isActive;

  const LiveStreamViewer({
    super.key,
    required this.streamId,
    required this.hostName,
    required this.title,
    required this.description,
    this.hostImage,
    required this.isActive,
  });

  @override
  State<LiveStreamViewer> createState() => _LiveStreamViewerState();
}

class _LiveStreamViewerState extends State<LiveStreamViewer> {
  final _liveService = LiveStreamService();
  final _socketService = SocketService();
  final _giftService = GiftService();

  Room? _room;
  bool _isConnected = false;
  final List<Map<String, dynamic>> _messages = [];
  int _viewerCount = 0;
  
  StreamSubscription? _chatSub;
  StreamSubscription? _viewerSub;
  StreamSubscription? _giftSub;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _connectAsViewer();
    }
  }

  @override
  void didUpdateWidget(LiveStreamViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _connectAsViewer();
    } else if (!widget.isActive && oldWidget.isActive) {
      _disconnect();
    }
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }

  void _disconnect() {
    _chatSub?.cancel();
    _viewerSub?.cancel();
    _giftSub?.cancel();
    _room?.disconnect();
    _socketService.leaveStream(widget.streamId);
    if (mounted) setState(() => _isConnected = false);
  }

  Future<void> _connectAsViewer() async {
    try {
      final tokenData = await _liveService.getStreamToken(widget.streamId);
      final String url = tokenData['url'];
      final String token = tokenData['token'];

      _room = Room();
      await _room!.connect(url, token);
      
      _setupSocketListeners();

      if (mounted) setState(() => _isConnected = true);
    } catch (e) {
      print('Viewer connection error: $e');
    }
  }

  void _setupSocketListeners() {
    _chatSub = _socketService.chatMessages.listen((msg) {
      if (mounted) setState(() => _messages.add(msg));
    });

    _viewerSub = _socketService.viewerCount.listen((count) {
      if (mounted) setState(() => _viewerCount = count);
    });

    _giftSub = _socketService.giftReceived.listen((gift) {
      if (mounted) {
        setState(() => _messages.add(gift));
        // Show gift animation if needed
      }
    });

    _socketService.joinStream(widget.streamId);
  }

  void _showGiftPicker() async {
    final gifts = await _giftService.getGifts();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Send a Gift 🎁', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: gifts.length,
                itemBuilder: (context, index) {
                  final gift = gifts[index];
                  return GestureDetector(
                    onTap: () async {
                      try {
                        await _giftService.sendGift(
                          streamId: widget.streamId,
                          giftId: gift['_id'],
                          giftName: gift['name'],
                          giftValue: gift['value'],
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sent ${gift['name']}!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to send gift: $e')),
                        );
                      }
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 16),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(30)),
                            child: gift['icon'] != null 
                              ? Image.network(gift['icon']) 
                              : const Icon(Icons.card_giftcard, color: AppColors.primary),
                          ),
                          const SizedBox(height: 8),
                          Text(gift['name'], style: const TextStyle(fontSize: 12, color: Colors.white70), overflow: TextOverflow.ellipsis),
                          Text('${gift['value']} 🪙', style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected || _room == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    // Get the host's video track
    final track = (_room!.remoteParticipants.values.firstOrNull?.videoTrackPublications.firstOrNull?.track 
                ?? _room!.localParticipant?.videoTrackPublications.firstOrNull?.track) as VideoTrack?;

    return Stack(
      children: [
        // Video View
        Positioned.fill(
          child: track != null 
            ? VideoTrackRenderer(track, fit: VideoViewFit.cover)
            : Container(color: Colors.black, child: const Center(child: CircularProgressIndicator())),
        ),

        // Dark Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
        ),

        // Top Info (Host)
        Positioned(
          top: 60,
          left: 20,
          right: 20,
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: widget.hostImage != null ? NetworkImage(widget.hostImage!) : null,
                child: widget.hostImage == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.hostName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(widget.title, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Text('LIVE', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Text('$_viewerCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bottom Details & Actions
        Positioned(
          bottom: 40,
          left: 20,
          right: 80, // Leave space for side buttons
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('@${widget.hostName.toLowerCase().replaceAll(' ', '')}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(widget.description, style: const TextStyle(color: Colors.white70, fontSize: 14), maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 20),
              // Chat Preview (Last 3 messages)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _messages.length.clamp(0, 3),
                  itemBuilder: (context, index) {
                    final msg = _messages[(_messages.length - 1 - index).clamp(0, _messages.length - 1)];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: '${msg['username']}: ', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                            TextSpan(text: msg['message'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Side Actions (TikTok style)
        Positioned(
          bottom: 60,
          right: 12,
          child: Column(
            children: [
              _buildSideAction(FontAwesomeIcons.solidHeart, 'Like', () {}),
              const SizedBox(height: 20),
              _buildSideAction(FontAwesomeIcons.commentDots, '${_messages.length}', () {}),
              const SizedBox(height: 20),
              _buildSideAction(FontAwesomeIcons.gift, 'Gift', _showGiftPicker, color: Colors.amber),
              const SizedBox(height: 20),
              _buildSideAction(FontAwesomeIcons.share, 'Share', () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSideAction(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color ?? Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
