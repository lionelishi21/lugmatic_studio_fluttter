import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';
import '../../data/services/clash_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/live_streaming_provider.dart';
import '../../providers/navigation_provider.dart';

class ClashesScreen extends StatefulWidget {
  const ClashesScreen({super.key});

  @override
  State<ClashesScreen> createState() => _ClashesScreenState();
}

class _ClashesScreenState extends State<ClashesScreen> {
  final _clashService = ClashService();
  List<dynamic> _schedule = [];
  bool _isLoading = true;
  Timer? _countdownTimer;
  int _selectedDayIndex = 0;
  late List<DateTime> _days;

  @override
  void initState() {
    super.initState();
    _buildDays();
    _loadSchedule();
    // Tick every second for live countdowns
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _buildDays() {
    final now = DateTime.now();
    _days = List.generate(7, (i) => DateTime(now.year, now.month, now.day + i));
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    try {
      final schedule = await _clashService.getSchedule();
      if (mounted) setState(() { _schedule = schedule; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _clashesForDay(DateTime day) {
    return _schedule.where((c) {
      final raw = c['scheduledAt'];
      if (raw == null) return c['status'] == 'active';
      final dt = DateTime.tryParse(raw.toString())?.toLocal();
      if (dt == null) return false;
      return dt.year == day.year && dt.month == day.month && dt.day == day.day;
    }).toList()
      ..sort((a, b) {
        final da = DateTime.tryParse(a['scheduledAt']?.toString() ?? '') ?? DateTime.now();
        final db = DateTime.tryParse(b['scheduledAt']?.toString() ?? '') ?? DateTime.now();
        return da.compareTo(db);
      });
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    if (d.day == now.day && d.month == now.month) return 'Today';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[d.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = _days[_selectedDayIndex];
    final dayClashes = _clashesForDay(selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clash Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () { setState(() => _isLoading = true); _loadSchedule(); },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showScheduleDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Schedule Clash', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.screenGradient),
        child: Column(
          children: [
            _buildDaySelector(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadSchedule,
                      child: dayClashes.isEmpty
                          ? _buildEmptyDay(selectedDay)
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                              itemCount: dayClashes.length,
                              itemBuilder: (context, i) => _buildClashCard(dayClashes[i]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _days.length,
        itemBuilder: (context, i) {
          final day = _days[i];
          final isSelected = i == _selectedDayIndex;
          final clashCount = _clashesForDay(day).length;
          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              width: 52,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayLabel(day),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.black : AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ),
                  if (clashCount > 0)
                    Container(
                      width: 5, height: 5,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black54 : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyDay(DateTime day) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        Center(
          child: Column(
            children: [
              Icon(Icons.bolt_outlined, size: 64, color: AppColors.muted),
              const SizedBox(height: 16),
              Text(
                'No clashes scheduled\nfor ${_dayLabel(day)}',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mutedForeground, fontSize: 16),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _showScheduleDialog,
                icon: const Icon(Icons.add),
                label: const Text('Schedule a Clash'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClashCard(dynamic clash) {
    final status = (clash['status'] ?? 'scheduled') as String;
    final scheduledAt = clash['scheduledAt'] != null
        ? DateTime.tryParse(clash['scheduledAt'].toString())?.toLocal()
        : null;
    final challenger = clash['challenger'];
    final opponent = clash['opponent'];
    final clashId = clash['_id']?.toString() ?? '';

    // Detect if the logged-in artist is a participant in this clash
    final myArtistId = context.read<AuthProvider>().user?['artistId']?.toString()
        ?? context.read<AuthProvider>().user?['_id']?.toString()
        ?? '';
    final challengerId = challenger?['_id']?.toString() ?? '';
    final opponentId = opponent?['_id']?.toString() ?? '';
    final isParticipant = myArtistId.isNotEmpty &&
        (myArtistId == challengerId || myArtistId == opponentId);

    final now = DateTime.now();
    final isLive = status == 'active';
    final minsUntil = scheduledAt != null ? scheduledAt.difference(now).inMinutes : null;
    final canJoin = isLive || (minsUntil != null && minsUntil <= 15 && minsUntil >= -5);

    String countdownStr = '';
    if (scheduledAt != null && !isLive) {
      final diff = scheduledAt.difference(now);
      if (diff.isNegative) {
        countdownStr = 'Started';
      } else if (diff.inHours >= 1) {
        countdownStr = '${diff.inHours}h ${diff.inMinutes % 60}m';
      } else if (diff.inMinutes >= 1) {
        countdownStr = '${diff.inMinutes}m ${diff.inSeconds % 60}s';
      } else {
        countdownStr = '${diff.inSeconds}s';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: NeumorphicTheme.neumorphicDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.card,
      ),
      child: Column(
        children: [
          // Status header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isLive
                  ? Colors.redAccent.withOpacity(0.15)
                  : canJoin
                      ? AppColors.primary.withOpacity(0.12)
                      : Colors.white.withOpacity(0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                if (isLive) ...[
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text('LIVE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                ] else ...[
                  Icon(Icons.schedule, size: 14, color: canJoin ? AppColors.primary : AppColors.mutedForeground),
                  const SizedBox(width: 6),
                  Text(
                    scheduledAt != null
                        ? '${_formatTime(scheduledAt)}${countdownStr.isNotEmpty ? '  ·  $countdownStr' : ''}'
                        : status.toUpperCase(),
                    style: TextStyle(
                      color: canJoin ? AppColors.primary : AppColors.mutedForeground,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const Spacer(),
                _statusBadge(status),
              ],
            ),
          ),

          // Artists
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(child: _buildArtistInfo(challenger, align: CrossAxisAlignment.start)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: isLive ? Colors.redAccent : AppColors.primary,
                    ),
                  ),
                ),
                Expanded(child: _buildArtistInfo(opponent, align: CrossAxisAlignment.end)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${((clash['duration'] ?? 1800) / 60).round()} min battle',
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
            ),
          ),

          // Action button: participant → Join / Watch Live for spectators
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: isParticipant
                // ── Participant: existing Join flow ──
                ? SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: canJoin ? () => _joinClash(clashId) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLive ? Colors.redAccent : AppColors.primary,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: AppColors.card,
                        disabledForegroundColor: AppColors.mutedForeground,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        isLive
                            ? '⚔️  Join Live Clash'
                            : canJoin
                                ? "✅  I'm Ready — Join"
                                : countdownStr.isNotEmpty
                                    ? 'Opens in $countdownStr'
                                    : 'Upcoming',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                // ── Non-participant: Watch Live (only if clash is active) ──
                : SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: isLive
                        ? ElevatedButton.icon(
                            onPressed: () => _watchLive(clashId),
                            icon: const Icon(Icons.play_circle_outline, size: 18),
                            label: const Text('Watch Live', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.mutedForeground,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              countdownStr.isNotEmpty ? 'Starts in $countdownStr' : 'Upcoming',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistInfo(dynamic artist, {required CrossAxisAlignment align}) {
    final name = (artist?['name'] ?? 'Unknown') as String;
    return Column(
      crossAxisAlignment: align,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primary.withOpacity(0.2),
          backgroundImage: artist?['image'] != null ? NetworkImage(artist['image'] as String) : null,
          child: artist?['image'] == null
              ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18))
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align == CrossAxisAlignment.start ? TextAlign.left : TextAlign.right,
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'active': color = Colors.redAccent; label = 'LIVE'; break;
      case 'accepted': color = Colors.orangeAccent; label = 'READY'; break;
      case 'scheduled': color = AppColors.primary; label = 'SCHEDULED'; break;
      default: color = AppColors.mutedForeground; label = status.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  Future<void> _joinClash(String clashId) async {
    try {
      await context.read<LiveStreamingProvider>().startClashStream(clashId);
      if (mounted) {
        context.read<NavigationProvider>().setIndex(3); // Navigate to Live tab
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚔️ Joined! You're in the clash arena."), backgroundColor: Colors.green),
        );
        _loadSchedule();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _watchLive(String clashId) async {
    final uri = Uri.parse('https://studio.lugmaticmusic.com/share/stream/$clashId');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open stream link'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showScheduleDialog() async {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 20, minute: 0);
    final opponentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('⚔️ Schedule a Clash'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: opponentController,
                  decoration: const InputDecoration(
                    hintText: 'Opponent Artist ID',
                    labelText: 'Opponent Artist ID',
                  ),
                ),
                const SizedBox(height: 16),
                Text('Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: TextStyle(color: AppColors.mutedForeground)),
                const SizedBox(height: 4),
                OutlinedButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (d != null) setDialogState(() => selectedDate = d);
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
                  child: const Text('Pick Date'),
                ),
                const SizedBox(height: 12),
                Text('Time: ${selectedTime.format(context)}',
                    style: TextStyle(color: AppColors.mutedForeground)),
                const SizedBox(height: 4),
                OutlinedButton(
                  onPressed: () async {
                    final t = await showTimePicker(context: context, initialTime: selectedTime);
                    if (t != null) setDialogState(() => selectedTime = t);
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
                  child: const Text('Pick Time'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (opponentController.text.isEmpty) return;
                final scheduledAt = DateTime(
                  selectedDate.year, selectedDate.month, selectedDate.day,
                  selectedTime.hour, selectedTime.minute,
                );
                try {
                  await _clashService.scheduleClash(
                    opponentArtistId: opponentController.text.trim(),
                    scheduledAt: scheduledAt,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadSchedule();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Clash scheduled! Both artists notified.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceAll('Exception:', '').trim()),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
              child: const Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    opponentController.dispose();
  }
}
