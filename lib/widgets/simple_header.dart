import 'package:flutter/material.dart';

class SimpleHeader extends StatelessWidget {
  const SimpleHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        children: [
          // 좌측 상단 육각형 PNG 로고
          Image.asset(
            'assets/images/Cherry_Pick_LOGO.png', // ← PNG 경로
            width: 32,
            height: 32,
          ),
        ],
      ),
    );
  }
}
