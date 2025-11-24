// lib/widgets/bottom_navigation.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        context.go('/luggage');
        break;
      case 1:
        context.go('/scan');
        break;
      case 2:
        context.go('/checklist');
        break;
      case 3:
        context.go('/recommendations');
        break;
    }
  }

  /// 체리픽 전용 로고 아이콘 (선택/비선택 색만 바뀌게)
  Widget _buildCherryIcon(Color color) {
    return Image.asset(
      'assets/images/Cherry_Pick_LOGO.png',
      width: 24,
      height: 24,
      color: color, // PNG가 단색이 아니라면 이 줄은 지워도 됨
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final selectedColor = cs.primary;
    final unselectedColor = cs.onSurfaceVariant;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) => _onTap(context, index),
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      showUnselectedLabels: true,
      items: [
        BottomNavigationBarItem(
          icon: _buildCherryIcon(unselectedColor),
          activeIcon: _buildCherryIcon(selectedColor),
          label: '체리픽',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.camera_alt_outlined),
          activeIcon: Icon(Icons.camera_alt),
          label: '스캔',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.flight_takeoff_outlined),
          activeIcon: Icon(Icons.flight_takeoff),
          label: '항공 규정',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.place_outlined),
          activeIcon: Icon(Icons.place),
          label: '추천',
        ),
      ],
    );
  }
}
