import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart';
import '../widgets/add_trip_dialog.dart';

class TripSelectorDialog extends StatelessWidget {
  const TripSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Consumer<TripProvider>(
      builder: (context, tripProvider, child) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('여행 선택',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                ...tripProvider.trips.map((trip) => _TripItem(
                  trip: trip,
                  isSelected: tripProvider.currentTripId == trip.id,
                  onTap: () {
                    tripProvider.setCurrentTrip(trip.id);
                    Navigator.of(context).pop();
                  },
                  onDelete: tripProvider.trips.length > 1
                      ? () => tripProvider.deleteTrip(trip.id)
                      : null,
                )),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).pop();
                    showDialog(context: context, builder: (_) => const AddTripDialog());
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outline.withOpacity(0.28), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add, color: cs.primary),
                        const SizedBox(width: 8),
                        Text('새 여행 추가',
                            style: TextStyle(fontWeight: FontWeight.w600, color: cs.primary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TripItem extends StatelessWidget {
  final Trip trip;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _TripItem({
    required this.trip,
    required this.isSelected,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? cs.primary.withOpacity(0.08) : cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? cs.primary.withOpacity(0.35) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: isSelected ? cs.primary : cs.onSurfaceVariant,
        ),
        title: Text(trip.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(trip.destination),
        trailing: onDelete != null
            ? IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
          color: cs.error,
        )
            : null,
      ),
    );
  }
}
