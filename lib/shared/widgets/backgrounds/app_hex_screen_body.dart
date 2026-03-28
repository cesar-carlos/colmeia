import 'package:colmeia/shared/widgets/backgrounds/honeycomb_hex_background.dart';
import 'package:flutter/material.dart';

/// Auth and full-screen layouts: honeycomb pattern behind SafeArea + child.
/// Matches the app shell body layering for a single visual language.
class AppHexScreenBody extends StatelessWidget {
  const AppHexScreenBody({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return HoneycombHexBackground(
      child: SafeArea(
        child: child,
      ),
    );
  }
}
