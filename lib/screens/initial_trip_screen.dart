// lib/screens/initial_trip_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/trip.dart';
import '../models/country_ref.dart';
import '../models/airport_ref.dart';
import '../models/airline_ref.dart';
import '../models/cabin_class_ref.dart';

import '../providers/trip_provider.dart';
import '../providers/device_provider.dart';
import '../providers/reference_provider.dart';
import '../service/trip_api.dart';

class InitialTripScreen extends StatefulWidget {
  const InitialTripScreen({super.key});

  @override
  State<InitialTripScreen> createState() => _InitialTripScreenState();
}

class _InitialTripScreenState extends State<InitialTripScreen> {
  int _inputMode = 0;

  final _formKey = GlobalKey<FormState>();

  // 🎯 더미 기본값이 채워진 컨트롤러
  final _tripTitleController = TextEditingController(text: 'LA 여행 테스트');
  final _outboundFlightController = TextEditingController(text: 'KE017');
  final _returnFlightController = TextEditingController(text: 'KE012');

  // 🎯 더미 기본값 설정 (테스트용)
  String? _fromCountryCode = 'KR';  // 한국
  String? _fromAirportIata = 'ICN'; // 인천국제공항
  String? _toCountryCode = 'US';    // 미국
  String? _toAirportIata = 'LAX';   // 로스앤젤레스
  String? _airlineCode = 'KE';      // 대한항공
  String? _airlineName = '대한항공';
  String? _seatClass = '이코노미';

  static const List<String> _defaultSeatClasses = [
    '이코노미',
    '프리미엄 이코노미',
    '비즈니스',
    '일등석',
  ];

  final TripApiService _tripApi = TripApiService();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final deviceProvider = context.read<DeviceProvider>();
      final refProvider = context.read<ReferenceProvider>();

      debugPrint('🔧 [InitialTripScreen] registerIfNeeded 호출');

      // 저장된 UUID를 먼저 로드
      await deviceProvider.loadFromStorage();
      
      // UUID가 없으면 새로 생성 (타임스탬프 기반)
      final deviceUuid = deviceProvider.deviceUuid ?? 
          'android-emulator-${DateTime.now().millisecondsSinceEpoch}';

      await deviceProvider.registerIfNeeded(
        appVersion: '1.0.0',
        os: 'android', // 실제 플랫폼에 맞게 수정
        model: 'test-device',
        locale: 'ko-KR',
        timezone: '+09:00',
        deviceUuid: deviceUuid, // 동적으로 생성된 UUID 사용
      );

      // 등록 후 디바이스 정보 확인
      if (deviceProvider.deviceUuid != null && deviceProvider.deviceToken != null) {
        debugPrint('🌍 국가 목록 fetchCountries 호출');
        await refProvider.fetchCountries(
          deviceUuid: deviceProvider.deviceUuid!,
          deviceToken: deviceProvider.deviceToken!,
          activeOnly: true,
        );

        debugPrint('✈️ 항공사 목록 fetchAirlines 호출');
        await refProvider.fetchAirlines(
          deviceUuid: deviceProvider.deviceUuid!,
          deviceToken: deviceProvider.deviceToken!,
          activeOnly: true,
        );
      } else {
        debugPrint('⚠️ device 정보 없음 → reference 호출 생략');
      }
    });
  }

  @override
  void dispose() {
    _tripTitleController.dispose();
    _outboundFlightController.dispose();
    _returnFlightController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _todayIso() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  String _calcDuration(String startDate, String endDate) {
    try {
      final s = DateTime.parse(startDate);
      final e = DateTime.parse(endDate);
      final days = e.difference(s).inDays;
      if (days <= 0) return '당일치기';
      return '${days}박 ${days + 1}일';
    } catch (_) {
      return '';
    }
  }

  CountryRef? _countryByCode(List<CountryRef> list, String code) {
    try {
      return list.firstWhere((c) => c.code == code);
    } catch (_) {
      return null;
    }
  }

  AirportRef? _airportByIata(List<AirportRef> list, String iata) {
    try {
      return list.firstWhere((a) => a.iataCode == iata);
    } catch (_) {
      return null;
    }
  }

  String _buildLegString(FlightLookupResult flight) {
    final dep = flight.departureAirportIata;
    final arr = flight.arrivalAirportIata;

    if (dep.isNotEmpty && arr.isNotEmpty) {
      return '$dep-$arr';
    }

    if (flight.leg != null && flight.leg!.length >= 7) {
      return flight.leg!;
    }

    return 'UNKNOWN';
  }

  Future<void> _fetchAirportsForCountry(String countryCode) async {
    final deviceProvider = context.read<DeviceProvider>();
    final deviceUuid = deviceProvider.deviceUuid;
    final deviceToken = deviceProvider.deviceToken;

    if (deviceUuid == null || deviceToken == null) {
      debugPrint('⚠️ device 정보 없음 → 공항 목록 호출 생략');
      return;
    }

    await context.read<ReferenceProvider>().fetchAirports(
      deviceUuid: deviceUuid,
      deviceToken: deviceToken,
      countryCode: countryCode,
      activeOnly: true,
      limit: 100,
    );
  }

  Future<void> _fetchCabinClassesForAirline(String airlineCode) async {
    final deviceProvider = context.read<DeviceProvider>();
    final deviceUuid = deviceProvider.deviceUuid;
    final deviceToken = deviceProvider.deviceToken;

    if (deviceUuid == null || deviceToken == null) {
      debugPrint('⚠️ device 정보 없음 → cabin_classes 호출 생략');
      return;
    }

    await context.read<ReferenceProvider>().fetchCabinClasses(
      deviceUuid: deviceUuid,
      deviceToken: deviceToken,
      airlineCode: airlineCode,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    debugPrint('▶️ [_submit] start, inputMode=$_inputMode');

    final tripProvider = context.read<TripProvider>();
    final deviceProvider = context.read<DeviceProvider>();

    final deviceUuid = deviceProvider.deviceUuid;
    final deviceToken = deviceProvider.deviceToken;

    debugPrint(
        '▶️ deviceUuid=$deviceUuid, deviceToken=${deviceToken != null ? 'exists' : 'null'}');

    if (deviceUuid == null || deviceToken == null) {
      _showError('기기 등록 중입니다. 잠시 후 다시 시도해 주세요.');
      debugPrint('⛔ device 정보 없음 → submit 중단');
      return;
    }

    final titleInput = _tripTitleController.text.trim();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      Trip newTrip;

      if (_inputMode == 0) {
        // 편명 기반 Trip 생성

        final goCode = _outboundFlightController.text.trim();
        final backCode = _returnFlightController.text.trim();

        debugPrint('✈️ lookup outbound flight: $goCode');
        final goFlight = await _tripApi.lookupFlight(
          deviceUuid: deviceUuid,
          deviceToken: deviceToken,
          flightCode: goCode,
        );

        debugPrint('✈️ lookup return flight: $backCode');
        final backFlight = await _tripApi.lookupFlight(
          deviceUuid: deviceUuid,
          deviceToken: deviceToken,
          flightCode: backCode,
        );

        final title =
        titleInput.isEmpty ? '$goCode / $backCode 여행' : titleInput;

        final segments = <TripSegmentInput>[
          TripSegmentInput(
            leg: _buildLegString(goFlight),
            operating: goFlight.airlineIata,
            cabinClass: 'economy',
          ),
          TripSegmentInput(
            leg: _buildLegString(backFlight),
            operating: backFlight.airlineIata,
            cabinClass: 'economy',
          ),
        ];

        debugPrint(
          'createTrip 요청: title=$title, '
              'from=${goFlight.departureAirportIata}, '
              'to=${goFlight.arrivalAirportIata}',
        );

        final created = await _tripApi.createTrip(
          deviceUuid: deviceUuid,
          deviceToken: deviceToken,
          title: title,
          fromAirport: goFlight.departureAirportIata,
          toAirport: goFlight.arrivalAirportIata,
          startDate: null,
          endDate: null,
          segments: segments,
        );

        debugPrint('createTrip 성공: tripId=${created.tripId}');

        final duration = _calcDuration(created.startDate, created.endDate);

        newTrip = Trip(
          id: created.tripId.toString(),
          name: created.title,
          destination: created.to ?? goFlight.arrivalAirportName,
          startDate: created.startDate,
          duration: duration,
        );
      } else {
        final refProvider = context.read<ReferenceProvider>();
        final countries = refProvider.countries;

        final fromCountryCode = _fromCountryCode!;
        final toCountryCode = _toCountryCode!;
        final fromAirportIata = _fromAirportIata!;
        final toAirportIata = _toAirportIata!;
        final airlineCode = _airlineCode!;
        final seatClass = _seatClass!;

        final fromCountry = _countryByCode(countries, fromCountryCode);
        final toCountry = _countryByCode(countries, toCountryCode);

        final fromAirports =
        refProvider.airportsForCountry(fromCountryCode);
        final toAirports =
        refProvider.airportsForCountry(toCountryCode);

        final fromAirport =
        _airportByIata(fromAirports, fromAirportIata);
        final toAirport =
        _airportByIata(toAirports, toAirportIata);

        final fromCountryName = (fromCountry?.nameKo.isNotEmpty ?? false)
            ? fromCountry!.nameKo
            : (fromCountry?.nameEn ?? fromCountryCode);
        final toCountryName = (toCountry?.nameKo.isNotEmpty ?? false)
            ? toCountry!.nameKo
            : (toCountry?.nameEn ?? toCountryCode);

        final fromAirportName = (fromAirport?.nameKo.isNotEmpty ?? false)
            ? '${fromAirport!.nameKo} (${fromAirport.iataCode})'
            : (fromAirport != null
            ? '${fromAirport.nameEn} (${fromAirport.iataCode})'
            : fromAirportIata);
        final toAirportName = (toAirport?.nameKo.isNotEmpty ?? false)
            ? '${toAirport!.nameKo} (${toAirport.iataCode})'
            : (toAirport != null
            ? '${toAirport.nameEn} (${toAirport.iataCode})'
            : toAirportIata);

        final airlineDisplay = _airlineName ?? airlineCode;
        final title =
        titleInput.isEmpty ? '$toCountryName 여행' : titleInput;

        // 여기서 실제 Trip 생성 API 호출
        final created = await _tripApi.createTrip(
          deviceUuid: deviceUuid,
          deviceToken: deviceToken,
          title: title,
          fromAirport: fromAirportIata,
          toAirport: toAirportIata,
          startDate: null,
          endDate: null,
          segments: [
            TripSegmentInput(
              leg: '$fromAirportIata-$toAirportIata',
              operating: airlineCode,
              // 좌석 등급 코드(Y/J/F 등)랑 매핑하면 좋지만
              // 일단은 economy로 고정해서 보내도 규정 조회는 가능
              cabinClass: 'economy',
            ),
          ],
        );

        newTrip = Trip(
          id: created.tripId.toString(),
          name: created.title,
          destination: '$toCountryName $toAirportName',
          startDate: _todayIso(),
          duration: '왕복 · $airlineDisplay · $seatClass',
        );

        debugPrint(
          '수동 입력 Trip 생성 & 서버 등록 완료: '
              '$fromCountryName $fromAirportName → $toCountryName $toAirportName '
              '(tripId=${created.tripId})',
        );
      }

      tripProvider.addTrip(newTrip);
      tripProvider.setCurrentTrip(newTrip.id);
      debugPrint(
          'TripProvider 업데이트 완료: trips=${tripProvider.trips.length}, currentTripId=${tripProvider.currentTripId}');

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        debugPrint('➡️ /luggage 로 이동');
        context.go('/luggage');
      }
    } catch (e, st) {
      Navigator.of(context, rootNavigator: true).pop();
      debugPrint('❌ [_submit] 에러: $e\n$st');
      _showError('여행 정보를 불러오지 못했어요.\n${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('첫 여행 설정'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              // 건너뛰기: 바로 스캔 화면으로
              context.go('/scan');
            },
            child: Text(
              '건너뛰기',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary, // 빨간색으로 보이게!
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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

              TextFormField(
                controller: _tripTitleController,
                decoration: const InputDecoration(
                  labelText: '여행 이름 (예: 오사카 3박 4일)',
                  hintText: '입력하지 않으면 편명을 기반으로 자동 생성돼요.',
                ),
              ),
              const SizedBox(height: 20),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ToggleButtons(
                  isSelected: [
                    _inputMode == 0,
                    _inputMode == 1,
                  ],
                  onPressed: (index) {
                    setState(() => _inputMode = index);
                  },
                  borderRadius: BorderRadius.circular(12),
                  constraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 40,
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '편명으로 입력',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '국가/공항으로 입력',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
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
          validator: (value) => value == null || value.trim().isEmpty
              ? '가는 편명을 입력해 주세요.'
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _returnFlightController,
          decoration: const InputDecoration(
            labelText: '오는 편명 (예: KE124)',
          ),
          textCapitalization: TextCapitalization.characters,
          validator: (value) => value == null || value.trim().isEmpty
              ? '오는 편명을 입력해 주세요.'
              : null,
        ),
        const SizedBox(height: 16),
        const Text(
          '※ 편명 기준으로 항공 규정·경로 정보를 자동으로 가져올 수 있어요.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDetailForm() {
    final refProvider = context.watch<ReferenceProvider>();
    final countries = refProvider.countries;
    final airlines = refProvider.airlines;

    final countryItems = countries.map((country) {
      final label = country.nameKo.isNotEmpty ? country.nameKo : country.nameEn;
      return DropdownMenuItem<String>(
        value: country.code,
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    }).toList();

    // 선택된 국가별 공항 리스트
    final fromAirports = _fromCountryCode == null
        ? const <AirportRef>[]
        : refProvider.airportsForCountry(_fromCountryCode!);
    final toAirports = _toCountryCode == null
        ? const <AirportRef>[]
        : refProvider.airportsForCountry(_toCountryCode!);

    // 선택된 항공사의 좌석 등급
    final cabinClasses = _airlineCode == null
        ? const <CabinClassRef>[]
        : refProvider.cabinClassesForAirline(_airlineCode!);

    List<DropdownMenuItem<String>> _airportItems(
        List<AirportRef> airports,
        ) {
      return airports.map((a) {
        final label = a.nameKo.isNotEmpty
            ? '${a.nameKo} (${a.iataCode})'
            : '${a.nameEn} (${a.iataCode})';
        return DropdownMenuItem<String>(
          value: a.iataCode,
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList();
    }

    // 좌석 등급 드롭다운 아이템
    List<DropdownMenuItem<String>> _seatClassItems() {
      if (cabinClasses.isNotEmpty) {
        // 중복 제거를 위해 Set 사용
        final seen = <String>{};
        return cabinClasses
            .where((c) => seen.add(c.name)) // 중복 제거
            .map(
              (c) => DropdownMenuItem<String>(
            value: c.name,
            child: Text(
              c.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        )
            .toList();
      }

      // API 실패 / 아직 로딩 전일 때 fallback
      return _defaultSeatClasses
          .map(
            (s) => DropdownMenuItem<String>(
          value: s,
          child: Text(
            s,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      )
          .toList();
    }

    // 현재 선택된 좌석 등급이 items에 유효한지 확인
    String? _getValidSeatClass() {
      if (_seatClass == null) return null;
      
      final items = _seatClassItems();
      final hasValidValue = items.any((item) => item.value == _seatClass);
      
      // 유효하지 않으면 null 반환 (리셋)
      if (!hasValidValue) {
        // 다음 프레임에서 _seatClass를 null로 설정
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _seatClass = null;
            });
          }
        });
        return null;
      }
      
      return _seatClass;
    }

    return Column(
      key: const ValueKey('detailForm'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '왕복 기준 출발·도착 정보를 입력해 주세요.',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (refProvider.isLoadingCountries && countries.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(),
          ),
        if (refProvider.countriesError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '국가 목록을 불러오지 못했어요 😢\n${refProvider.countriesError}',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
        if (refProvider.isLoadingAirports)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(),
          ),
        if (refProvider.airportsError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '공항 목록을 불러오지 못했어요 😢\n${refProvider.airportsError}',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
        if (refProvider.isLoadingAirlines && airlines.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(),
          ),
        if (refProvider.airlinesError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '항공사 목록을 불러오지 못했어요 😢\n${refProvider.airlinesError}',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
        if (refProvider.isLoadingCabinClasses && _airlineCode != null)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(),
          ),
        if (refProvider.cabinClassesError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '좌석 등급을 불러오지 못했어요 😢\n${refProvider.cabinClassesError}',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
        const SizedBox(height: 8),

        // 출발 국가
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _fromCountryCode,
          decoration: const InputDecoration(labelText: '출발 국가'),
          items: countryItems,
          onChanged: (value) {
            setState(() {
              _fromCountryCode = value;
              _fromAirportIata = null;
            });
            if (value != null) {
              _fetchAirportsForCountry(value);
            }
          },
          validator: (value) => value == null ? '출발 국가를 선택해 주세요.' : null,
        ),
        const SizedBox(height: 8),

        // 출발 공항
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _fromAirportIata,
          decoration: const InputDecoration(labelText: '출발 공항'),
          items: _airportItems(fromAirports),
          onChanged: (_fromCountryCode == null)
              ? null
              : (value) {
            setState(() => _fromAirportIata = value);
          },
          validator: (value) =>
          value == null ? '출발 공항을 선택해 주세요.' : null,
        ),
        const SizedBox(height: 16),

        // 도착 국가
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _toCountryCode,
          decoration: const InputDecoration(labelText: '도착 국가'),
          items: countryItems,
          onChanged: (value) {
            setState(() {
              _toCountryCode = value;
              _toAirportIata = null;
            });
            if (value != null) {
              _fetchAirportsForCountry(value);
            }
          },
          validator: (value) => value == null ? '도착 국가를 선택해 주세요.' : null,
        ),
        const SizedBox(height: 8),

        // 도착 공항
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _toAirportIata,
          decoration: const InputDecoration(labelText: '도착 공항'),
          items: _airportItems(toAirports),
          onChanged: (_toCountryCode == null)
              ? null
              : (value) {
            setState(() => _toAirportIata = value);
          },
          validator: (value) => value == null ? '도착 공항을 선택해 주세요.' : null,
        ),
        const SizedBox(height: 16),

        // 항공사
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _airlineCode,
          decoration: const InputDecoration(labelText: '항공사'),
          items: airlines.map((air) {
            return DropdownMenuItem<String>(
              value: air.code,
              child: Text(
                air.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _airlineCode = value;
              _seatClass = null;

              if (value != null) {
                final selected = airlines.firstWhere(
                      (a) => a.code == value,
                  orElse: () => AirlineRef(code: value, name: value),
                );
                _airlineName = selected.name;
                _fetchCabinClassesForAirline(value);
              } else {
                _airlineName = null;
              }
            });
          },
          validator: (value) => value == null ? '항공사를 선택해 주세요.' : null,
        ),
        const SizedBox(height: 16),

        // 좌석 등급
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _getValidSeatClass(),
          decoration: const InputDecoration(labelText: '좌석 등급'),
          items: _seatClassItems(),
          onChanged: (_airlineCode == null)
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
