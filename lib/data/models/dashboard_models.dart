class ArtistStats {
  final int totalTracks;
  final int monthlyListeners;
  final int socialMediaFollowers;
  final int totalPlays;

  ArtistStats({
    required this.totalTracks,
    required this.monthlyListeners,
    required this.socialMediaFollowers,
    required this.totalPlays,
  });

  factory ArtistStats.fromJson(Map<String, dynamic> json) {
    return ArtistStats(
      totalTracks: json['totalTracks'] ?? 0,
      monthlyListeners: json['monthlyListeners'] ?? 0,
      socialMediaFollowers: json['socialMediaFollowers'] ?? 0,
      totalPlays: json['totalPlays'] ?? 0,
    );
  }
}

class Transaction {
  final String id;
  final String type;
  final double amount;
  final String currency;
  final String status;
  final String description;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.status,
    required this.description,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      status: json['status'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class ArtistEarnings {
  final double totalEarnings;
  final double monthlyEarnings;
  final List<Transaction> history;

  ArtistEarnings({
    required this.totalEarnings,
    required this.monthlyEarnings,
    required this.history,
  });

  factory ArtistEarnings.fromJson(Map<String, dynamic> json) {
    var historyList = json['history'] as List? ?? [];
    List<Transaction> history = historyList.map((i) => Transaction.fromJson(i)).toList();

    return ArtistEarnings(
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      monthlyEarnings: (json['monthlyEarnings'] ?? 0).toDouble(),
      history: history,
    );
  }
}

class ArtistDetails {
  final String id;
  final String name;
  final String? profilePicture;
  final String? image;

  ArtistDetails({
    required this.id,
    required this.name,
    this.profilePicture,
    this.image,
  });

  factory ArtistDetails.fromJson(Map<String, dynamic> json) {
    return ArtistDetails(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Artist',
      profilePicture: json['profilePicture'],
      image: json['image'],
    );
  }
}
