import 'package:flutter/foundation.dart';
import '../data/services/podcast_service.dart';

class PodcastProvider extends ChangeNotifier {
  final PodcastService _service = PodcastService();

  List<dynamic> _podcasts = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get podcasts => _podcasts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPodcasts(String artistId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _podcasts = await _service.getArtistPodcasts(artistId);
    } catch (e) {
      _error = 'Failed to load podcasts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePodcast(String id) async {
    try {
      final success = await _service.deletePodcast(id);
      if (success) {
        _podcasts.removeWhere((p) => p['_id'] == id);
        notifyListeners();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<void> togglePublish(String id, bool currentStatus) async {
    try {
      final success = await _service.togglePublishStatus(id, !currentStatus);
      if (success) {
        final index = _podcasts.indexWhere((p) => p['_id'] == id);
        if (index != -1) {
          _podcasts[index]['isPublished'] = !currentStatus;
          notifyListeners();
        }
      }
    } catch (e) {
      // Handle error
    }
  }
}
