// lib/providers/preview_provider.dart
import 'package:flutter/foundation.dart';

import '../models/preview_request.dart';
import '../models/preview_response.dart';
import '../service/preview_api.dart';

class PreviewProvider with ChangeNotifier {
  final PreviewApiService api;

  PreviewProvider({required this.api});

  PreviewResponse? _preview;
  bool _isLoading = false;
  String? _errorMessage;

  PreviewResponse? get preview => _preview;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPreview(PreviewRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await api.fetchPreview(request);
      _preview = result;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _preview = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
