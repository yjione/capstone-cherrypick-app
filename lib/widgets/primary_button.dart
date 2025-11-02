// lib/widgets/primary_button.dart
import 'package:flutter/material.dart';

class CPPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool expanded;
  final Widget? leading;
  final bool isLoading;

  const CPPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expanded = true,
    this.leading,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final btnChild = isLoading
        ? const SizedBox(
      height: 18,
      width: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    )
        : Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 8),
        ],
        Text(label),
      ],
    );

    final btn = FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: btnChild,
    );

    // expanded=true 이면 하단 고정형으로 쓰기 편하도록 SafeArea + 패딩 포함
    if (expanded) {
      return SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(width: double.infinity, child: btn),
      );
    }
    return btn;
  }
}
