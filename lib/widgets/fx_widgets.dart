// lib/widgets/fx_widgets.dart
import 'package:flutter/material.dart';
import '../service/fx_api.dart';

class FxRateCard extends StatefulWidget {
  final FxApiService fxApi;
  final String baseCurrency;   // 예: "USD" (여행지 통화)
  final String symbolCurrency; // 예: "KRW" (항상 원화)

  const FxRateCard({
    super.key,
    required this.fxApi,
    required this.baseCurrency,
    this.symbolCurrency = 'KRW',
  });

  @override
  State<FxRateCard> createState() => _FxRateCardState();
}

class _FxRateCardState extends State<FxRateCard> {
  FxConvertResult? _result;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final r = await widget.fxApi.convert(
        amount: 1, // 1 단위 기준
        base: widget.baseCurrency,
        symbol: widget.symbolCurrency,
      );
      if (!mounted) return;
      setState(() => _result = r);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const SizedBox(
          height: 40,
          child: Center(child: CircularProgressIndicator()),
        )
            : _error != null
            ? Text(
          '환율 정보를 불러오지 못했어요.\n$_error',
          style: const TextStyle(fontSize: 12, color: Colors.red),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '환율 정보',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (_result != null) ...[
              Text(
                '1 ${_result!.base} ≈ '
                    '${_result!.converted.toStringAsFixed(2)} ${_result!.symbol}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '업데이트: ${_result!.asOf}',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

//금액 입력하면 환율 한화로 계산되도록
class FxCalculator extends StatefulWidget {
  final FxApiService fxApi;
  final String baseCurrency;   // 입력 통화 (여행지 통화)
  final String symbolCurrency; // 결과 통화 (예: KRW)

  const FxCalculator({
    super.key,
    required this.fxApi,
    required this.baseCurrency,
    this.symbolCurrency = 'KRW',
  });

  @override
  State<FxCalculator> createState() => _FxCalculatorState();
}

class _FxCalculatorState extends State<FxCalculator> {
  final _controller = TextEditingController(text: '100');
  FxConvertResult? _result;
  bool _loading = false;

  Future<void> _calc() async {
    final amount = double.tryParse(_controller.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) {
      setState(() => _result = null);
      return;
    }

    setState(() => _loading = true);
    try {
      final r = await widget.fxApi.convert(
        amount: amount,
        base: widget.baseCurrency,
        symbol: widget.symbolCurrency,
      );
      if (!mounted) return;
      setState(() => _result = r);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _calc();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '환율 계산기',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: widget.baseCurrency,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => _calc(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: _loading
                    ? const SizedBox(
                  height: 16,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                    : Text(
                  _result == null
                      ? '0 ${widget.symbolCurrency}'
                      : '${_result!.converted.toStringAsFixed(2)} ${_result!.symbol}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
