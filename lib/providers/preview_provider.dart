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
    _preview = null;
    notifyListeners();

    try {
      final result = await api.fetchPreview(request); // PreviewResponse

      // 여기까지 왔으면 파싱 에러는 없는 것. 그대로 저장
      _preview = result;

      // 만약 엔진/내레이션이 비어 있고 needs_review 플래그가 true 라면
      // 백엔드 쪽 LLM 문제가 있었다는 뜻이니 메시지만 따로 세팅
      if (result.narration == null &&
          (result.flags.llmError != null || result.flags.needsReview)) {
        _errorMessage =
        'AI 쪽에서 규정 설명을 만들지 못했어요.\n잠시 후 다시 시도해 주세요.';
      }
    } catch (e, _) {
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
