// lib/widgets/travel_recommendations.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/trip.dart';
import '../providers/trip_provider.dart';
import '../providers/device_provider.dart';
import '../providers/packing_provider.dart';
import '../service/recommendation_api.dart';
import '../service/bag_api.dart';

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

  // FX
  final TextEditingController _amountController = TextEditingController();
  String? _fxResult;
  bool _isFxLoading = false;
  bool _hasTriedFx = false;

  double? _lastFxRate;
  String? _fxBase;
  String? _fxSymbol;
  String? _fxAsOf;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initDatesFromTrip();
  }

  @override
  void didUpdateWidget(covariant TravelRecommendations oldWidget) {
    super.didUpdateWidget(oldWidget);

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
        _hasTriedFx = false;
      });
    }
  }

  void _initDatesFromTrip() {
    _startDate = widget.trip.startDate;
    _endDate = '';
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

  // -------------------------------------------------------------
  // 날짜 카드 + 추천 생성 버튼
  // -------------------------------------------------------------
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
                    onPicked: (d) => setState(() => _startDate = d),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateField(
                    label: '귀국 날짜',
                    value: _endDate,
                    onPicked: (d) => setState(() => _endDate = d),
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

        try {
          if (value.isNotEmpty) initial = DateTime.parse(value);
        } catch (_) {}

        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(now.year, now.month, now.day),
          lastDate: now.add(const Duration(days: 365)),
        );
        if (picked != null) {
          final s =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          onPicked(s);
        }
      },
    );
  }

  // -------------------------------------------------------------
  // TabView
  // -------------------------------------------------------------
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
          height: 460,
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

  // -------------------------------------------------------------
  // 날씨 · 환율 탭
  // -------------------------------------------------------------
  Widget _buildWeatherTab() {
    final cs = Theme.of(context).colorScheme;
    final rec = _recommendation!;
    final climate = _climate;

    double temp = rec.weather.temperatureC;
    double feels = rec.weather.feelsLikeC;
    int humidity = rec.weather.humidity;
    String summary = rec.weather.summary;

    if (climate != null) {
      temp = climate.recentStats.tMeanC;
      feels = climate.recentStats.tMeanC;
      summary = '최근 평균 기온 기반';
    }

    final hasStaticFx = rec.exchangeRate.currencyCode.isNotEmpty &&
        rec.exchangeRate.baseCurrency.isNotEmpty &&
        rec.exchangeRate.rate > 0;

    final hasRuntimeFx =
        _lastFxRate != null && _fxBase != null && _fxSymbol != null;

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
                summary,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text('기온: ${temp.toStringAsFixed(1)}°C (체감 ${feels.toStringAsFixed(1)}°C)'),
              const SizedBox(height: 4),
              Text('습도: ${humidity == 0 ? "-" : "$humidity%"}'),

              if (climate != null) ...[
                const SizedBox(height: 4),
                Text(
                    '최저/최고: ${climate.recentStats.tMinC}°C / ${climate.recentStats.tMaxC}°C'),
                const SizedBox(height: 4),
                Text('총 강수량: ${climate.recentStats.precipSumMm.toStringAsFixed(1)} mm'),
              ],

              const Divider(height: 24),
              _buildFxCalculator(baseCurrencyLabel, rec, cs, hasStaticFx, hasRuntimeFx),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // FX 계산기 (날씨 탭 내부)
  // -------------------------------------------------------------
  Widget _buildFxCalculator(
      String baseCurrencyLabel,
      TripRecommendation rec,
      ColorScheme cs,
      bool hasStaticFx,
      bool hasRuntimeFx)
  {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],

        if (_hasTriedFx && (hasStaticFx || hasRuntimeFx))
          _buildFxInfo(rec, cs, hasStaticFx),
      ],
    );
  }

  Widget _buildFxInfo(TripRecommendation rec, ColorScheme cs, bool hasStaticFx) {
    String base;
    String symbol;
    double rate;
    String updated;

    if (hasStaticFx) {
      base = rec.exchangeRate.baseCurrency;
      symbol = rec.exchangeRate.currencyCode;
      rate = rec.exchangeRate.rate;
      updated = rec.exchangeRate.lastUpdated;
    } else {
      base = _fxBase ?? 'KRW';
      symbol = _fxSymbol ?? 'USD';
      rate = 1 / (_lastFxRate ?? 1);
      updated = _fxAsOf ?? '-';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          '환율 정보',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '1 $symbol ≈ ${rate.toStringAsFixed(2)} $base',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        Text(
          '업데이트: $updated',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 짐 추천 탭 (핵심 변경!)
  // -------------------------------------------------------------
  Widget _buildItemsTab() {
    final cs = Theme.of(context).colorScheme;
    final rec = _recommendation!;

    // GET /recommendation 에서 내려오는 인기 아이템 목록
    final popularItems = rec.popularItems;
    final outfit = rec.outfit; // optional — 서버 outfit 저장 안 되면 null

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

              // -----------------------------
              // ① popular_items 기반 표시
              // -----------------------------
              if (popularItems.isEmpty)
                Text(
                  '추천된 짐 정보가 아직 없어요.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                )
              else
                ...popularItems.map(
                      (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 8, right: 8),
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

              // -----------------------------
              // ② 요약 팁 — outfitTip + (optional outfit.description)
              // -----------------------------
              Text(
                '옷차림 팁',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),

              Text(
                outfit?.description ?? rec.outfitTip,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // -------------------------------------------------------------
  // 쇼핑 탭
  // -------------------------------------------------------------
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

  // -------------------------------------------------------------
  // 추천 생성 전체 흐름
  // -------------------------------------------------------------
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
      _hasTriedFx = false;
    });

    try {
      await api.updateTripDuration(
        deviceUuid: device.deviceUuid!,
        deviceToken: device.deviceToken!,
        tripId: tripId,
        startDate: _startDate,
        endDate: _endDate,
      );

      await api.generateOutfitRecommendation(
        deviceUuid: device.deviceUuid!,
        deviceToken: device.deviceToken!,
        tripId: tripId,
      );

      final rec = await api.getTripRecommendation(
        deviceUuid: device.deviceUuid!,
        deviceToken: device.deviceToken!,
        tripId: tripId,
      );

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('추천을 불러오지 못했어요: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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

    String base = rec.exchangeRate.baseCurrency.isNotEmpty
        ? rec.exchangeRate.baseCurrency
        : 'KRW';
    String target = rec.exchangeRate.currencyCode.isNotEmpty
        ? rec.exchangeRate.currencyCode
        : _guessCurrencyFromCountry(rec.countryCode);

    final raw = _amountController.text.replaceAll(',', '').trim();
    final amount = double.tryParse(raw);

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
      _hasTriedFx = true;
    });

    try {
      final json = await api.convertFx(
        deviceUuid: device.deviceUuid!,
        deviceToken: device.deviceToken!,
        from: base,
        to: target,
        amount: amount,
      );

      double? result = (json['converted'] ?? json['result'])?.toDouble();
      double? rate = (json['rate'] as num?)?.toDouble();

      if (result == null && rate != null) {
        result = amount * rate!;
      }

      _lastFxRate = rate;
      _fxBase = json['base'] ?? base;
      _fxSymbol = json['symbol'] ?? target;
      _fxAsOf = json['as_of'];

      setState(() {
        if (result == null) {
          _fxResult = '환율 정보를 불러오지 못했어요.';
        } else {
          _fxResult =
          '${amount.toStringAsFixed(0)} ${_fxBase} ≈ ${result.toStringAsFixed(2)} ${_fxSymbol}';
        }
      });
    } catch (e) {
      final saved =
          _lastFxRate ?? (rec.exchangeRate.rate > 0 ? rec.exchangeRate.rate : null);

      if (saved != null) {
        final fallback = amount * saved;
        setState(() {
          _fxResult =
          '${amount.toStringAsFixed(0)} $base ≈ ${fallback.toStringAsFixed(2)} $target (저장된 환율 기준)';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('환율 변환 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFxLoading = false);
    }
  }

  String _guessCurrencyFromCountry(String country) {
    switch (country) {
      case 'US':
        return 'USD';
      case 'JP':
        return 'JPY';
      case 'GB':
        return 'GBP';
      case 'FR':
      case 'DE':
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
}
