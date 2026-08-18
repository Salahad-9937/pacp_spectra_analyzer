import 'package:flutter/material.dart';

import 'button_busy_indicator.dart';

enum AppButtonKind {
  outlined,
  elevated,
  text,
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.kind = AppButtonKind.outlined,
    this.busy = false,
    this.showBusyIndicator = false,
    this.disableWhenBusy = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final AppButtonKind kind;
  final bool busy;
  final bool showBusyIndicator;
  final bool disableWhenBusy;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || (busy && disableWhenBusy);
    final VoidCallback? effectiveOnPressed = disabled ? null : onPressed;

    final Widget leading = busy && showBusyIndicator
        ? const ButtonBusyIndicator()
        : Icon(icon, size: 17);

    final Widget caption = Text(label);

    switch (kind) {
      case AppButtonKind.elevated:
        return ElevatedButton.icon(
          onPressed: effectiveOnPressed,
          icon: leading,
          label: caption,
        );
      case AppButtonKind.text:
        return TextButton.icon(
          onPressed: effectiveOnPressed,
          icon: leading,
          label: caption,
        );
      case AppButtonKind.outlined:
        return OutlinedButton.icon(
          onPressed: effectiveOnPressed,
          icon: leading,
          label: caption,
        );
    }
  }
}