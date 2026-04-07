class Track {
  final String id;
  final String name;
  final String? coverArt;
  final String? coverArtUrl;
  final String status;
  final int playCount;
  final String? uploadSource;
  final DateTime createdAt;

  Track({
    required this.id,
    required this.name,
    this.coverArt,
    this.coverArtUrl,
    required this.status,
    required this.playCount,
    this.uploadSource,
    required this.createdAt,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown Track',
      coverArt: json['coverArt'],
      coverArtUrl: json['coverArtUrl'],
      status: json['status'] ?? 'pending',
      playCount: json['playCount'] ?? 0,
      uploadSource: json['uploadSource'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class DailyStat {
  final String date;
  final int plays;

  DailyStat({required this.date, required this.plays});

  factory DailyStat.fromJson(Map<String, dynamic> json) {
    return DailyStat(
      date: json['date'] ?? '',
      plays: json['plays'] ?? 0,
    );
  }
}

class DeviceStat {
  final String device;
  final int count;

  DeviceStat({required this.device, required this.count});

  factory DeviceStat.fromJson(Map<String, dynamic> json) {
    return DeviceStat(
      device: json['device'] ?? 'Unknown',
      count: json['count'] ?? 0,
    );
  }
}

class TrackAnalytics {
  final int totalPlays;
  final List<DailyStat> dailyStats;
  final List<DeviceStat> deviceStats;
  final int period;

  TrackAnalytics({
    required this.totalPlays,
    required this.dailyStats,
    required this.deviceStats,
    required this.period,
  });

  factory TrackAnalytics.fromJson(Map<String, dynamic> json) {
    var dailyList = json['dailyStats'] as List? ?? [];
    var deviceList = json['deviceStats'] as List? ?? [];

    return TrackAnalytics(
      totalPlays: json['totalPlays'] ?? 0,
      dailyStats: dailyList.map((i) => DailyStat.fromJson(i)).toList(),
      deviceStats: deviceList.map((i) => DeviceStat.fromJson(i)).toList(),
      period: json['period'] ?? 30,
    );
  }
}
