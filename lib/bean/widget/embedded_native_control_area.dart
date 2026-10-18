import 'dart:io';
import 'package:kazumi/l10n/material.dart';
import 'package:kazumi/services/platform/desktop_window_config.dart';

/// Reserves space above content for native macOS window controls.
class EmbeddedNativeControlArea extends StatelessWidget {
  const EmbeddedNativeControlArea({
    super.key,
    required this.child,
    this.requireOffset = true,
  });

  final Widget child;
  final bool requireOffset;

  @override
  Widget build(BuildContext context) {
    ChineseScriptScope.of(context);
    final needsOffset =
        Platform.isMacOS &&
        requireOffset &&
        DesktopWindowConfig.showWindowButton;
    return Padding(
      padding: needsOffset ? const EdgeInsets.only(top: 22) : EdgeInsets.zero,
      child: child,
    );
  }
}
