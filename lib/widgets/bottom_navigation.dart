//lib/widgets/bottom_navigation.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;

  const BottomNavigation({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outline.withOpacity(0.16), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.circle,
                label: '체리픽',
                isActive: currentIndex == 0,
                onTap: () => context.go('/luggage'),
              ),
              _NavItem(
                icon: Icons.camera_alt_rounded,
                label: '스캔',
                isActive: currentIndex == 1,
                onTap: () => context.go('/scan'),
              ),
              _NavItem(
                icon: Icons.flight_takeoff_rounded,
                label: '항공 규정',
                isActive: currentIndex == 2,
                onTap: () => context.go('/checklist'),
              ),
              _NavItem(
                icon: Icons.location_on_rounded,
                label: '추천',
                isActive: currentIndex == 3,
                onTap: () => context.go('/recommendations'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 24, color: isActive ? cs.primary : cs.onSurfaceVariant),
                if (isActive)
                  Positioned(
                    bottom: -6,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
