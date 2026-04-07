import 'package:flutter/foundation.dart';
import '../data/models/track_model.dart';
import '../data/services/track_service.dart';

class TrackProvider extends ChangeNotifier {
  final TrackService _service = TrackService();

  List<Track> _tracks = [];
  TrackAnalytics? _selectedTrackAnalytics;
  bool _isLoading = false;
  String? _error;

  List<Track> get tracks => _tracks;
  TrackAnalytics? get selectedTrackAnalytics => _selectedTrackAnalytics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTracks(String artistId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tracks = await _service.getArtistTracks(artistId);
    } catch (e) {
      _error = 'Failed to load tracks: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTrackAnalytics(String trackId, {int days = 30}) async {
    _isLoading = true;
    _error = null;
    _selectedTrackAnalytics = null;
    notifyListeners();

    try {
      _selectedTrackAnalytics = await _service.getTrackAnalytics(trackId, days: days);
    } catch (e) {
      _error = 'Failed to load analytics: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTrack(String trackId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _service.deleteTrack(trackId);
      if (success) {
        _tracks.removeWhere((t) => t.id == trackId);
      }
      return success;
    } catch (e) {
      _error = 'Failed to delete track: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
