import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';
import '../../providers/auth_provider.dart';
import 'message_thread_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

class Participant {
  final String id;
  final String firstName;
  final String lastName;

  const Participant({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
        id: json['_id'] ?? '',
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
      );

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }
}

class LastMessage {
  final String content;
  final DateTime createdAt;

  const LastMessage({required this.content, required this.createdAt});

  factory LastMessage.fromJson(Map<String, dynamic> json) => LastMessage(
        content: json['content'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}

class Conversation {
  final String id;
  final List<Participant> participants;
  final LastMessage? lastMessage;
  final Map<String, int> unreadCounts;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.unreadCounts,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final rawParticipants = json['participants'] as List? ?? [];
    final rawUnread = json['unreadCounts'] as Map<String, dynamic>? ?? {};

    return Conversation(
      id: json['_id'] ?? '',
      participants: rawParticipants.map((p) => Participant.fromJson(p as Map<String, dynamic>)).toList(),
      lastMessage: json['lastMessage'] != null ? LastMessage.fromJson(json['lastMessage']) : null,
      unreadCounts: rawUnread.map((k, v) => MapEntry(k, (v as num).toInt())),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// Returns the other participant (not the current user).
  Participant? otherParticipant(String myId) {
    try {
      return participants.firstWhere((p) => p.id != myId);
    } catch (_) {
      return participants.isNotEmpty ? participants.first : null;
    }
  }

  int unreadFor(String userId) => unreadCounts[userId] ?? 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ApiClient _api = ApiClient();
  final TextEditingController _searchController = TextEditingController();

  List<Conversation> _conversations = [];
  List<Conversation> _filtered = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    final myId = _myId();
    setState(() {
      if (query.isEmpty) {
        _filtered = List.from(_conversations);
      } else {
        _filtered = _conversations.where((c) {
          final other = c.otherParticipant(myId);
          return other != null && other.fullName.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  String _myId() {
    final auth = context.read<AuthProvider>();
    return (auth.user?['_id'] ?? '').toString();
  }

  Future<void> _fetchConversations() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.dio.get('/messages');
      final raw = res.data;
      final list = (raw['data'] ?? raw) as List;
      _conversations = list.map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
      _filtered = List.from(_conversations);
    } catch (e) {
      _error = 'Failed to load messages: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.foreground),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: AppColors.foreground, fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Search conversations…',
            hintStyle: TextStyle(color: AppColors.mutedForeground, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: AppColors.mutedForeground, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(onPressed: _fetchConversations, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_filtered.isEmpty) {
      return _buildEmptyState();
    }

    final myId = _myId();

    return RefreshIndicator(
      onRefresh: _fetchConversations,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filtered.length,
        itemBuilder: (context, index) => _buildConversationTile(_filtered[index], myId),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, size: 72, color: AppColors.mutedForeground.withOpacity(0.3)),
          const SizedBox(height: 20),
          const Text(
            'No messages yet.',
            style: TextStyle(color: AppColors.foreground, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Fans who message you will appear here.',
            style: TextStyle(color: AppColors.mutedForeground, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(Conversation conv, String myId) {
    final other = conv.otherParticipant(myId);
    final unread = conv.unreadFor(myId);
    final hasUnread = unread > 0;

    final lastText = conv.lastMessage?.content ?? '';
    final lastTime = conv.lastMessage?.createdAt ?? conv.updatedAt;
    final timeLabel = _formatTime(lastTime);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MessageThreadScreen(
              conversationId: conv.id,
              otherName: other?.fullName ?? 'Unknown',
            ),
          ),
        );
        // Refresh on return (unread counts may have changed)
        _fetchConversations();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Text(
                other?.initials ?? '??',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Name + preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    other?.fullName ?? 'Unknown',
                    style: TextStyle(
                      color: AppColors.foreground,
                      fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lastText.isEmpty ? 'No messages yet' : lastText,
                    style: TextStyle(
                      color: hasUnread ? AppColors.foreground.withOpacity(0.8) : AppColors.mutedForeground,
                      fontSize: 13,
                      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Time + badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeLabel,
                  style: const TextStyle(color: AppColors.mutedForeground, fontSize: 11),
                ),
                if (hasUnread) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return DateFormat.jm().format(dt);
    if (diff.inDays < 7) return DateFormat.E().format(dt);
    return DateFormat.MMMd().format(dt);
  }
}
