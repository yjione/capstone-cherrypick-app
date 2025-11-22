// lib/screens/initial_trip_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/trip.dart';
import '../providers/trip_provider.dart';
import '../providers/device_provider.dart'; // ✔️ 추가됨

class InitialTripScreen extends StatefulWidget {
  const InitialTripScreen({super.key});

  @override
  State<InitialTripScreen> createState() => _InitialTripScreenState();
}

class _InitialTripScreenState extends State<InitialTripScreen> {
  // 0: 편명 입력, 1: 국가/공항/항공사/좌석 등급 입력
  int _inputMode = 0;

  final _formKey = GlobalKey<FormState>();

  // --- 편명 입력용 (왕복) ---
  final _outboundFlightController = TextEditingController();
  final _returnFlightController = TextEditingController();

  // --- 상세 입력용: 드롭다운 상태 ---
  String? _fromCountry;
  String? _fromAirport;
  String? _toCountry;
  String? _toAirport;
  String? _airline;
  String? _seatClass;

  /// 국가 → 공항 목록
  final Map<String, List<String>> _countryAirports = const {
    '일본': ['나리타(NRT)', '하네다(HND)', '간사이(KIX)'],
    '미국': ['LAX(로스앤젤레스)', 'JFK(뉴욕)', 'SFO(샌프란시스코)'],
    '한국': ['인천(ICN)', '김포(GMP)', '김해(PUS)'],
  };

  /// 항공사 전체 목록
  final List<String> _allAirlines = const [
    '대한항공',
    '아시아나항공',
    '제주항공',
    'JAL',
    '델타',
    '아메리칸항공',
  ];

  /// 항공사 → 좌석 등급
  final Map<String, List<String>> _airlineSeatClasses = const {
    '대한항공': ['이코노미', '프리미엄 이코노미', '비즈니스', '일등석'],
    '아시아나항공': ['이코노미', '비즈니스'],
    '제주항공': ['이코노미'],
    'JAL': ['이코노미', '프리미엄 이코노미', '비즈니스'],
    '델타': ['이코노미', '비즈니스'],
    '아메리칸항공': ['이코노미', '비즈니스', '일등석'],
  };

  List<String> get _countries => _countryAirports.keys.toList();
  List<String> _airportsFor(String? country) =>
      country == null ? [] : _countryAirports[country] ?? [];
  List<String> get _fromAirports => _airportsFor(_fromCountry);
  List<String> get _toAirports => _airportsFor(_toCountry);

  List<String> get _seatClassesForSelectedAirline =>
      _airline == null ? [] : _airlineSeatClasses[_airline!] ?? [];

  // ✔️ 추가된 부분: 앱 시작 시 Device 등록
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final deviceProvider = context.read<DeviceProvider>();

      deviceProvider.registerIfNeeded(
        appVersion: '1.0.0',
        os: 'android', // TODO: 플랫폼에 맞게 수정
        model: 'test-device',
        locale: 'ko-KR',
        timezone: '+09:00',
        deviceUuid: 'dummy-device-1234', // TODO: 실제 UUID로 교체
      );
    });
  }

  @override
  void dispose() {
    _outboundFlightController.dispose();
    _returnFlightController.dispose();
    super.dispose();
  }

  String _todayIso() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final tripProvider = context.read<TripProvider>();
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final today = _todayIso();

    Trip newTrip;

    if (_inputMode == 0) {
      // 편명 입력
      final go = _outboundFlightController.text.trim();
      final back = _returnFlightController.text.trim();

      newTrip = Trip(
        id: newId,
        name: '$go / $back 왕복 여행',
        destination: '미정',
        startDate: today,
        duration: '왕복',
      );
    } else {
      // 국가·공항·항공사·좌석 입력
      final fromCountry = _fromCountry!;
      final fromAirport = _fromAirport!;
      final toCountry = _toCountry!;
      final toAirport = _toAirport!;
      final airline = _airline!;
      final seatClass = _seatClass!;

      newTrip = Trip(
        id: newId,
        name: '$toCountry 여행',
        destination: '$toCountry $toAirport',
        startDate: today,
        duration: '왕복 · $airline · $seatClass',
      );
    }

    tripProvider.addTrip(newTrip);
    context.go('/luggage');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('첫 여행 설정'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '왕복 여행 정보를 먼저 입력해 주세요',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '항공 규정을 정확하게 알려주기 위해\n이번 여행의 왕복 정보를 받아요.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // 입력 방식 토글
              ToggleButtons(
                isSelected: [
                  _inputMode == 0,
                  _inputMode == 1,
                ],
                onPressed: (index) {
                  setState(() => _inputMode = index);
                },
                borderRadius: BorderRadius.circular(12),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('편명으로 입력'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('국가/공항으로 입력'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _inputMode == 0
                          ? _buildFlightNumberForm()
                          : _buildDetailForm(),
                    ),
                  ),
                ),
              ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('완료'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ---------------- 위젯 빌더 ----------------

  Widget _buildFlightNumberForm() {
    return Column(
      key: const ValueKey('flightForm'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '편명으로 왕복 정보를 입력해 주세요.',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _outboundFlightController,
          decoration: const InputDecoration(
            labelText: '가는 편명 (예: KE123)',
          ),
          textCapitalization: TextCapitalization.characters,
          validator: (value) =>
          value == null || value.trim().isEmpty ? '가는 편명을 입력해 주세요.' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _returnFlightController,
          decoration: const InputDecoration(
            labelText: '오는 편명 (예: KE124)',
          ),
          textCapitalization: TextCapitalization.characters,
          validator: (value) =>
          value == null || value.trim().isEmpty ? '오는 편명을 입력해 주세요.' : null,
        ),
        const SizedBox(height: 16),
        const Text(
          '※ 편명 기준으로 나중에 항공 규정·경로 정보를 자동으로 가져올 수 있어요.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDetailForm() {
    return Column(
      key: const ValueKey('detailForm'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '왕복 기준 출발·도착 정보를 입력해 주세요.',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        // 출발 국가
        DropdownButtonFormField<String>(
          value: _fromCountry,
          decoration: const InputDecoration(labelText: '출발 국가'),
          items: _countries
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _fromCountry = value;
              _fromAirport = null;
            });
          },
          validator: (value) => value == null ? '출발 국가를 선택해 주세요.' : null,
        ),
        const SizedBox(height: 8),

        // 출발 공항
        DropdownButtonFormField<String>(
          value: _fromAirport,
          decoration: const InputDecoration(labelText: '출발 공항'),
          items: _fromAirports
              .map((a) => DropdownMenuItem(value: a, child: Text(a)))
              .toList(),
          onChanged: (_fromCountry == null)
              ? null
              : (value) {
            setState(() => _fromAirport = value);
          },
          validator: (value) => value == null ? '출발 공항을 선택해 주세요.' : null,
        ),
        const SizedBox(height: 16),

        // 도착 국가
        DropdownButtonFormField<String>(
          value: _toCountry,
          decoration: const InputDecoration(labelText: '도착 국가'),
          items: _countries
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _toCountry = value;
              _toAirport = null;
            });
          },
          validator: (value) => value == null ? '도착 국가를 선택해 주세요.' : null,
        ),
        const SizedBox(height: 8),

        // 도착 공항
        DropdownButtonFormField<String>(
          value: _toAirport,
          decoration: const InputDecoration(labelText: '도착 공항'),
          items: _toAirports
              .map((a) => DropdownMenuItem(value: a, child: Text(a)))
              .toList(),
          onChanged: (_toCountry == null)
              ? null
              : (value) {
            setState(() => _toAirport = value);
          },
          validator: (value) => value == null ? '도착 공항을 선택해 주세요.' : null,
        ),
        const SizedBox(height: 16),

        // 항공사
        DropdownButtonFormField<String>(
          value: _airline,
          decoration: const InputDecoration(labelText: '항공사'),
          items: _allAirlines
              .map((air) => DropdownMenuItem(value: air, child: Text(air)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _airline = value;
              _seatClass = null;
            });
          },
          validator: (value) => value == null ? '항공사를 선택해 주세요.' : null,
        ),
        const SizedBox(height: 16),

        // 좌석 등급
        DropdownButtonFormField<String>(
          value: _seatClass,
          decoration: const InputDecoration(labelText: '좌석 등급'),
          items: _seatClassesForSelectedAirline
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (_airline == null)
              ? null
              : (value) {
            setState(() {
              _seatClass = value;
            });
          },
          validator: (value) => value == null ? '좌석 등급을 선택해 주세요.' : null,
        ),

        const SizedBox(height: 16),
        const Text(
          '※ 입력하신 왕복 구간을 기준으로 항공 규정을 계산할 수 있어요.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
