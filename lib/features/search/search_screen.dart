import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _api = ApiClient();
  final _controller = TextEditingController();
  final _focus = FocusNode();

  List<dynamic> _songs = [];
  bool _isLoading = false;
  String? _error;
  Timer? _debounce;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final q = _controller.text.trim();
    if (q == _lastQuery) return;
    _debounce?.cancel();
    if (q.isEmpty) {
      setState(() { _songs = []; _error = null; _isLoading = false; _lastQuery = ''; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 420), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() { _isLoading = true; _error = null; _lastQuery = q; });
    try {
      final res = await _api.dio.get('/song/list', queryParameters: {'search': q});
      final data = res.data;
      List<dynamic> songs;
      if (data is List) {
        songs = data;
      } else if (data is Map && data['data'] != null) {
        songs = data['data'] as List<dynamic>;
      } else {
        songs = [];
      }
      if (mounted) setState(() { _songs = songs; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Search failed'; _isLoading = false; });
    }
  }

  void _clear() {
    _controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _controller.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Search',
          style: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: true,
              style: const TextStyle(color: AppColors.foreground, fontSize: 15),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'Search for tracks, artists...',
                hintStyle: const TextStyle(color: AppColors.mutedForeground, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.mutedForeground, size: 20),
                suffixIcon: hasQuery
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.mutedForeground, size: 18),
                        onPressed: _clear,
                      )
                    : null,
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5), width: 1.5),
                ),
              ),
            ),
          ),

          // Results area
          Expanded(child: _buildBody(hasQuery)),
        ],
      ),
    );
  }

  Widget _buildBody(bool hasQuery) {
    if (!hasQuery) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.magnifyingGlass, size: 48, color: AppColors.muted),
            const SizedBox(height: 20),
            const Text(
              'Search for tracks, artists...',
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 15),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.mutedForeground)),
          ],
        ),
      );
    }

    if (_songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.circleXmark, size: 48, color: AppColors.muted),
            const SizedBox(height: 20),
            Text(
              'No results for "${_controller.text.trim()}"',
              style: const TextStyle(color: AppColors.mutedForeground, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      itemCount: _songs.length,
      itemBuilder: (context, i) => _SongRow(song: _songs[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SongRow extends StatelessWidget {
  final dynamic song;
  const _SongRow({required this.song});

  @override
  Widget build(BuildContext context) {
    final coverUrl = song['coverArtUrl'] as String?;
    final name = (song['name'] ?? 'Unknown') as String;
    final artistName = (song['artist']?['name'] ?? song['artistName'] ?? '') as String;
    final status = (song['status'] ?? '') as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: coverUrl != null
                ? Image.network(
                    coverUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  artistName,
                  style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (status.isNotEmpty) _StatusBadge(status: status),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 52,
    height: 52,
    color: AppColors.muted,
    child: const Center(child: FaIcon(FontAwesomeIcons.music, color: AppColors.primary, size: 16)),
  );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved': color = Colors.greenAccent; break;
      case 'pending':  color = Colors.amberAccent; break;
      case 'rejected': color = Colors.redAccent;   break;
      default:         color = AppColors.mutedForeground;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}
