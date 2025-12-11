// lib/widgets/cherry_app_bar.dart
import 'package:flutter/material.dart';

class CherryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CherryAppBar({super.key});

  // AppBar 전체 높이 살짝 키움 (기본 kToolbarHeight ≒ 56)
  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: cs.surface,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      toolbarHeight: 64, // preferredSize랑 맞춰주기
      title: Image.asset(
        'assets/images/Cherry_Pick_Text.png',
        height: 32,           // 🔼 기존 28 → 32 로 살짝 키움
        fit: BoxFit.contain,
      ),
    );
  }
}
