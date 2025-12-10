// lib/widgets/travel_recommendations.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/trip.dart';
import '../providers/trip_provider.dart';
import '../providers/device_provider.dart';
import '../service/recommendation_api.dart';

class TravelRecommendations extends StatefulWidget {
  final Trip trip;

  const TravelRecommendations({super.key, required this.trip});

  @override
  State<TravelRecommendations> createState() => _TravelRecommendationsState();
}

class _TravelRecommendationsState extends State<TravelRecommendations>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _startDate = '';
  String _endDate = '';

  bool _isLoading = false;
  TripRecommendation? _recommendation;
  TripClimate? _climate;

  // ====== FX 환율 계산기 상태 ======
  final TextEditingController _amountController = TextEditingController();
  String? _fxResult;
  bool _isFxLoading = false;

  // 마지막으로 조회한 환율 정보 (에러 시 fallback용 + 상단 표시용)
  double? _lastFxRate; // base -> symbol (예: 1 KRW = 0.00068 USD)
  String? _fxBase;     // base 통화 코드 (예: KRW)
  String? _fxSymbol;   // 목적 통화 코드 (예: USD)
  String? _fxAsOf;     // 기준일(as_of)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 날씨 / 짐 / 쇼핑
    _initDatesFromTrip();
  }

  @override
  void didUpdateWidget(covariant TravelRecommendations oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 선택된 trip 이 바뀌면 날짜/추천/환율계산기 리셋
    if (oldWidget.trip.id != widget.trip.id) {
      _initDatesFromTrip();
      _amountController.clear();
      setState(() {
        _recommendation = null;
        _climate = null;
        _fxResult = null;
        _lastFxRate = null;
        _fxBase = null;
        _fxSymbol = null;
        _fxAsOf = null;
      });
    }
  }

  void _initDatesFromTrip() {
    _startDate = widget.trip.startDate;
    // endDate는 사용자가 직접 선택.
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final trip = widget.trip;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              '여행 추천',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall!
                  .copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '${trip.name} · ${trip.destination}',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          _buildSearchCard(),
          if (_recommendation != null) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.location_on, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  '${_recommendation!.city} (${_recommendation!.countryCode})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTabView(),
          ],
        ],
      ),
    );
  }

  // ====== 상단 카드 (기간 입력 + 버튼) ======

  Widget _buildSearchCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    label: '출발 날짜',
                    value: _startDate,
                    onPicked: (d) {
                      setState(() => _startDate = d);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateField(
                    label: '귀국 날짜',
                    value: _endDate,
                    onPicked: (d) {
                      setState(() => _endDate = d);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_startDate.isNotEmpty &&
                    _endDate.isNotEmpty &&
                    !_isLoading)
                    ? _onGeneratePressed
                    : null,
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
                    Text('추천 생성 중...'),
                  ],
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 8),
                    Text('맞춤 추천 받기'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required ValueChanged<String> onPicked,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      readOnly: true,
      controller: TextEditingController(text: value),
      onTap: () async {
        final now = DateTime.now();
        DateTime initial = now;
        if (value.isNotEmpty) {
          try {
            initial = DateTime.parse(value);
          } catch (_) {}
        }
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(now.year, now.month, now.day),
          lastDate: now.add(const Duration(days: 365)),
        );
        if (picked != null) {
          final str =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          onPicked(str);
        }
      },
    );
  }

  // ====== 탭 ======

  Widget _buildTabView() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: '날씨 · 환율'),
            Tab(text: '짐 추천'),
            Tab(text: '쇼핑 가이드'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 460, // 각 탭 내용은 안에서 스크롤
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildWeatherTab(),
              _buildItemsTab(),
              _buildShoppingTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ====== 날씨 · 환율 탭 ======

  Widget _buildWeatherTab() {
    final cs = Theme.of(context).colorScheme;
    final rec = _recommendation!;
    final climate = _climate;

    // 기본값은 recommendation.weather 기준
    double temp = rec.weather.temperatureC;
    double feels = rec.weather.feelsLikeC;
    int humidity = rec.weather.humidity;
    String summary = rec.weather.summary;

    // 서버에서 weather 를 null로 내려줄 때를 대비해서
    // climate 가 있으면 그쪽 값을 우선 사용
    if (climate != null) {
      temp = climate.recentStats.tMeanC;
      feels = climate.recentStats.tMeanC; // 체감온도는 일단 평균으로 대체
      summary = '최근 ${climate.usedYears.length}년 기후 평균 기준';
    }

    final hasStaticFx = rec.exchangeRate.currencyCode.isNotEmpty &&
        rec.exchangeRate.baseCurrency.isNotEmpty &&
        rec.exchangeRate.rate > 0;

    final hasRuntimeFx =
        _lastFxRate != null && _fxBase != null && _fxSymbol != null;

    // TextField 라벨에 쓸 기준 통화
    final baseCurrencyLabel = rec.exchangeRate.baseCurrency.isNotEmpty
        ? rec.exchangeRate.baseCurrency
        : (_fxBase ?? 'KRW');

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.wb_sunny_rounded, color: cs.primary),
                  const SizedBox(width: 8),
                  const Text(
                    '현지 날씨 · 환율',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                summary.isEmpty ? '날씨 요약 정보를 불러오지 못했어요.' : summary,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '기온: ${temp.toStringAsFixed(1)}°C '
                    '(체감 ${feels.toStringAsFixed(1)}°C)',
              ),
              const SizedBox(height: 4),
              Text(
                climate != null && humidity == 0
                    ? '습도: -'
                    : '습도: ${humidity}%',
              ),
              if (climate != null) ...[
                const SizedBox(height: 4),
                Text(
                  '최저/최고: '
                      '${climate.recentStats.tMinC.toStringAsFixed(1)}°C'
                      ' / ${climate.recentStats.tMaxC.toStringAsFixed(1)}°C',
                ),
                const SizedBox(height: 4),
                Text(
                  '총 강수량: '
                      '${climate.recentStats.precipSumMm.toStringAsFixed(1)} mm',
                ),
              ],
              const Divider(height: 24),

              // ====== 환율 정보 영역 ======
              Text(
                '환율 정보',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),

              // 1순위: 백엔드에서 내려준 exchange_rate
              if (hasStaticFx) ...[
                Text(
                  '1 ${rec.exchangeRate.currencyCode} ≈ '
                      '${rec.exchangeRate.rate.toStringAsFixed(2)} '
                      '${rec.exchangeRate.baseCurrency}',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  '업데이트: ${rec.exchangeRate.lastUpdated}',
                  style:
                  TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ]
              // 2순위: 사용자가 방금 FX API로 조회한 값
              else if (hasRuntimeFx) ...[
                // convert API: rate = base -> symbol (예: 1 KRW = 0.00068 USD)
                // 우리가 보여주고 싶은 건 1 USD ≈ 1470 KRW 이라서 역수 사용
                Text(
                  '1 ${_fxSymbol!} ≈ '
                      '${(1 / _lastFxRate!).toStringAsFixed(2)} ${_fxBase!}',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  '업데이트: ${_fxAsOf ?? '-'}',
                  style:
                  TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ]
              // 둘 다 없으면
              else ...[
                  Text(
                    '환율 정보를 불러오지 못했어요.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],

              // ====== 환율 계산기 UI (항상 노출) ======
              const SizedBox(height: 20),
              Text(
                '간단 환율 계산기',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '금액 ($baseCurrencyLabel)',
                  hintText: '예: 100000',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isFxLoading ? null : _onConvertFxPressed,
                  child: _isFxLoading
                      ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('현지 통화로 환전하기'),
                ),
              ),
              if (_fxResult != null) ...[
                const SizedBox(height: 8),
                Text(
                  _fxResult!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ====== 짐 추천 탭 ======

  Widget _buildItemsTab() {
    final cs = Theme.of(context).colorScheme;
    final rec = _recommendation!;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.checklist_rounded, color: cs.primary),
                  const SizedBox(width: 8),
                  const Text(
                    '추천 짐 아이템',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (rec.popularItems.isEmpty)
                Text(
                  '추천 아이템 정보가 아직 없어요.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                )
              else
                ...rec.popularItems.map(
                      (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          margin:
                          const EdgeInsets.only(top: 6, right: 8),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const Divider(height: 24),
              Text(
                '옷차림 팁',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                rec.outfitTip,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====== 쇼핑 가이드 탭 ======

  Widget _buildShoppingTab() {
    final cs = Theme.of(context).colorScheme;
    final rec = _recommendation!;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_bag_rounded, color: cs.primary),
                  const SizedBox(width: 8),
                  const Text(
                    '현지 쇼핑 가이드',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                rec.shoppingGuide.isEmpty
                    ? '현지 쇼핑 가이드가 아직 준비되지 않았어요.'
                    : rec.shoppingGuide,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====== 버튼 눌렀을 때 추천 생성 API 흐름 ======

  Future<void> _onGeneratePressed() async {
    final device = context.read<DeviceProvider>();
    final tripProvider = context.read<TripProvider>();
    final trip = tripProvider.currentTrip;

    if (device.deviceUuid == null ||
        device.deviceToken == null ||
        trip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('여행 또는 기기 정보가 올바르지 않아요.')),
      );
      return;
    }

    final api = RecommendationApiService();
    final tripId = int.parse(trip.id);

    setState(() {
      _isLoading = true;
      _fxResult = null;
      _lastFxRate = null;
      _fxBase = null;
      _fxSymbol = null;
      _fxAsOf = null;
    });

    try {
      // 1) 기간 업데이트
      await api.updateTripDuration(
        deviceUuid: device.deviceUuid!,
        deviceToken: device.deviceToken!,
        tripId: tripId,
        startDate: _startDate,
        endDate: _endDate,
      );

      // 2) 옷차림/기후 분석 생성
      await api.generateOutfitRecommendation(
        deviceUuid: device.deviceUuid!,
        deviceToken: device.deviceToken!,
        tripId: tripId,
      );

      // 3) 통합 추천 조회
      final rec = await api.getTripRecommendation(
        deviceUuid: device.deviceUuid!,
        deviceToken: device.deviceToken!,
        tripId: tripId,
      );

      // 4) 기후 정보 조회
      final climate = await api.getTripClimate(
        deviceUuid: device.deviceUuid!,
        deviceToken: device.deviceToken!,
        tripId: tripId,
      );

      if (!mounted) return;
      setState(() {
        _recommendation = rec;
        _climate = climate;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('추천을 불러오지 못했어요: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // ====== 국가코드 → 통화코드 간단 매핑 ======

  String _guessCurrencyFromCountry(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'US':
        return 'USD';
      case 'JP':
        return 'JPY';
      case 'GB':
        return 'GBP';
      case 'EU':
      case 'DE':
      case 'FR':
      case 'IT':
      case 'ES':
        return 'EUR';
      case 'CN':
        return 'CNY';
      case 'HK':
        return 'HKD';
      case 'TW':
        return 'TWD';
      case 'AU':
        return 'AUD';
      case 'CA':
        return 'CAD';
      case 'TH':
        return 'THB';
      case 'VN':
        return 'VND';
      case 'SG':
        return 'SGD';
      default:
        return 'USD';
    }
  }

  // ====== 환율 계산기 버튼 눌렀을 때 ======

  Future<void> _onConvertFxPressed() async {
    final rec = _recommendation;
    if (rec == null) return;

    final device = context.read<DeviceProvider>();
    if (device.deviceUuid == null || device.deviceToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기기 정보를 불러오지 못했어요. 앱을 다시 시작해 주세요.')),
      );
      return;
    }

    // 기본 통화는 KRW로 가정, 서버에서 exchange_rate가 채워지면 그걸 우선 사용
    String base = rec.exchangeRate.baseCurrency.isNotEmpty
        ? rec.exchangeRate.baseCurrency
        : 'KRW';
    String target = rec.exchangeRate.currencyCode.isNotEmpty
        ? rec.exchangeRate.currencyCode
        : _guessCurrencyFromCountry(rec.countryCode);

    final rawText = _amountController.text.replaceAll(',', '').trim();
    final amount = double.tryParse(rawText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 금액을 입력해 주세요.')),
      );
      return;
    }

    final api = RecommendationApiService();

    setState(() {
      _isFxLoading = true;
      _fxResult = null;
    });

    try {
      final json = await api.convertFx(
        deviceUuid: device.deviceUuid!,
        deviceToken: device.deviceToken!,
        from: base,
        to: target,
        amount: amount,
      );

      double? result;
      double? rate;

      // 실제 응답: { base, symbol, amount, rate, converted, as_of, ... }
      if (json['converted'] is num) {
        result = (json['converted'] as num).toDouble();
      }
      if (json['rate'] is num) {
        rate = (json['rate'] as num).toDouble();
      }

      // 방어적으로 다른 키 이름도 체크
      if (result == null && json['result'] is num) {
        result = (json['result'] as num).toDouble();
      }
      if (result == null && json['converted_amount'] is num) {
        result = (json['converted_amount'] as num).toDouble();
      }
      if (result == null && rate != null) {
        result = amount * rate!;
      }

      // 메타 정보 저장 (상단 환율 표시용)
      _lastFxRate = rate;
      _fxBase = (json['base'] as String?) ?? base;
      _fxSymbol = (json['symbol'] as String?) ?? target;
      _fxAsOf = json['as_of'] as String?;

      if (result == null) {
        setState(() {
          _fxResult = '환율 정보를 불러오지 못했어요.';
        });
      } else {
        final baseCode = _fxBase ?? base;
        final targetCode = _fxSymbol ?? target;
        setState(() {
          _fxResult =
          '${amount.toStringAsFixed(0)} $baseCode ≈ ${result!.toStringAsFixed(2)} $targetCode';
        });
      }
    } catch (e) {
      // 에러 시: 이전에 저장된 rate 나 recommendation 의 rate 로 근사 계산
      final double? rate =
          _lastFxRate ?? (rec.exchangeRate.rate > 0 ? rec.exchangeRate.rate : null);
      final String baseCode = base;
      final String targetCode = target;

      if (rate != null && rate > 0) {
        final fallback = amount * rate;
        setState(() {
          _fxResult =
          '${amount.toStringAsFixed(0)} $baseCode ≈ ${fallback.toStringAsFixed(2)} $targetCode (저장된 환율 기준)';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('환율 변환에 실패했어요: $e')),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() => _isFxLoading = false);
    }
  }
}
