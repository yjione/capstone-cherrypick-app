// lib/widgets/yolo_scanner.dart
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/device_provider.dart';
import '../providers/trip_provider.dart';
import '../service/detect_api.dart';
import '../service/rules_api.dart';
import '../models/preview_request.dart';
import '../screens/rules_check_result_screen.dart';

/// YOLO 기반 실시간 스캔 위젯
/// 
/// 플로우:
/// 1. 초기 화면: 제목, 카메라 아이콘, [카메라 촬영], [사진 업로드]
/// 2. 카메라 촬영 클릭 -> 카메라 프리뷰 + 주기적 이미지 전송 시작
/// 3. 서버에서 라벨 리스트 받아서 하단에 표시 (누적)
/// 4. [스캔 멈추기] 클릭 -> 카메라 종료, 라벨 편집 화면
/// 5. 라벨 수정/삭제 후 [규정 확인하기] 버튼으로 다음 단계
class YoloScanner extends StatefulWidget {
  const YoloScanner({super.key});

  @override
  State<YoloScanner> createState() => _YoloScannerState();
}

enum ScanState {
  idle, // 초기 상태
  scanning, // 스캔 중 (카메라 프리뷰 + 주기적 전송)
  stopped, // 스캔 멈춤 (라벨 편집 가능)
}

class _YoloScannerState extends State<YoloScanner> {
  // 상태 관리
  ScanState _state = ScanState.idle;
  
  // 카메라 관련
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  
  // 스캔 관련
  Timer? _scanTimer; // 주기적 이미지 전송을 위한 타이머
  final DetectApiService _detectApi = DetectApiService();
  final RulesApiService _rulesApi = RulesApiService();
  final Set<String> _labelsSeen = {}; // 이미 본 라벨들 (중복 방지)
  final List<String> _labels = []; // 현재까지 인식된 라벨 리스트
  bool _isDetecting = false; // 현재 전송 중인지 (중복 방지)
  bool _isCheckingRules = false; // 규정 확인 중인지
  
  // 라벨 편집 관련
  final Map<String, TextEditingController> _labelControllers = {};
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
    // initState에서 직접 호출하지 말고 WidgetsBinding.instance.addPostFrameCallback 사용
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureDeviceRegistered();
    });
  }

  /// 디바이스 등록 확인 및 등록 시도
  Future<void> _ensureDeviceRegistered() async {
    if (!mounted) return;
    
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    
    // 저장된 정보 로드
    await deviceProvider.loadFromStorage();
    
    // 이미 등록되어 있으면 종료
    if (deviceProvider.deviceToken != null && deviceProvider.deviceUuid != null) {
      debugPrint('✅ 디바이스 이미 등록됨: ${deviceProvider.deviceUuid}');
      return;
    }
    
    debugPrint('🔧 디바이스 등록 시작...');
    
    // 등록 시도
    // deviceUuid는 고정값 사용 (같은 에뮬레이터에서는 같은 UUID 사용)
    final deviceUuid = deviceProvider.deviceUuid ?? 'android-emulator-${DateTime.now().millisecondsSinceEpoch}';
    
    await deviceProvider.registerIfNeeded(
      appVersion: '1.0.0',
      os: 'android',
      model: 'test-device',
      locale: 'ko-KR',
      timezone: '+09:00',
      deviceUuid: deviceUuid,
    );
    
    // 등록 결과 확인
    if (deviceProvider.deviceToken != null) {
      debugPrint('✅ 디바이스 등록 완료: ${deviceProvider.deviceUuid}');
    } else {
      debugPrint('❌ 디바이스 등록 실패: ${deviceProvider.error}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('디바이스 등록 실패: ${deviceProvider.error ?? "서버 연결 실패"}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _stopScanning();
    _cameraController?.dispose();
    // 라벨 편집 컨트롤러들도 정리
    for (var controller in _labelControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// 카메라 초기화
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras!.first,
          ResolutionPreset.medium, // medium으로 설정 (고해상도는 너무 무거울 수 있음)
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('카메라 초기화 실패: $e');
      // 카메라가 없어도 사진 업로드는 가능하므로 계속 진행
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tripProvider = context.watch<TripProvider>();
    final currentTrip = tripProvider.currentTrip;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: "물품 스캔" 제목
          Center(
            child: Column(
              children: [
                const Text(
                  '물품 스캔',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (currentTrip != null)
                  Text(
                    '${currentTrip.name} 기준',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 상태에 따라 다른 UI 표시
          if (_state == ScanState.idle) _buildStartOptions(),
          if (_state == ScanState.scanning) _buildCameraView(),
          if (_state == ScanState.stopped) _buildLabelEditView(),
        ],
      ),
    );
  }

  /// 1단계: 초기 화면 (제목, 카메라 아이콘, 버튼들)
  Widget _buildStartOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // 카메라 아이콘
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.camera_alt,
                size: 32,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            // [카메라 촬영] 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startScanning,
                icon: const Icon(Icons.camera_alt),
                label: const Text('카메라 촬영'),
              ),
            ),
            const SizedBox(height: 12),
            // [사진 업로드] 버튼
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.upload),
                label: const Text('사진 업로드'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 2단계: 카메라 프리뷰 화면 (스캔 중)
  Widget _buildCameraView() {
    return Column(
      children: [
        // 상단: 카메라 프리뷰
        Card(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: _isCameraInitialized && _cameraController != null
                  ? CameraPreview(_cameraController!)
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // 하단: 스캔 멈추기 버튼 + 라벨 리스트
        Row(
          children: [
            // 좌측: [스캔 멈추기] 버튼
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _stopScanning,
                icon: const Icon(Icons.stop),
                label: const Text('스캔 멈추기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // 현재까지 인식된 라벨 리스트 영역
        if (_labels.isNotEmpty) ...[
          const Text(
            '인식된 물품',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _labels.map((label) {
              return Chip(
                label: Text(label),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  /// 3단계: 라벨 편집 화면 (스캔 멈춤 후)
  Widget _buildLabelEditView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '인식된 물품 목록',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '라벨을 수정하거나 삭제할 수 있습니다.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        
        // 라벨 리스트 (편집 가능)
        if (_labels.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('인식된 물품이 없습니다.'),
            ),
          )
        else
          ..._labels.asMap().entries.map((entry) {
            final index = entry.key;
            final label = entry.value;
            
            // 각 라벨마다 TextEditingController 생성 (아직 없으면)
            if (!_labelControllers.containsKey(label)) {
              _labelControllers[label] = TextEditingController(text: label);
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  // 라벨 편집 필드
                  Expanded(
                    child: TextField(
                      controller: _labelControllers[label],
                      decoration: InputDecoration(
                        labelText: '물품 이름',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => _removeLabel(index),
                          tooltip: '삭제',
                        ),
                      ),
                      onChanged: (value) {
                        // 실시간으로 라벨 업데이트 (나중에 저장 버튼 누를 때 반영)
                        if (value.isNotEmpty) {
                          _labels[index] = value;
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        
        const SizedBox(height: 16),
        
        // 수동으로 라벨 추가 버튼 (선택사항)
        OutlinedButton.icon(
          onPressed: _addManualLabel,
          icon: const Icon(Icons.add),
          label: const Text('라벨 추가'),
        ),
        
        const SizedBox(height: 24),
        
        // [규정 확인하기] 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_labels.isEmpty || _isCheckingRules)
                ? null
                : _checkRegulations,
            icon: _isCheckingRules
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle),
            label: Text(_isCheckingRules ? '확인 중...' : '규정 확인하기'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  /// [카메라 촬영] 버튼 클릭 시
  Future<void> _startScanning() async {
    // 카메라가 초기화되지 않았으면 초기화 시도
    if (!_isCameraInitialized) {
      await _initializeCamera();
    }
    
    if (_cameraController == null || !_isCameraInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카메라를 사용할 수 없습니다.')),
      );
      return;
    }

    setState(() {
      _state = ScanState.scanning;
      _labels.clear();
      _labelsSeen.clear();
    });

    // 주기적 이미지 전송 시작 (0.5초 간격)
    _startPeriodicDetection();
  }

  /// 주기적으로 이미지를 서버에 전송하여 물체 감지
  void _startPeriodicDetection() {
    // 기존 타이머가 있으면 취소
    _scanTimer?.cancel();
    
    // 0.5초마다 실행
    _scanTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_state != ScanState.scanning) {
        timer.cancel();
        return;
      }
      
      // 이미 전송 중이면 스킵 (중복 방지)
      if (_isDetecting) {
        return;
      }
      
      _captureAndDetect();
    });
  }

  /// 카메라 프레임을 캡처하고 서버에 전송하여 물체 감지
  Future<void> _captureAndDetect() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_isDetecting) {
      return; // 이미 전송 중
    }

    setState(() {
      _isDetecting = true;
    });

    try {
      // 카메라에서 이미지 캡처
      final image = await _cameraController!.takePicture();
      
      // 이미지 파일을 바이트로 읽기
      final imageFile = File(image.path);
      final imageBytes = await imageFile.readAsBytes();
      
      // 디바이스 정보 가져오기
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      
      var deviceUuid = deviceProvider.deviceUuid;
      var deviceToken = deviceProvider.deviceToken;
      
      if (deviceUuid == null || deviceToken == null) {
        debugPrint('❌ 디바이스가 등록되지 않았습니다. 등록 시도 중...');
        // 등록 시도
        await _ensureDeviceRegistered();
        
        // 다시 확인
        deviceUuid = deviceProvider.deviceUuid;
        deviceToken = deviceProvider.deviceToken;
        
        if (deviceUuid == null || deviceToken == null) {
          debugPrint('❌ 디바이스 등록 실패: ${deviceProvider.error}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('디바이스 등록 실패. 서버 연결을 확인하세요.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }
      
      // 서버에 전송하여 물체 감지
      final response = await _detectApi.detectObjectsFromBytes(
        imageBytes,
        fileName: 'frame.jpg',
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
      );
      
      // 새로 감지된 라벨만 추가 (중복 방지)
      // 다이어그램에 맞춰 display와 count를 포함한 형식으로 받음
      for (final detectedLabel in response.labels) {
        final label = detectedLabel.display; // 한국어 표시명 사용
        if (!_labelsSeen.contains(label)) {
          _labelsSeen.add(label);
          if (mounted) {
            setState(() {
              _labels.add(label);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('물체 감지 실패: $e');
      // 에러가 나도 계속 스캔은 진행
    } finally {
      if (mounted) {
        setState(() {
          _isDetecting = false;
        });
      }
    }
  }

  /// [스캔 멈추기] 버튼 클릭 시
  void _stopScanning() {
    // 타이머 중지
    _scanTimer?.cancel();
    _scanTimer = null;
    
    // 카메라 종료는 하지 않음 (다시 시작할 수도 있으므로)
    // 대신 상태만 변경
    
    setState(() {
      _state = ScanState.stopped;
      _isDetecting = false;
    });
  }

  /// [사진 업로드] 버튼 클릭 시
  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) {
      return;
    }

    // 단일 이미지로 물체 감지
    setState(() {
      _state = ScanState.scanning;
      _labels.clear();
      _labelsSeen.clear();
    });

    try {
      final imageFile = File(image.path);
      final imageBytes = await imageFile.readAsBytes();
      
      // 디바이스 정보 가져오기
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      var deviceUuid = deviceProvider.deviceUuid;
      var deviceToken = deviceProvider.deviceToken;
      
      if (deviceUuid == null || deviceToken == null) {
        debugPrint('❌ 디바이스가 등록되지 않았습니다. 등록 시도 중...');
        // 등록 시도
        await _ensureDeviceRegistered();
        
        // 다시 확인
        deviceUuid = deviceProvider.deviceUuid;
        deviceToken = deviceProvider.deviceToken;
        
        if (deviceUuid == null || deviceToken == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('디바이스 등록 실패. 서버 연결을 확인하세요.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _state = ScanState.idle;
          });
          return;
        }
      }
      
      final response = await _detectApi.detectObjectsFromBytes(
        imageBytes,
        fileName: image.name,
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
      );
      
      setState(() {
        // 다이어그램에 맞춰 display와 count를 포함한 형식으로 받음
        for (final detectedLabel in response.labels) {
          final label = detectedLabel.display; // 한국어 표시명 사용
          if (!_labelsSeen.contains(label)) {
            _labelsSeen.add(label);
            _labels.add(label);
          }
        }
        _state = ScanState.stopped; // 바로 편집 화면으로
      });
    } catch (e) {
      debugPrint('이미지 감지 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 분석 실패: $e')),
      );
      setState(() {
        _state = ScanState.idle;
      });
    }
  }

  /// 라벨 삭제
  void _removeLabel(int index) {
    final label = _labels[index];
    _labelsSeen.remove(label);
    _labels.removeAt(index);
    
    // 컨트롤러도 정리
    _labelControllers[label]?.dispose();
    _labelControllers.remove(label);
    
    setState(() {});
  }

  /// 수동으로 라벨 추가
  void _addManualLabel() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('라벨 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '물품 이름',
            hintText: '예: 칫솔, 샴푸',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final label = controller.text.trim();
              if (label.isNotEmpty && !_labelsSeen.contains(label)) {
                _labelsSeen.add(label);
                _labels.add(label);
                _labelControllers[label] = TextEditingController(text: label);
                setState(() {});
              }
              Navigator.pop(context);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  /// [규정 확인하기] 버튼 클릭 시
  Future<void> _checkRegulations() async {
    if (_labels.isEmpty) {
      return;
    }

    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final currentTrip = tripProvider.currentTrip;

    if (currentTrip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 여행 정보를 설정해 주세요.')),
      );
      return;
    }

    setState(() {
      _isCheckingRules = true;
    });

    try {
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      final deviceToken = deviceProvider.deviceToken;

      // 여정 정보 생성 (Trip에서 추출)
      // 목적지에서 공항 코드 추출 (예: "일본 나리타(NRT)" -> "NRT")
      String extractAirportCode(String destination) {
        final start = destination.indexOf('(');
        final end = destination.indexOf(')');
        if (start != -1 && end != -1 && end > start + 1) {
          final inside = destination.substring(start + 1, end).trim();
          if (inside.length == 3) {
            return inside.toUpperCase();
          }
        }
        // 기본값
        return 'ICN';
      }

      const fromAirport = 'ICN'; // 출발지는 인천으로 가정
      final toAirport = extractAirportCode(currentTrip.destination);
      const airlineCode = 'KE'; // 기본값
      const cabinClass = 'economy'; // 기본값

      final itinerary = Itinerary(
        from: fromAirport,
        to: toAirport,
        via: const [],
        rescreening: false,
      );

      final segments = [
        Segment(
          leg: '$fromAirport-$toAirport',
          operating: airlineCode,
          cabinClass: cabinClass,
        ),
      ];

      // 디바이스 정보 가져오기
      final deviceUuid = deviceProvider.deviceUuid;
      
      if (deviceUuid == null || deviceToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('디바이스가 등록되지 않았습니다.')),
          );
        }
        setState(() {
          _isCheckingRules = false;
        });
        return;
      }
      
      // 규정 확인 API 호출
      final response = await _rulesApi.checkRules(
        labels: _labels,
        itinerary: itinerary,
        segments: segments,
        locale: 'ko-KR',
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
      );

      if (!mounted) return;

      // 결과 화면으로 이동
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RulesCheckResultScreen(
            results: response.results,
            tripName: currentTrip.name,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('규정 확인 중 오류가 발생했습니다: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingRules = false;
        });
      }
    }
  }
}

