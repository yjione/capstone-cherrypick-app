// lib/widgets/regulation_checker.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/trip_provider.dart';
import '../providers/device_provider.dart';
import '../providers/preview_provider.dart';

import '../models/preview_request.dart';
import '../models/preview_response.dart';

import '../service/reference_api.dart';
import '../models/country_ref.dart';
import '../models/airport_ref.dart';
import '../models/airline_ref.dart';
import '../models/cabin_class_ref.dart';

class RegulationChecker extends StatefulWidget {
  const RegulationChecker({super.key});

  @override
  State<RegulationChecker> createState() => _RegulationCheckerState();
}

class _RegulationCheckerState extends State<RegulationChecker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _itemController = TextEditingController();

  // reference API
  final ReferenceApiService _refApi = ReferenceApiService();

  // reference 데이터 목록
  List<CountryRef> _countries = [];
  List<AirportRef> _airports = [];
  List<AirlineRef> _airlines = [];
  List<CabinClassRef> _cabinClasses = [];

  // 선택된 값들
  CountryRef? _selectedCountry;
  AirportRef? _selectedAirport;
  AirlineRef? _selectedAirline;
  CabinClassRef? _selectedCabinClass;

  // 로딩 플래그
  bool _loadingCountries = false;
  bool _loadingAirports = false;
  bool _loadingAirlines = false;
  bool _loadingCabins = false;

  // preview 결과
  bool _isPreviewLoading = false;
  PreviewResponse? _preview;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialReferences();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Reference API 호출
  // ---------------------------------------------------------------------------

  Future<void> _loadInitialReferences() async {
    final device = context.read<DeviceProvider>();
    final deviceUuid = device.deviceUuid;
    final deviceToken = device.deviceToken;

    if (deviceUuid == null || deviceToken == null) {
      return;
    }

    setState(() {
      _loadingCountries = true;
      _loadingAirlines = true;
    });

    try {
      final countriesFuture = _refApi.listCountries(
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
      );
      final airlinesFuture = _refApi.listAirlines(
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
      );

      final results = await Future.wait([countriesFuture, airlinesFuture]);

      if (!mounted) return;

      setState(() {
        _countries = results[0] as List<CountryRef>;
        _airlines = results[1] as List<AirlineRef>;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('기본 정보 로딩 실패: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingCountries = false;
        _loadingAirlines = false;
      });
    }
  }

  Future<void> _loadAirportsForCountry(CountryRef country) async {
    final device = context.read<DeviceProvider>();
    final deviceUuid = device.deviceUuid;
    final deviceToken = device.deviceToken;

    if (deviceUuid == null || deviceToken == null) return;

    setState(() {
      _loadingAirports = true;
      _airports = [];
      _selectedAirport = null;
    });

    try {
      final airports = await _refApi.listAirports(
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
        countryCode: country.code,
        limit: 200,
      );

      if (!mounted) return;

      setState(() {
        _airports = airports;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('공항 정보 로딩 실패: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingAirports = false;
      });
    }
  }

  Future<void> _loadCabinClassesForAirline(AirlineRef airline) async {
    final device = context.read<DeviceProvider>();
    final deviceUuid = device.deviceUuid;
    final deviceToken = device.deviceToken;

    if (deviceUuid == null || deviceToken == null) return;

    setState(() {
      _loadingCabins = true;
      _cabinClasses = [];
      _selectedCabinClass = null;
    });

    try {
      final cabins = await _refApi.listCabinClasses(
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
        airlineCode: airline.code,
      );

      if (!mounted) return;

      setState(() {
        _cabinClasses = cabins;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('좌석 등급 정보 로딩 실패: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingCabins = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  bool get _canSearch =>
      !_isPreviewLoading &&
          _selectedCountry != null &&
          _selectedAirport != null &&
          _selectedAirline != null &&
          _selectedCabinClass != null &&
          _itemController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceProvider>();
    final deviceMissing =
        device.deviceUuid == null || device.deviceToken == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              '항공 규정 확인',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (deviceMissing)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                '⚠️ 기기 등록 정보가 없어 reference / preview API를 호출할 수 없습니다.\n'
                    '여행 선택 화면에서 한 번 이상 진입해 기기 등록을 완료해주세요.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 8),
          _buildSearchCard(deviceMissing),
          if (_preview != null) ...[
            const SizedBox(height: 24),
            _buildResultHeader(),
            const SizedBox(height: 16),
            _buildTabView(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchCard(bool deviceMissing) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 아이템 이름
            TextFormField(
              controller: _itemController,
              decoration: const InputDecoration(
                labelText: '아이템 이름',
                hintText: '예: 노트북, 보조배터리, 향수',
              ),
              onChanged: (_) {
                setState(() {
                  _preview = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // 국가
            DropdownButtonFormField<CountryRef>(
              value: _selectedCountry,
              decoration: InputDecoration(
                labelText: _loadingCountries
                    ? '목적지 국가 (로딩 중...)'
                    : '목적지 국가',
              ),
              items: _countries
                  .map(
                    (c) => DropdownMenuItem(
                  value: c,
                  // 👉 CountryRef 필드명에 맞게 수정
                  child: Text('${c.nameKo} (${c.code})'),
                ),
              )
                  .toList(),
              onChanged: (deviceMissing || _loadingCountries)
                  ? null
                  : (value) {
                setState(() {
                  _selectedCountry = value;
                  _preview = null;
                });
                if (value != null) {
                  _loadAirportsForCountry(value);
                }
              },
            ),
            const SizedBox(height: 16),

            // 공항
            DropdownButtonFormField<AirportRef>(
              value: _selectedAirport,
              decoration: InputDecoration(
                labelText: _selectedCountry == null
                    ? '도착 공항 (먼저 국가 선택)'
                    : _loadingAirports
                    ? '도착 공항 (로딩 중...)'
                    : '도착 공항',
              ),
              items: _airports
                  .map(
                    (a) => DropdownMenuItem(
                  value: a,
                  // 👉 AirportRef 필드명에 맞게 수정
                  child: Text('${a.nameKo} (${a.iataCode})'),
                ),
              )
                  .toList(),
              onChanged: (deviceMissing ||
                  _selectedCountry == null ||
                  _loadingAirports)
                  ? null
                  : (value) {
                setState(() {
                  _selectedAirport = value;
                  _preview = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // 항공사
            DropdownButtonFormField<AirlineRef>(
              value: _selectedAirline,
              decoration: InputDecoration(
                labelText: _loadingAirlines ? '항공사 (로딩 중...)' : '항공사',
              ),
              items: _airlines
                  .map(
                    (a) => DropdownMenuItem(
                  value: a,
                  // 👉 AirlineRef 필드명에 맞게 수정
                  child: Text('${a.name} (${a.code})'),
                ),
              )
                  .toList(),
              onChanged: (deviceMissing || _loadingAirlines)
                  ? null
                  : (value) {
                setState(() {
                  _selectedAirline = value;
                  _preview = null;
                });
                if (value != null) {
                  _loadCabinClassesForAirline(value);
                }
              },
            ),
            const SizedBox(height: 16),

            // 좌석 등급
            DropdownButtonFormField<CabinClassRef>(
              value: _selectedCabinClass,
              decoration: InputDecoration(
                labelText: _selectedAirline == null
                    ? '좌석 등급 (먼저 항공사 선택)'
                    : _loadingCabins
                    ? '좌석 등급 (로딩 중...)'
                    : '좌석 등급',
              ),
              items: _cabinClasses
                  .map(
                    (c) => DropdownMenuItem(
                  value: c,
                  // 👉 CabinClassRef 필드명에 맞게 수정
                  child: Text('${c.name} (${c.code})'),
                ),
              )
                  .toList(),
              onChanged: (deviceMissing ||
                  _selectedAirline == null ||
                  _loadingCabins)
                  ? null
                  : (value) {
                setState(() {
                  _selectedCabinClass = value;
                  _preview = null;
                });
              },
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (deviceMissing || !_canSearch)
                    ? null
                    : _searchRegulations,
                child: _isPreviewLoading
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('규정 확인 중...'),
                  ],
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 8),
                    Text('규정 확인하기'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 결과 UI
  // ---------------------------------------------------------------------------

  Widget _buildResultHeader() {
    final narration = _preview?.narration;
    final resolved = _preview?.resolved;

    final countryStr = (_selectedCountry != null && _selectedAirport != null)
        ? '${_selectedCountry!.nameKo} / ${_selectedAirport!.nameKo}'
        : '';
    final airlineStr =
    (_selectedAirline != null && _selectedCabinClass != null)
        ? '${_selectedAirline!.name} · ${_selectedCabinClass!.name}'
        : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.flight,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            [
              if (countryStr.isNotEmpty) countryStr,
              if (airlineStr.isNotEmpty) airlineStr,
              if (resolved?.label != null)
                '검색 아이템: ${resolved!.label}',
              if (narration?.title != null)
                '판정 항목: ${narration!.title}',
            ].join('\n'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabView() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '기내수하물'),
            Tab(text: '위탁수하물'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 420,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCarryOnTab(),
              _buildCheckedTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCarryOnTab() {
    final narration = _preview?.narration;
    final card = narration?.carryOnCard;
    final aiTips = _preview?.aiTips ?? [];

    if (narration == null || card == null) {
      return const Center(child: Text('기내 수하물 판정 정보를 불러올 수 없습니다.'));
    }

    final color = _statusColor(card.statusLabel);

    // 🔧 List<dynamic> → List<String>
    final bullets = List<String>.from(narration.bullets);
    final aiTipBullets = aiTips
        .map((t) => t.text)
        .where((t) => t != null)
        .map((t) => t as String)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.work_outline,
                  color: color,
                ),
                const SizedBox(width: 8),
                const Text(
                  '기내 수하물 판정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _buildStatusChip(card.statusLabel, color),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              card.shortReason,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (bullets.isNotEmpty)
              _NoticeBox(
                icon: Icons.info_outline,
                title: '추가 안내',
                bullets: bullets,
              ),
            const SizedBox(height: 16),
            if (aiTipBullets.isNotEmpty)
              _NoticeBox(
                icon: Icons.lightbulb_outline,
                title: 'AI 팁',
                bullets: aiTipBullets,
                accent: const Color(0xFFF97316),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckedTab() {
    final narration = _preview?.narration;
    final card = narration?.checkedCard;
    final aiTips = _preview?.aiTips ?? [];

    if (narration == null || card == null) {
      return const Center(child: Text('위탁 수하물 판정 정보를 불러올 수 없습니다.'));
    }

    final color = _statusColor(card.statusLabel);

    // 🔧 List<dynamic> → List<String>
    final bullets = List<String>.from(narration.bullets);
    final aiTipBullets = aiTips
        .map((t) => t.text)
        .where((t) => t != null)
        .map((t) => t as String)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.luggage_outlined,
                  color: color,
                ),
                const SizedBox(width: 8),
                const Text(
                  '위탁 수하물 판정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _buildStatusChip(card.statusLabel, color),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              card.shortReason,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (bullets.isNotEmpty)
              _NoticeBox(
                icon: Icons.info_outline,
                title: '추가 안내',
                bullets: bullets,
              ),
            const SizedBox(height: 16),
            if (aiTipBullets.isNotEmpty)
              _NoticeBox(
                icon: Icons.lightbulb_outline,
                title: 'AI 팁',
                bullets: aiTipBullets,
                accent: const Color(0xFF3B82F6),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Preview API 호출
  // ---------------------------------------------------------------------------

  Future<void> _searchRegulations() async {
    if (_isPreviewLoading) return;

    final tripProvider = context.read<TripProvider>();
    final deviceProvider = context.read<DeviceProvider>();
    final previewProvider = context.read<PreviewProvider>();

    final currentTrip = tripProvider.currentTrip;
    final deviceUuid = deviceProvider.deviceUuid;
    final deviceToken = deviceProvider.deviceToken;

    if (currentTrip == null || deviceUuid == null || deviceToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('여행/기기 정보가 없어 규정을 조회할 수 없어요.')),
      );
      return;
    }

    final label = _itemController.text.trim();
    if (label.isEmpty ||
        _selectedAirport == null ||
        _selectedAirline == null ||
        _selectedCabinClass == null) {
      return;
    }

    setState(() {
      _isPreviewLoading = true;
      _preview = null;
    });

    try {
      const fromAirport = 'ICN'; // 출발 공항은 일단 고정
      final toAirport = _selectedAirport!.iataCode;
      final airlineCode = _selectedAirline!.code;
      final cabinClassCode = _selectedCabinClass!.code;

      final reqId = DateTime.now().millisecondsSinceEpoch.toString();

      final request = PreviewRequest(
        label: label,
        locale: 'ko-KR',
        reqId: reqId,
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
            cabinClass: cabinClassCode,
          ),
        ],
        itemParams: ItemParams(
          volumeMl: 0,
          wh: 0,
          count: 1,
          abvPercent: 0,
          weightKg: 0,
          bladeLengthCm: 0,
        ),
        dutyFree: DutyFree(
          isDf: false,
          stebSealed: false,
        ),
      );

      await previewProvider.fetchPreview(request);

      if (!mounted) return;

      if (previewProvider.errorMessage != null ||
          previewProvider.preview == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '규정을 불러오지 못했어요: '
                  '${previewProvider.errorMessage ?? '알 수 없는 오류'}',
            ),
          ),
        );
        return;
      }

      setState(() {
        _preview = previewProvider.preview;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isPreviewLoading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Helper
  // ---------------------------------------------------------------------------

  Color _statusColor(String label) {
    if (label.contains('금지') || label.contains('불가')) {
      return Colors.red;
    }
    if (label.contains('허용') || label.contains('가능')) {
      return Colors.green;
    }
    return Colors.orange;
  }
}

// 공통 안내 박스 ---------------------------------------------------------------

class _NoticeBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> bullets;
  final String? badge;
  final Color? accent;

  const _NoticeBox({
    required this.icon,
    required this.title,
    required this.bullets,
    this.badge,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color a = accent ?? cs.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: a, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (badge != null)
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: a,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...bullets.map(
              (t) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8, right: 8),
                  decoration: BoxDecoration(
                    color: a,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Text(
                    t,
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
