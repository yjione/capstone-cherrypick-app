// lib/service/detect_api.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// 감지된 물체 정보
class DetectedLabel {
  final String display; // 한국어 표시명 (예: "헤어 스프레이", "보조배터리")
  final int count; // 감지된 개수

  DetectedLabel({required this.display, required this.count});

  factory DetectedLabel.fromJson(Map<String, dynamic> json) {
    return DetectedLabel(
      display: json['display'] as String? ?? '',
      count: json['count'] as int? ?? 1,
    );
  }
}

/// Object Detection API 응답 모델
/// 
/// 다이어그램에 맞춰 display와 count를 포함한 형식
/// 예: {"labels": [{"display": "헤어 스프레이", "count": 2}, {"display": "보조배터리", "count": 1}]}
class DetectResponse {
  final List<DetectedLabel> labels;

  DetectResponse({required this.labels});

  factory DetectResponse.fromJson(Map<String, dynamic> json) {
    return DetectResponse(
      labels: (json['labels'] as List<dynamic>?)
              ?.map((e) => DetectedLabel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
  
  /// 호환성을 위해 라벨 이름 리스트만 반환 (기존 코드와의 호환)
  List<String> get labelNames => labels.map((l) => l.display).toList();
}

/// Object Detection API 서비스
/// 
/// 백엔드의 `/v1/detect` API를 호출하여 이미지에서 물체를 감지합니다.
/// 
/// 사용 예시:
/// ```dart
/// final api = DetectApiService();
/// final imageFile = File('path/to/image.jpg');
/// final response = await api.detectObjects(imageFile, deviceToken: 'token');
/// print(response.labels); // ['toothbrush', 'bottle', ...]
/// ```
class DetectApiService {
  // 백엔드 base URL
  // Android 에뮬레이터에서 로컬 서버 접근: 10.0.2.2
  static const String _baseUrl = 'http://10.0.2.2:8001';

  /// 이미지에서 물체를 감지합니다.
  /// 
  /// [imageFile]: 감지할 이미지 파일
  /// [deviceUuid]: 디바이스 UUID (필수)
  /// [deviceToken]: 디바이스 인증 토큰 (필수)
  /// 
  /// Returns: 감지된 라벨 리스트가 포함된 DetectResponse
  /// 
  /// Throws: Exception (네트워크 오류, 서버 오류 등)
  Future<DetectResponse> detectObjects(
    File imageFile, {
    required String deviceUuid,
    required String deviceToken,
  }) async {
    final url = Uri.parse('$_baseUrl/v1/detect');

    // multipart/form-data 요청 생성
    final request = http.MultipartRequest('POST', url);

    // 헤더 설정 (백엔드 인증 필수)
    request.headers['Accept'] = 'application/json';
    request.headers['X-Device-UUID'] = deviceUuid;
    request.headers['X-Device-Token'] = deviceToken;

    // 이미지 파일 추가
    // 파일명에서 확장자 추출하여 content-type 설정
    final fileName = imageFile.path.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();
    final contentType = _getContentType(extension);

    request.files.add(
      await http.MultipartFile.fromPath(
        'file', // 백엔드에서 기대하는 필드명
        imageFile.path,
        filename: fileName,
        contentType: contentType,
      ),
    );

    try {
      // 요청 전송
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // 응답 처리
      if (response.statusCode != 200) {
        throw Exception(
          'Detect API failed: ${response.statusCode} ${response.body}',
        );
      }

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      return DetectResponse.fromJson(body);
    } catch (e) {
      throw Exception('Failed to detect objects: $e');
    }
  }

  /// 이미지 바이트 데이터에서 물체를 감지합니다.
  /// 
  /// 카메라 프리뷰에서 직접 캡처한 이미지 바이트를 전송할 때 사용합니다.
  /// 
  /// [imageBytes]: 이미지 바이트 데이터
  /// [fileName]: 파일명 (예: "frame.jpg")
  /// [deviceUuid]: 디바이스 UUID (필수)
  /// [deviceToken]: 디바이스 인증 토큰 (필수)
  /// 
  /// Returns: 감지된 라벨 리스트가 포함된 DetectResponse
  Future<DetectResponse> detectObjectsFromBytes(
    List<int> imageBytes, {
    String fileName = 'frame.jpg',
    required String deviceUuid,
    required String deviceToken,
  }) async {
    final url = Uri.parse('$_baseUrl/v1/detect');

    final request = http.MultipartRequest('POST', url);

    // 헤더 설정 (백엔드 인증 필수)
    request.headers['Accept'] = 'application/json';
    request.headers['X-Device-UUID'] = deviceUuid;
    request.headers['X-Device-Token'] = deviceToken;

    // 바이트 데이터를 multipart file로 변환
    final extension = fileName.split('.').last.toLowerCase();
    final contentType = _getContentType(extension);

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
        contentType: contentType,
      ),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception(
          'Detect API failed: ${response.statusCode} ${response.body}',
        );
      }

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      return DetectResponse.fromJson(body);
    } catch (e) {
      throw Exception('Failed to detect objects: $e');
    }
  }

  /// 파일 확장자로부터 Content-Type을 반환합니다.
  MediaType _getContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      default:
        return MediaType('image', 'jpeg'); // 기본값
    }
  }
}

