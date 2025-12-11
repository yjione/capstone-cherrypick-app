/// lib/screens/initial_trip_screen.dart
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

  final _tripTitleController = TextEditingController();

  final _outboundFlightController = TextEditingController();
  final _returnFlightController = TextEditingController();

  String? _fromCountryCode;
  String? _fromAirportIata;
  String? _toCountryCode;
  String? _toAirportIata;
  String? _airlineCode;
  String? _airlineName;
  String? _seatClass;

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

      await deviceProvider.registerIfNeeded(
        appVersion: '1.0.0',
        os: 'android', // 실제 플랫폼에 맞게 수정
        model: 'test-device',
        locale: 'ko-KR',
        timezone: '+09:00',
        deviceUuid: 'dummy-device-1234', // 실제 UUID로 교체
      );

      final deviceUuid = deviceProvider.deviceUuid;
      final deviceToken = deviceProvider.deviceToken;

      if (deviceUuid != null && deviceToken != null) {
        debugPrint('🌍 국가 목록 fetchCountries 호출');
        await refProvider.fetchCountries(
          deviceUuid: deviceUuid,
          deviceToken: deviceToken,
          activeOnly: true,
        );

        debugPrint('✈️ 항공사 목록 fetchAirlines 호출');
        await refProvider.fetchAirlines(
          deviceUuid: deviceUuid,
          deviceToken: deviceToken,
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

  // ---------------------------------------------------------------------------
  //  바텀시트 선택 로직
  // ---------------------------------------------------------------------------

  Future<String?> _selectCountryBottomSheet({
    required String title,
    String? initialCode,
  }) async {
    final refProvider = context.read<ReferenceProvider>();
    final countries = refProvider.countries;

    if (countries.isEmpty) {
      _showError('국가 목록을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.');
      return null;
    }

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;

        return SafeArea(
          child: SizedBox(
            height: screenHeight * 0.65,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView.builder(
                    itemCount: countries.length,
                    itemBuilder: (context, index) {
                      final c = countries[index];
                      final label =
                      c.nameKo.isNotEmpty ? c.nameKo : c.nameEn ?? c.code;
                      final selected = c.code == initialCode;
                      return ListTile(
                        title: Text(label),
                        subtitle: Text(
                          c.code,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing:
                        selected ? const Icon(Icons.check, size: 18) : null,
                        onTap: () {
                          Navigator.pop(context, c.code);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _selectAirportBottomSheet({
    required String title,
    required String countryCode,
    String? initialIata,
  }) async {
    final refProvider = context.read<ReferenceProvider>();
    final airports = refProvider.airportsForCountry(countryCode);

    if (airports.isEmpty) {
      _showError('해당 국가의 공항 목록을 불러오지 못했어요.');
      return null;
    }

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;

        return SafeArea(
          child: SizedBox(
            height: screenHeight * 0.65,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView.builder(
                    itemCount: airports.length,
                    itemBuilder: (context, index) {
                      final a = airports[index];
                      final label = a.nameKo.isNotEmpty
                          ? '${a.nameKo} (${a.iataCode})'
                          : '${a.nameEn} (${a.iataCode})';
                      final selected = a.iataCode == initialIata;
                      return ListTile(
                        title: Text(label),
                        trailing:
                        selected ? const Icon(Icons.check, size: 18) : null,
                        onTap: () {
                          Navigator.pop(context, a.iataCode);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectFromRoute() async {
    // 1) 국가 선택
    final countryCode = await _selectCountryBottomSheet(
      title: '출발 국가 선택',
      initialCode: _fromCountryCode,
    );
    if (countryCode == null) return;

    await _fetchAirportsForCountry(countryCode);

    // 2) 공항 선택
    final airportIata = await _selectAirportBottomSheet(
      title: '출발 공항 선택',
      countryCode: countryCode,
      initialIata: _fromAirportIata,
    );
    if (airportIata == null) return;

    setState(() {
      _fromCountryCode = countryCode;
      _fromAirportIata = airportIata;
    });
  }

  Future<void> _selectToRoute() async {
    final countryCode = await _selectCountryBottomSheet(
      title: '도착 국가 선택',
      initialCode: _toCountryCode,
    );
    if (countryCode == null) return;

    await _fetchAirportsForCountry(countryCode);

    final airportIata = await _selectAirportBottomSheet(
      title: '도착 공항 선택',
      countryCode: countryCode,
      initialIata: _toAirportIata,
    );
    if (airportIata == null) return;

    setState(() {
      _toCountryCode = countryCode;
      _toAirportIata = airportIata;
    });
  }

  Future<void> _selectAirline() async {
    final refProvider = context.read<ReferenceProvider>();
    final airlines = refProvider.airlines;

    if (airlines.isEmpty) {
      _showError('항공사 목록을 불러오지 못했어요.');
      return;
    }

    final selectedCode = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;

        return SafeArea(
          child: SizedBox(
            height: screenHeight * 0.65,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '항공사 선택',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView.builder(
                    itemCount: airlines.length,
                    itemBuilder: (context, index) {
                      final a = airlines[index];
                      final selected = a.code == _airlineCode;
                      return ListTile(
                        title: Text(a.name),
                        subtitle: Text(
                          a.code,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing:
                        selected ? const Icon(Icons.check, size: 18) : null,
                        onTap: () {
                          Navigator.pop(context, a.code);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedCode == null) return;

    final airline = airlines.firstWhere(
          (a) => a.code == selectedCode,
      orElse: () => AirlineRef(code: selectedCode, name: selectedCode),
    );

    await _fetchCabinClassesForAirline(selectedCode);

    setState(() {
      _airlineCode = selectedCode;
      _airlineName = airline.name;
      _seatClass = null; // 항공사 바꾸면 좌석 초기화
    });
  }

  Future<void> _selectSeatClass() async {
    if (_airlineCode == null) {
      _showError('먼저 항공사를 선택해 주세요.');
      return;
    }

    final refProvider = context.read<ReferenceProvider>();
    final cabinClasses = refProvider.cabinClassesForAirline(_airlineCode!);

    final items = cabinClasses.isNotEmpty
        ? cabinClasses.map((c) => c.name).toList()
        : _defaultSeatClasses;

    final selectedName = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;

        return SafeArea(
          child: SizedBox(
            height: screenHeight * 0.5,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '좌석 등급 선택',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final name = items[index];
                      final selected = name == _seatClass;
                      return ListTile(
                        title: Text(name),
                        trailing:
                        selected ? const Icon(Icons.check, size: 18) : null,
                        onTap: () {
                          Navigator.pop(context, name);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedName == null) return;

    setState(() {
      _seatClass = selectedName;
    });
  }

  // ---------------------------------------------------------------------------
  //  Submit
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // 수동 입력 모드일 때는 선택 여부를 수동으로 검사
    if (_inputMode == 1) {
      if (_fromCountryCode == null ||
          _fromAirportIata == null ||
          _toCountryCode == null ||
          _toAirportIata == null ||
          _airlineCode == null ||
          _seatClass == null) {
        _showError('왕복 정보를 모두 선택해 주세요.');
        return;
      }
    }

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

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('첫 여행 설정'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => context.go('/luggage'),
            child: Text(
              '건너뛰기',
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w700,
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
    final cs = Theme.of(context).colorScheme;

    String _fromLabel() {
      if (_fromCountryCode == null || _fromAirportIata == null) {
        return '출발 국가/공항 선택';
      }
      return '$_fromCountryCode · $_fromAirportIata';
    }

    String _toLabel() {
      if (_toCountryCode == null || _toAirportIata == null) {
        return '도착 국가/공항 선택';
      }
      return '$_toCountryCode · $_toAirportIata';
    }

    String _airlineLabel() {
      return _airlineName ?? '항공사 선택';
    }

    String _seatClassLabel() {
      return _seatClass ?? '좌석 등급 선택';
    }

    return Column(
      key: const ValueKey('detailForm'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '왕복 기준 출발·도착 정보를 입력해 주세요.',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: cs.surfaceVariant.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _RouteTile(
                label: '출발지',
                value: _fromLabel(),
                onTap: _selectFromRoute,
              ),
              const Divider(height: 1),
              _RouteTile(
                label: '도착지',
                value: _toLabel(),
                onTap: _selectToRoute,
              ),
              const Divider(height: 1),
              _RouteTile(
                label: '항공사',
                value: _airlineLabel(),
                onTap: _selectAirline,
              ),
              const Divider(height: 1),
              _RouteTile(
                label: '좌석 등급',
                value: _seatClassLabel(),
                onTap: _selectSeatClass,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '※ 입력하신 왕복 구간을 기준으로 항공 규정을 계산할 수 있어요.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class _RouteTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _RouteTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPlaceholder = value.contains('선택');

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: onTap,
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          color: isPlaceholder
              ? cs.onSurfaceVariant.withOpacity(0.6)
              : cs.onSurface,
          fontWeight: isPlaceholder ? FontWeight.w400 : FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
