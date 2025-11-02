import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../widgets/trip_selector_dialog.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProvider>(
      builder: (context, tripProvider, child) {
        final currentTrip = tripProvider.currentTrip;

        final cs = Theme.of(context).colorScheme;
        final bg = cs.primary.withOpacity(0.08); // 연분홍 하이라이트

        return Padding(
          padding: const EdgeInsets.only(left: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showTripSelector(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🍒', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    currentTrip?.name ?? '여행 선택',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 18, color: cs.primary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTripSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TripSelectorDialog(),
    );
  }
}
