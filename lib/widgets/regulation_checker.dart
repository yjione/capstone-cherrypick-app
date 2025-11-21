import 'package:flutter/material.dart';

class RegulationChecker extends StatefulWidget {
  const RegulationChecker({super.key});

  @override
  State<RegulationChecker> createState() => _RegulationCheckerState();
}

class _RegulationCheckerState extends State<RegulationChecker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? _selectedCountry;
  String? _selectedAirport;
  String? _selectedAirline;
  String? _selectedSeatClass;

  bool _isLoading = false;
  RegulationData? _regulationData;

  /// ✅ 국가 → 공항 목록
  final Map<String, List<String>> _countryAirports = const {
    '일본': [
      '나리타(NRT)',
      '하네다(HND)',
      '간사이(KIX)',
    ],
    '미국': [
      'LAX(로스앤젤레스)',
      'JFK(뉴욕)',
      'SFO(샌프란시스코)',
    ],
    '한국': [
      '인천(ICN)',
      '김포(GMP)',
      '김해(PUS)',
    ],
  };

  /// ✅ 항공사 전체 목록 (국가와 무관)
  final List<String> _allAirlines = const [
    '대한항공',
    '아시아나항공',
    '제주항공',
    'JAL',
    '델타',
    '아메리칸항공',
  ];

  /// ✅ 항공사 → 좌석 등급 (항공사에만 종속)
  final Map<String, List<String>> _airlineSeatClasses = const {
    '대한항공': ['이코노미', '프리미엄 이코노미', '비즈니스', '일등석'],
    '아시아나항공': ['이코노미', '비즈니스'],
    '제주항공': ['이코노미'],
    'JAL': ['이코노미', '프리미엄 이코노미', '비즈니스'],
    '델타': ['이코노미', '비즈니스'],
    '아메리칸항공': ['이코노미', '비즈니스', '일등석'],
  };

  // ----- Getter들 -----

  List<String> get _countries => _countryAirports.keys.toList();

  List<String> get _airports {
    if (_selectedCountry == null) return [];
    return _countryAirports[_selectedCountry!] ?? [];
  }

  // 항공사는 국가/공항과 무관하게 동일한 전체 리스트
  List<String> get _airlines => _allAirlines;

  // 좌석 등급은 항공사에만 종속
  List<String> get _seatClasses {
    if (_selectedAirline == null) return [];
    return _airlineSeatClasses[_selectedAirline!] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 24),
          _buildSearchCard(),
          if (_regulationData != null) ...[
            const SizedBox(height: 24),
            _buildResultHeader(),
            const SizedBox(height: 16),
            _buildTabView(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 1) 국가 선택
            DropdownButtonFormField<String>(
              value: _selectedCountry,
              decoration: const InputDecoration(
                labelText: '목적지 국가',
              ),
              items: _countries
                  .map(
                    (country) => DropdownMenuItem(
                  value: country,
                  child: Text(country),
                ),
              )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCountry = value;
                  // 국가가 바뀌면 공항만 초기화
                  _selectedAirport = null;
                  _selectedSeatClass = null;
                  _regulationData = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // 2) 공항 선택 (국가에 종속)
            DropdownButtonFormField<String>(
              value: _selectedAirport,
              decoration: const InputDecoration(
                labelText: '공항',
              ),
              items: _airports
                  .map(
                    (airport) => DropdownMenuItem(
                  value: airport,
                  child: Text(airport),
                ),
              )
                  .toList(),
              onChanged: (_selectedCountry == null)
                  ? null
                  : (value) {
                setState(() {
                  _selectedAirport = value;
                  _regulationData = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // 3) 항공사 선택 (국가와 무관)
            DropdownButtonFormField<String>(
              value: _selectedAirline,
              decoration: const InputDecoration(
                labelText: '항공사',
              ),
              items: _airlines
                  .map(
                    (airline) => DropdownMenuItem(
                  value: airline,
                  child: Text(airline),
                ),
              )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAirline = value;
                  _selectedSeatClass = null;
                  _regulationData = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // 4) 좌석 등급 선택 (항공사에 종속)
            DropdownButtonFormField<String>(
              value: _selectedSeatClass,
              decoration: const InputDecoration(
                labelText: '좌석 등급',
              ),
              items: _seatClasses
                  .map(
                    (seat) => DropdownMenuItem(
                  value: seat,
                  child: Text(seat),
                ),
              )
                  .toList(),
              onChanged: (_selectedAirline == null)
                  ? null
                  : (value) {
                setState(() {
                  _selectedSeatClass = value;
                  _regulationData = null;
                });
              },
            ),
            const SizedBox(height: 24),

            // 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSearch ? _searchRegulations : null,
                child: _isLoading
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

  bool get _canSearch =>
      !_isLoading &&
          _selectedCountry != null &&
          _selectedAirport != null &&
          _selectedAirline != null &&
          _selectedSeatClass != null;

  Widget _buildResultHeader() {
    return Row(
      children: [
        Icon(
          Icons.flight,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '${_regulationData!.country} / ${_regulationData!.airport}\n'
              '${_regulationData!.airline} · ${_regulationData!.seatClass}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
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
            Tab(text: '금지품목'),
            Tab(text: '면세한도'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 600,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCarryOnTab(),
              _buildCheckedTab(),
              _buildProhibitedTab(),
              _buildDutyFreeTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCarryOnTab() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
                SizedBox(width: 8),
                Text(
                  '기내 수하물 규정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    '최대 무게',
                    _regulationData!.carryOn.maxWeight,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    '최대 크기',
                    _regulationData!.carryOn.maxSize,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLiquidRestrictions(),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckedTab() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.blue,
                ),
                SizedBox(width: 8),
                Text(
                  '위탁 수하물 규정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    '최대 무게',
                    _regulationData!.checked.maxWeight,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    '최대 크기',
                    _regulationData!.checked.maxSize,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCheckedRestrictions(),
          ],
        ),
      ),
    );
  }

  Widget _buildProhibitedTab() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Colors.red,
                ),
                SizedBox(width: 8),
                Text(
                  '금지 품목',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _regulationData!.prohibited.map((item) {
                return Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.red.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '중요 안내',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '위 품목들은 기내 및 위탁 수하물 모두 반입이 금지됩니다. 자세한 사항은 해당 항공사 및 공항 보안청에 문의하세요.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDutyFreeTab() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.green,
                ),
                SizedBox(width: 8),
                Text(
                  '면세 한도',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDutyFreeItem(
                      '🍷', '주류', _regulationData!.dutyFree.alcohol),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDutyFreeItem(
                      '🚬', '담배', _regulationData!.dutyFree.tobacco),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDutyFreeItem(
                      '🌸', '향수', _regulationData!.dutyFree.perfume),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _NoticeBox(
              icon: Icons.info_rounded,
              title: '면세 한도 안내',
              bullets: [
                '위 한도는 성인 1인 기준이며 국가별로 상이할 수 있습니다.',
                '초과 시 관세가 부과될 수 있으니 주의하세요.',
              ],
              accent: Color(0xFF10B981),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiquidRestrictions() {
    final data = _regulationData!.carryOn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '액체류 제한',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _NoticeBox(
          icon: Icons.warning_amber_rounded,
          title: '액체류 규정',
          badge: data.liquidLimit,
          bullets: data.restrictions,
        ),
      ],
    );
  }

  Widget _buildCheckedRestrictions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주의사항',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _NoticeBox(
          icon: Icons.info_rounded,
          title: '위탁 수하물 주의사항',
          bullets: _regulationData!.checked.restrictions,
          accent: const Color(0xFF3B82F6),
        ),
      ],
    );
  }

  Widget _buildDutyFreeItem(String emoji, String title, String limit) {
    const green = Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: green.withOpacity(0.06),
        border: Border.all(color: green.withOpacity(0.18)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: green,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            limit,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 여기서는 더미 규정 데이터만 세팅 (Preview API 호출 없음)
  Future<void> _searchRegulations() async {
    if (!_canSearch) return;

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _regulationData = RegulationData(
        country: _selectedCountry!,
        airport: _selectedAirport!,
        airline: _selectedAirline!,
        seatClass: _selectedSeatClass!,
        carryOn: CarryOnData(
          maxWeight: "10kg",
          maxSize: "55cm × 40cm × 20cm",
          liquidLimit: "100ml (총 1L)",
          restrictions: [
            "투명 지퍼백에 보관",
            "개별 용기 100ml 이하",
            "1인당 1개 지퍼백만 허용",
          ],
        ),
        checked: CheckedData(
          maxWeight: "23kg",
          maxSize: "158cm (3변의 합)",
          restrictions: [
            "리튬배터리 금지",
            "인화성 물질 금지",
            "날카로운 물건 주의",
          ],
        ),
        prohibited: [
          "폭발물",
          "인화성 액체",
          "독성 물질",
          "방사성 물질",
          "부식성 물질",
          "자성 물질",
          "산화성 물질",
        ],
        dutyFree: DutyFreeData(
          alcohol: "1L (21도 이상 22도 미만) 또는 400ml (22도 이상)",
          tobacco: "담배 200개비 또는 시가 50개비",
          perfume: "60ml",
        ),
      );
      _isLoading = false;
    });
  }
}

/// ===== 데이터 모델들 =====

class RegulationData {
  final String country;
  final String airport;
  final String airline;
  final String seatClass;
  final CarryOnData carryOn;
  final CheckedData checked;
  final List<String> prohibited;
  final DutyFreeData dutyFree;

  RegulationData({
    required this.country,
    required this.airport,
    required this.airline,
    required this.seatClass,
    required this.carryOn,
    required this.checked,
    required this.prohibited,
    required this.dutyFree,
  });
}

class CarryOnData {
  final String maxWeight;
  final String maxSize;
  final String liquidLimit;
  final List<String> restrictions;

  CarryOnData({
    required this.maxWeight,
    required this.maxSize,
    required this.liquidLimit,
    required this.restrictions,
  });
}

class CheckedData {
  final String maxWeight;
  final String maxSize;
  final List<String> restrictions;

  CheckedData({
    required this.maxWeight,
    required this.maxSize,
    required this.restrictions,
  });
}

class DutyFreeData {
  final String alcohol;
  final String tobacco;
  final String perfume;

  DutyFreeData({
    required this.alcohol,
    required this.tobacco,
    required this.perfume,
  });
}

class _NoticeBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> bullets;
  final String? badge; // 없으면 null
  final Color? accent; // 없으면 브랜드 핑크 사용

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
        // 상단 라인 (아이콘 + 제목 + 뱃지)
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
        // 불릿 리스트 (배경 박스 없이)
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
