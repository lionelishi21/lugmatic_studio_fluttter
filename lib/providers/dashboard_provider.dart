import 'package:flutter/foundation.dart';
import '../data/models/dashboard_models.dart';
import '../data/services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _service = DashboardService();

  bool _isLoading = false;
  String? _error;
  
  ArtistDetails? _artistDetails;
  ArtistStats? _artistStats;
  ArtistEarnings? _artistEarnings;

  bool get isLoading => _isLoading;
  String? get error => _error;
  ArtistDetails? get artistDetails => _artistDetails;
  ArtistStats? get artistStats => _artistStats;
  ArtistEarnings? get artistEarnings => _artistEarnings;

  Future<void> fetchDashboardData(String artistId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getArtistDetails(artistId),
        _service.getArtistStats(artistId),
        _service.getArtistEarnings(),
      ]);

      _artistDetails = results[0] as ArtistDetails;
      _artistStats = results[1] as ArtistStats;
      _artistEarnings = results[2] as ArtistEarnings;
    } catch (e) {
      _error = 'Failed to load dashboard data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
