// lib/widgets/regulation_checker.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// trip_provider는 지금 안 쓰여서 주석 처리해도 됨
// import '../providers/trip_provider.dart';

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
  List<AirportRef> _fromAirports = [];
  List<AirportRef> _toAirports = [];
  List<AirlineRef> _airlines = [];
  List<CabinClassRef> _cabinClasses = [];

  // 선택된 값들
  CountryRef? _fromCountry;
  AirportRef? _fromAirport;
  CountryRef? _toCountry;
  AirportRef? _toAirport;
  AirlineRef? _selectedAirline;
  CabinClassRef? _selectedCabinClass;

  // 로딩 플래그
  bool _loadingCountries = false;
  bool _loadingFromAirports = false;
  bool _loadingToAirports = false;
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

  Future<void> _loadAirportsForCountry(
      CountryRef country, {
        required bool isFrom,
        VoidCallback? onModalUpdate,
      }) async {
    final device = context.read<DeviceProvider>();
    final deviceUuid = device.deviceUuid;
    final deviceToken = device.deviceToken;

    if (deviceUuid == null || deviceToken == null) return;

    setState(() {
      if (isFrom) {
        _loadingFromAirports = true;
        _fromAirports = [];
        _fromAirport = null;
      } else {
        _loadingToAirports = true;
        _toAirports = [];
        _toAirport = null;
      }
    });
    onModalUpdate?.call(); // 바텀시트도 리빌드

    try {
      final airports = await _refApi.listAirports(
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
        countryCode: country.code,
        limit: 200,
      );

      if (!mounted) return;

      setState(() {
        if (isFrom) {
          _fromAirports = airports;
        } else {
          _toAirports = airports;
        }
      });
      onModalUpdate?.call(); // 리스트 바뀐 후에도 리빌드
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('공항 정보 로딩 실패: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        if (isFrom) {
          _loadingFromAirports = false;
        } else {
          _loadingToAirports = false;
        }
      });
      onModalUpdate?.call(); // 로딩 플래그 변경 반영
    }
  }

  Future<void> _loadCabinClassesForAirline(
      AirlineRef airline, {
        VoidCallback? onModalUpdate,
      }) async {
    final device = context.read<DeviceProvider>();
    final deviceUuid = device.deviceUuid;
    final deviceToken = device.deviceToken;

    if (deviceUuid == null || deviceToken == null) return;

    setState(() {
      _loadingCabins = true;
      _cabinClasses = [];
      _selectedCabinClass = null;
    });
    onModalUpdate?.call();

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
      onModalUpdate?.call();
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
      onModalUpdate?.call();
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  bool get _canSearch =>
      !_isPreviewLoading &&
          _fromCountry != null &&
          _fromAirport != null &&
          _toCountry != null &&
          _toAirport != null &&
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
          _buildSearchForm(deviceMissing),
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

  /// 메인 화면: 아이템 이름 + 왕복 정보 카드 + 규정 확인 버튼
  Widget _buildSearchForm(bool deviceMissing) {
    final cs = Theme.of(context).colorScheme;

    final fromLabel = (_fromCountry != null && _fromAirport != null)
        ? '${_fromCountry!.code} · ${_fromAirport!.iataCode}'
        : '';

    final toLabel = (_toCountry != null && _toAirport != null)
        ? '${_toCountry!.code} · ${_toAirport!.iataCode}'
        : '';

    final airlineLabel = _selectedAirline != null
        ? _selectedAirline!.name
        : '';

    final cabinLabel = _selectedCabinClass != null
        ? _selectedCabinClass!.name
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '어떤 물건인지 알려주세요',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _itemController,
          decoration: InputDecoration(
            hintText: '예: 노트북, 보조배터리, 향수',
            filled: true,
            fillColor: cs.surfaceVariant.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (_) {
            setState(() {
              _preview = null;
            });
          },
        ),
        const SizedBox(height: 24),

        const Text(
          '왕복 기준 출발·도착 정보를 입력해 주세요.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              _InfoRow(
                title: '출발지',
                value: fromLabel,
                onTap: deviceMissing ? null : _showFromBottomSheet,
              ),
              const Divider(height: 1),
              _InfoRow(
                title: '도착지',
                value: toLabel,
                onTap: deviceMissing ? null : _showToBottomSheet,
              ),
              const Divider(height: 1),
              _InfoRow(
                title: '항공사',
                value: airlineLabel,
                onTap: deviceMissing ? null : _showFlightBottomSheet,
              ),
              const Divider(height: 1),
              _InfoRow(
                title: '좌석 등급',
                value: cabinLabel,
                onTap: deviceMissing ? null : _showFlightBottomSheet,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '※ 입력하신 구간을 기준으로 항공 규정을 계산할 수 있어요.',
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed:
            (deviceMissing || !_canSearch) ? null : _searchRegulations,
            icon: _isPreviewLoading
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.search),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                _isPreviewLoading ? '규정 확인 중...' : '규정 확인하기',
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 출발지 / 도착지 / 항공편 바텀시트
  // ---------------------------------------------------------------------------

  void _showFromBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, modalSetState) {
            final cs = Theme.of(ctx).colorScheme;
            final bottom = MediaQuery.of(ctx).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cs.outline.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const Text(
                    '어디에서 출발하나요?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 출발 국가
                  DropdownButtonFormField<CountryRef>(
                    value: _fromCountry,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText:
                      _loadingCountries ? '출발 국가 (로딩 중...)' : '출발 국가',
                    ),
                    items: _countries
                        .map(
                          (c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          '${c.nameKo} (${c.code})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _fromCountry = value;
                        _preview = null;
                      });
                      modalSetState(() {}); // 텍스트 즉시 반영

                      if (value != null) {
                        _loadAirportsForCountry(
                          value,
                          isFrom: true,
                          onModalUpdate: () => modalSetState(() {}),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // 출발 공항
                  DropdownButtonFormField<AirportRef>(
                    value: _fromAirport,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: _fromCountry == null
                          ? '출발 공항 (먼저 국가 선택)'
                          : _loadingFromAirports
                          ? '출발 공항 (로딩 중...)'
                          : '출발 공항',
                    ),
                    items: _fromAirports
                        .map(
                          (a) => DropdownMenuItem(
                        value: a,
                        child: Text(
                          '${a.nameKo} (${a.iataCode})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (_fromCountry == null || _loadingFromAirports)
                        ? null
                        : (value) {
                      setState(() {
                        _fromAirport = value;
                        _preview = null;
                      });
                      modalSetState(() {});
                    },
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('완료'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showToBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, modalSetState) {
            final cs = Theme.of(ctx).colorScheme;
            final bottom = MediaQuery.of(ctx).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cs.outline.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const Text(
                    '어디로 도착하나요?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 도착 국가
                  DropdownButtonFormField<CountryRef>(
                    value: _toCountry,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText:
                      _loadingCountries ? '도착 국가 (로딩 중...)' : '도착 국가',
                    ),
                    items: _countries
                        .map(
                          (c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          '${c.nameKo} (${c.code})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _toCountry = value;
                        _preview = null;
                      });
                      modalSetState(() {});

                      if (value != null) {
                        _loadAirportsForCountry(
                          value,
                          isFrom: false,
                          onModalUpdate: () => modalSetState(() {}),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // 도착 공항
                  DropdownButtonFormField<AirportRef>(
                    value: _toAirport,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: _toCountry == null
                          ? '도착 공항 (먼저 국가 선택)'
                          : _loadingToAirports
                          ? '도착 공항 (로딩 중...)'
                          : '도착 공항',
                    ),
                    items: _toAirports
                        .map(
                          (a) => DropdownMenuItem(
                        value: a,
                        child: Text(
                          '${a.nameKo} (${a.iataCode})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (_toCountry == null || _loadingToAirports)
                        ? null
                        : (value) {
                      setState(() {
                        _toAirport = value;
                        _preview = null;
                      });
                      modalSetState(() {});
                    },
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('완료'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFlightBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, modalSetState) {
            final bottom = MediaQuery.of(sheetContext).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '어떤 항공편을 이용하나요?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 항공사
                    DropdownButtonFormField<AirlineRef>(
                      value: _selectedAirline,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText:
                        _loadingAirlines ? '항공사 (로딩 중...)' : '항공사',
                      ),
                      items: _airlines
                          .map(
                            (a) => DropdownMenuItem(
                          value: a,
                          child: Text(
                            '${a.name} (${a.code})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                          .toList(),
                      onChanged: _loadingAirlines
                          ? null
                          : (value) {
                        setState(() {
                          _selectedAirline = value;
                          _selectedCabinClass = null;
                          _preview = null;
                        });
                        modalSetState(() {});

                        if (value != null) {
                          _loadCabinClassesForAirline(
                            value,
                            onModalUpdate: () => modalSetState(() {}),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 좌석 등급
                    DropdownButtonFormField<CabinClassRef>(
                      value: _selectedCabinClass,
                      isExpanded: true,
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
                          child: Text(
                            '${c.name} (${c.code})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                          .toList(),
                      onChanged:
                      (_selectedAirline == null || _loadingCabins) ? null : (
                          value,
                          ) {
                        setState(() {
                          _selectedCabinClass = value;
                          _preview = null;
                        });
                        modalSetState(() {});
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('완료'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Preview API 호출
  // ---------------------------------------------------------------------------

  Future<void> _searchRegulations() async {
    if (_isPreviewLoading) return;

    final deviceProvider = context.read<DeviceProvider>();
    final previewProvider = context.read<PreviewProvider>();

    final deviceUuid = deviceProvider.deviceUuid;
    final deviceToken = deviceProvider.deviceToken;

    if (deviceUuid == null || deviceToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기기 등록 정보가 없어 규정을 조회할 수 없어요.')),
      );
      return;
    }

    final label = _itemController.text.trim();
    if (label.isEmpty ||
        _fromAirport == null ||
        _toAirport == null ||
        _selectedAirline == null ||
        _selectedCabinClass == null) {
      return;
    }

    setState(() {
      _isPreviewLoading = true;
      _preview = null;
    });

    try {
      final fromAirport = _fromAirport!.iataCode;
      final toAirport = _toAirport!.iataCode;
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
  // 결과 UI
  // ---------------------------------------------------------------------------

  Widget _buildResultHeader() {
    final narration = _preview?.narration;
    final resolved = _preview?.resolved;

    String routeStr = '';
    if (_fromCountry != null &&
        _fromAirport != null &&
        _toCountry != null &&
        _toAirport != null) {
      routeStr =
      '${_fromCountry!.nameKo} ${_fromAirport!.nameKo} → '
          '${_toCountry!.nameKo} ${_toAirport!.nameKo}';
    }

    final airlineStr =
    (_selectedAirline != null && _selectedCabinClass != null)
        ? '${_selectedAirline!.name} · ${_selectedCabinClass!.name}'
        : '';

    String? itemLabel;
    if (narration != null && narration.title.trim().isNotEmpty) {
      itemLabel = narration.title;
    } else if (resolved != null && resolved.label.trim().isNotEmpty) {
      itemLabel = resolved.label;
    }

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
              if (routeStr.isNotEmpty) routeStr,
              if (airlineStr.isNotEmpty) airlineStr,
              if (itemLabel != null) '아이템: $itemLabel',
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

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
