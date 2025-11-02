import 'package:flutter/material.dart';

class SimpleHeader extends StatelessWidget {
  const SimpleHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(child: Text('🍒', style: TextStyle(fontSize: 18))),
          ),
        ],
      ),
    );
  }
}
