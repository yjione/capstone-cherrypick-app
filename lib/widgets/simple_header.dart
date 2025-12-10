import 'package:flutter/material.dart';

class SimpleHeader extends StatelessWidget {
  const SimpleHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        children: [
          Image.asset(
            'assets/images/Cherry_Pick_LOGO.png',
            width: 32,
            height: 32,
          ),
        ],
      ),
    );
  }
}
