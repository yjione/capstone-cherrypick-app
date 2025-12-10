// lib/screens/checklist_screen.dart
import 'package:flutter/material.dart';

import '../widgets/cherry_app_bar.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/regulation_checker.dart';

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: const CherryAppBar(),
      body: const RegulationChecker(),
      bottomNavigationBar: const BottomNavigation(currentIndex: 2),
    );
  }
}
