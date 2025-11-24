// lib/widgets/cherry_app_bar.dart
import 'package:flutter/material.dart';

class CherryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CherryAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: cs.surface,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: Image.asset(
        'assets/images/Cherry_Pick_Text.png',
        height: 28,              // 🔥 예전보다 살짝 더 크게
        fit: BoxFit.contain,
      ),
    );
  }
}
