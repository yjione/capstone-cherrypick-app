import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:camera/camera.dart';
import 'package:provider/provider.dart';

import '../providers/trip_provider.dart';

// Preview API 관련
import '../providers/preview_provider.dart';
import '../models/preview_request.dart';
import '../screens/item_preview_screen.dart';

class ItemScanner extends StatefulWidget {
  const ItemScanner({super.key});

  @override
  State<ItemScanner> createState() => _ItemScannerState();
}

class _ItemScannerState extends State<ItemScanner> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraActive = false;
  bool _isScanning = false;
  bool _isPreviewLoading = false; // Preview API 로딩 상태

  XFile? _selectedImage;
  ScanResult? _scanResult;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras(); // 웹/모바일 공통
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras!.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (!mounted) return;
        setState(() {});
      }
    } catch (e) {
      debugPrint('카메라 초기화 실패: $e');
      // 웹에서 권한 거부, 디바이스 없음 등 다양한 경우가 있으므로 UI는 계속 표시
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final currentTrip = tripProvider.currentTrip;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (!_isCameraActive && _selectedImage == null) _buildStartOptions(),
          if (_isCameraActive) _buildCameraView(),
          if (_selectedImage != null) _buildImagePreview(),
        ],
      ),
    );
  }

  Widget _buildStartOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
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
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _startCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('카메라 촬영'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.upload),
                    label: const Text('사진 업로드'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 300,
                width: double.infinity,
                child: Stack(
                  children: [
                    CameraPreview(_cameraController!),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    if (kIsWeb)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '브라우저 권한 팝업을 허용하세요',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _capturePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('촬영하기'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _stopCamera,
                    icon: const Icon(Icons.close),
                    label: const Text('취소'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: FutureBuilder<Uint8List>(
                  future: _selectedImage!.readAsBytes(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Image.memory(snap.data!, fit: BoxFit.cover);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isScanning) _buildScanningIndicator(),
            if (_scanResult != null) _buildScanResult(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _scanResult != null ? _addToPackingList : null,
                    child: const Text('짐 리스트에 추가'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetScan,
                    child: const Text('다시 스캔'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningIndicator() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'AI가 물품을 분석하고 있어요...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: 0.75,
          backgroundColor:
          Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ],
    );
  }

  Widget _buildScanResult() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '스캔 결과',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '정확도 ${_scanResult!.confidence}%',
                style: TextStyle(
                  fontSize: 12,
                  color:
                  Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),

        // Preview API 로딩 상태 표시
        if (_isPreviewLoading) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                '상세 판정 불러오는 중...',
                style: TextStyle(
                  fontSize: 12,
                  color:
                  Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _scanResult!.item,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _scanResult!.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_scanResult!.volume != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '용량: ${_scanResult!.volume}',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
                if (_scanResult!.weight != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '용량: ${_scanResult!.weight}',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildLuggageStatus(
                        '기내 수하물',
                        _scanResult!.carryOnAllowed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildLuggageStatus(
                        '위탁 수하물',
                        _scanResult!.checkedAllowed,
                      ),
                    ),
                  ],
                ),

                if (_scanResult!.restrictions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 16,
                        color: Colors.amber,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '주의사항',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._scanResult!.restrictions.map(
                        (restriction) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 6, right: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              restriction,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // 🔹 여기서 Preview API 호출 버튼
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                    _isPreviewLoading ? null : _openPreviewForScanResult,
                    icon: const Icon(Icons.info_outline),
                    label: const Text('상세 판정 보기'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLuggageStatus(String title, bool allowed) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: allowed ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(
          color: allowed ? Colors.green.shade200 : Colors.red.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            allowed ? Icons.check_circle : Icons.cancel,
            color: allowed ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            allowed ? '허용' : '불가',
            style: TextStyle(
              fontSize: 10,
              color: allowed
                  ? Colors.green.shade700
                  : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startCamera() async {
    if (_cameraController == null) {
      await _initializeCamera();
    }
    if (_cameraController != null &&
        _cameraController!.value.isInitialized) {
      setState(() {
        _isCameraActive = true;
      });
    }
  }

  void _stopCamera() {
    setState(() {
      _isCameraActive = false;
    });
  }

  Future<void> _capturePhoto() async {
    if (_cameraController != null &&
        _cameraController!.value.isInitialized) {
      final image = await _cameraController!.takePicture();
      setState(() {
        _selectedImage = image;
        _isCameraActive = false;
      });
      _simulateScan();
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
      _simulateScan();
    }
  }

  Future<void> _simulateScan() async {
    setState(() {
      _isScanning = true;
      _scanResult = null;
    });

    // 실제 구현에서는 AI/Preview API + 이미지 분석 연동 예정
    await Future.delayed(const Duration(seconds: 2));

    // 모의 결과 데이터
    final mockResults = [
      ScanResult(
        item: "화장품 (토너)",
        category: "액체류",
        volume: "150ml",
        carryOnAllowed: true,
        checkedAllowed: true,
        restrictions: ["100ml 이하 용기에 담아야 함", "투명 지퍼백에 보관"],
        confidence: 92,
      ),
      ScanResult(
        item: "보조배터리",
        category: "전자기기",
        weight: "20,000mAh",
        carryOnAllowed: true,
        checkedAllowed: false,
        restrictions: ["기내 수하물만 가능", "100Wh 이하만 허용"],
        confidence: 88,
      ),
      ScanResult(
        item: "헤어드라이어",
        category: "전자기기",
        carryOnAllowed: true,
        checkedAllowed: true,
        restrictions: ["전압 확인 필요", "플러그 어댑터 준비"],
        confidence: 95,
      ),
    ];

    setState(() {
      _scanResult =
      mockResults[DateTime.now().millisecondsSinceEpoch % mockResults.length];
      _isScanning = false;
    });
  }

  void _resetScan() {
    setState(() {
      _selectedImage = null;
      _scanResult = null;
      _isScanning = false;
      _isPreviewLoading = false;
    });
  }

  void _addToPackingList() {
    // TODO: 나중에 PackingProvider랑 실제 연동 (현재 Trip 기준으로 추가)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('짐 리스트에 추가되었습니다')),
    );
  }

  // =========================================================
  // 여기부터 Preview API 연동 부분
  // =========================================================

  Future<void> _openPreviewForScanResult() async {
    if (_scanResult == null) return;

    final tripProvider = context.read<TripProvider>();
    final currentTrip = tripProvider.currentTrip;

    if (currentTrip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 여행 정보를 설정해 주세요.')),
      );
      return;
    }

    setState(() {
      _isPreviewLoading = true;
    });

    try {
      final previewProvider = context.read<PreviewProvider>();

      // 목적지 공항 코드 추출 (Trip.destination에서 괄호 안 코드 뽑기 시도)
      // 예: "일본 나리타(NRT)" → "NRT"
      String extractAirportCode(String destination) {
        final start = destination.indexOf('(');
        final end = destination.indexOf(')');

        if (start != -1 && end != -1 && end > start + 1) {
          final inside = destination.substring(start + 1, end).trim();
          final isCode = inside.length == 3 &&
              RegExp(r'^[A-Za-z]+$').hasMatch(inside);
          if (isCode) return inside.toUpperCase();
        }

        // 괄호가 없으면 앞 3글자 정도를 코드처럼 사용하는 임시 로직
        final trimmed = destination.trim();
        if (trimmed.length >= 3) {
          return trimmed.substring(0, 3).toUpperCase();
        }
        // 완전 없으면 그냥 NRT 같은 기본값 사용 (임시)
        return 'NRT';
      }

      // 좌석 등급/항공사 정보는 아직 Trip에 없으므로 임시값 사용
      const fromAirport = 'ICN';
      final toAirport = extractAirportCode(currentTrip.destination);
      const airlineCode = 'KE'; // TODO: Trip에 항공사 필드 추가 후 교체
      const cabinClass = 'economy'; // TODO: Trip에 좌석 등급 필드 추가 후 교체

      // 아이템 정보도 아직 구조화 안되어 있으니 대략적인 값 사용
      final request = PreviewRequest(
        label: _scanResult!.item, // 스캔된 아이템 이름
        locale: 'ko-KR',
        reqId: DateTime.now().millisecondsSinceEpoch.toString(),
        itinerary: Itinerary(
          from: fromAirport,
          to: toAirport,
          via: const [],
          rescreening: false,
        ),
        segments: [
          Segment(
            leg: '$fromAirport-$toAirport',
            operating: airlineCode,
            cabinClass: cabinClass,
          ),
        ],
        itemParams: ItemParams(
          volumeMl: 100, // TODO: _scanResult.volume 파싱해서 반영 가능
          wh: 0,
          count: 1,
          abvPercent: 0,
          weightKg: 0.2,
          bladeLengthCm: 0,
        ),
        dutyFree: DutyFree(
          isDf: false,
          stebSealed: false,
        ),
      );

      await previewProvider.fetchPreview(request);

      if (!mounted) return;

      if (previewProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '아이템 판정 조회 중 오류가 발생했습니다.\n${previewProvider.errorMessage}',
            ),
          ),
        );
      } else if (previewProvider.preview != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ItemPreviewScreen(
              data: previewProvider.preview!,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPreviewLoading = false;
        });
      }
    }
  }
}

class ScanResult {
  final String item;
  final String category;
  final String? volume;
  final String? weight;
  final bool carryOnAllowed;
  final bool checkedAllowed;
  final List<String> restrictions;
  final int confidence;

  ScanResult({
    required this.item,
    required this.category,
    this.volume,
    this.weight,
    required this.carryOnAllowed,
    required this.checkedAllowed,
    required this.restrictions,
    required this.confidence,
  });
}
