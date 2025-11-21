// lib/widgets/item_status_styles.dart
import 'package:flutter/material.dart';

enum Status { allow, conditional, deny }

Status statusFromLabel(String label) {
  switch (label) {
    case '허용':
      return Status.allow;
    case '조건부 허용':
      return Status.conditional;
    case '금지':
    default:
      return Status.deny;
  }
}

class StatusStyle {
  final Color bg;
  final Color text;
  final IconData icon;
  const StatusStyle({
    required this.bg,
    required this.text,
    required this.icon,
  });
}

const statusStyleMap = <Status, StatusStyle>{
  Status.allow: StatusStyle(
    bg: Color(0xFFE9F8EE),
    text: Color(0xFF16794C),
    icon: Icons.check_circle,
  ),
  Status.conditional: StatusStyle(
    bg: Color(0xFFFFF6E5),
    text: Color(0xFF8A5A00),
    icon: Icons.error_outline,
  ),
  Status.deny: StatusStyle(
    bg: Color(0xFFFFECEC),
    text: Color(0xFFB42318),
    icon: Icons.block,
  ),
};
