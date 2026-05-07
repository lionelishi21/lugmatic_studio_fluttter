import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';
import '../../providers/live_streaming_provider.dart';
import 'widgets/clash_opponent_view.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> with WidgetsBindingObserver {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _chatController = TextEditingController();
  final _chatScrollController = ScrollController();
  String _selectedCategory = 'music';
  StreamSubscription? _invitationSub;

  static const _categories = ['music', 'poetry', 'dancing', 'art', 'performance', 'podcast', 'other'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LiveStreamingProvider>();
      _invitationSub = provider.clashInvitations.listen((data) {
        if (mounted) _showClashInvitation(data);
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _invitationSub?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  // ── Permission + stream start ───────────────────────────────────────

  Future<void> _startStreaming() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnack('Please enter a stream title');
      return;
    }

    // Request camera & mic permissions before touching LiveKit
    final camera = await Permission.camera.request();
    final mic    = await Permission.microphone.request();

    if (!camera.isGranted || !mic.isGranted) {
      _showSnack(
        'Camera and microphone access are required to stream. '
        'Please enable them in Settings.',
        error: true,
      );
      if (camera.isPermanentlyDenied || mic.isPermanentlyDenied) {
        openAppSettings();
      }
      return;
    }

    try {
      await context.read<LiveStreamingProvider>().startStreaming(
        _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
      );
    } catch (e) {
      if (mounted) _showSnack('Failed to start stream: $e', error: true);
    }
  }

  Future<void> _stopStreaming() async {
    try {
      await context.read<LiveStreamingProvider>().stopStreaming();
    } catch (e) {
      if (mounted) _showSnack('Failed to end stream: $e', error: true);
    }
  }

  void _sendChat() {
    final msg = _chatController.text.trim();
    if (msg.isEmpty) return;
    context.read<LiveStreamingProvider>().sendChat(msg);
    _chatController.clear();
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.redAccent : null,
    ));
  }

  void _showClashInvitation(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('⚔️ Clash Challenge!', style: TextStyle(color: Colors.white)),
        content: Text(
          '${data['challenger']['name']} has challenged you to a Lyrical War!',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await context.read<LiveStreamingProvider>().rejectClash(data['clashId']);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Decline', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              await context.read<LiveStreamingProvider>().acceptClash(data['clashId']);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LiveStreamingProvider>();

    // Force portrait when not streaming; allow landscape when live
    SystemChrome.setPreferredOrientations(
      provider.isStreaming
          ? [DeviceOrientation.portraitUp, DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
          : [DeviceOrientation.portraitUp],
    );

    if (provider.isStreaming) {
      return _buildLiveView(provider);
    }

    return _buildSetupScaffold(provider);
  }

  // ── Setup screen ────────────────────────────────────────────────────

  Widget _buildSetupScaffold(LiveStreamingProvider provider) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Go Live'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (provider.summary != null) ...[
              _buildSummaryCard(provider),
              const SizedBox(height: 24),
            ],
            const Icon(Icons.videocam_outlined, size: 72, color: AppColors.primary),
            const SizedBox(height: 20),
            const Text('Start a Live Session', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Connect with your fans and earn gifts in real-time.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mutedForeground, fontSize: 14)),
            const SizedBox(height: 32),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.foreground),
              decoration: NeumorphicTheme.neumorphicInputDecoration(
                label: 'Stream Title *',
                hint: 'e.g. Acoustic Night Live',
                prefixIcon: Icons.title,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              style: const TextStyle(color: AppColors.foreground),
              decoration: NeumorphicTheme.neumorphicInputDecoration(
                label: 'Description (optional)',
                hint: 'Tell fans what to expect...',
                prefixIcon: Icons.description_outlined,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              dropdownColor: AppColors.card,
              style: const TextStyle(color: AppColors.foreground),
              decoration: NeumorphicTheme.neumorphicInputDecoration(
                label: 'Category',
                prefixIcon: Icons.category_outlined,
              ),
              items: _categories.map((c) => DropdownMenuItem(
                value: c,
                child: Text(c[0].toUpperCase() + c.substring(1)),
              )).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v ?? 'music'),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: provider.isBusy ? null : _startStreaming,
              icon: provider.isBusy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.live_tv),
              label: Text(provider.isBusy ? 'Starting...' : 'Go Live Now'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(LiveStreamingProvider provider) {
    final summary = provider.summary!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          const Text('Stream Ended', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          IconButton(onPressed: () => provider.clearSummary(), icon: const Icon(Icons.close)),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _stat('Duration', '${((summary['duration'] ?? 0) / 60).floor()}m'),
          _stat('Viewers', '${summary['totalViewers'] ?? 0}'),
          _stat('Gifts', '${summary['totalGiftsReceived'] ?? 0}'),
          _stat('Earned', '${summary['totalGiftValue'] ?? 0} 🪙'),
        ]),
      ]),
    );
  }

  Widget _stat(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
  ]);

  // ── Full-screen live view ───────────────────────────────────────────

  Widget _buildLiveView(LiveStreamingProvider provider) {
    final track = provider.room?.localParticipant?.videoTrackPublications.firstOrNull?.track as LocalVideoTrack?;
    final clash = provider.activeClash;
    final inClash = provider.hasClashRoom && clash != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [

            // ── 1. Full-screen video ──────────────────────────────────
            inClash
                ? Column(children: [
                    Expanded(child: _cameraView(track, 'YOU')),
                    Container(height: 2, color: Colors.white24),
                    Expanded(child: ClashOpponentView(
                      clashRoomUrl: provider.clashRoomUrl!,
                      clashRoomToken: provider.clashRoomToken!,
                      opponentUserId: provider.clashOpponentUserId ?? '',
                      opponentName: (clash['opponent'] is Map
                          ? clash['opponent']['name'] : null) ?? 'Opponent',
                    )),
                  ])
                : _cameraView(track, null),

            // ── 2. Top bar ────────────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Row(children: [
                  // LIVE badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                    child: const Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  Text(provider.elapsedTime,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  // Viewer count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      const Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('${provider.viewerCount}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  // Coins earned
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                    child: Text('${provider.totalCoins} 🪙',
                        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ]),
              ),
            ),

            // ── 3. Gift alert ─────────────────────────────────────────
            if (provider.lastGift != null)
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.18, left: 16,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  builder: (_, v, __) => Opacity(
                    opacity: v,
                    child: Transform.translate(
                      offset: Offset((1 - v) * -40, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Colors.purple, Colors.pink]),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Text('🎁 ', style: TextStyle(fontSize: 16)),
                          Text(
                            '${provider.lastGift!['username']} sent ${provider.lastGift!['giftName']}!',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(10)),
                            child: Text('+${provider.lastGift!['giftValue']}',
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),

            // ── 4. Chat messages ──────────────────────────────────────
            Positioned(
              bottom: 72, left: 12, right: 88,
              child: _buildChatMessages(provider),
            ),

            // ── 5. Right-side controls ────────────────────────────────
            Positioned(
              right: 12, bottom: 72,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _controlBtn(
                  provider.isMicOn ? Icons.mic : Icons.mic_off,
                  provider.isMicOn ? Colors.white : Colors.red,
                  provider.toggleMic,
                  label: provider.isMicOn ? 'Mic' : 'Muted',
                ),
                const SizedBox(height: 16),
                _controlBtn(
                  provider.isCameraOn ? Icons.videocam : Icons.videocam_off,
                  provider.isCameraOn ? Colors.white : Colors.red,
                  provider.toggleCamera,
                  label: provider.isCameraOn ? 'Cam' : 'Cam Off',
                ),
                const SizedBox(height: 16),
                _controlBtn(Icons.stop_circle_outlined, Colors.redAccent, _stopStreaming, label: 'End'),
              ]),
            ),

            // ── 6. Bottom chat input ──────────────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Say something...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white12,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendChat(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendChat,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.send, color: Colors.black, size: 20),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cameraView(LocalVideoTrack? track, String? label) {
    return Stack(fit: StackFit.expand, children: [
      if (track != null)
        VideoTrackRenderer(track, key: ValueKey(track.sid), fit: VideoViewFit.cover)
      else
        Container(
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      if (label != null)
        Positioned(
          top: 8, left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
    ]);
  }

  Widget _buildChatMessages(LiveStreamingProvider provider) {
    if (provider.messages.isEmpty) return const SizedBox.shrink();
    final messages = provider.messages.take(6).toList().reversed.toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: messages.map((msg) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(12),
          ),
          child: RichText(
            text: TextSpan(children: [
              TextSpan(
                text: '${msg['username']} ',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              TextSpan(
                text: msg['message'],
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ]),
          ),
        ),
      )).toList(),
    );
  }

  Widget _controlBtn(IconData icon, Color color, VoidCallback onTap, {required String label}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ]),
    );
  }
}
