import 'package:flutter/material.dart';

/// The app-wide dark gradient used as the background of every screen.
const LinearGradient kAppBackgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0D1B2A), Color(0xFF1A2E44), Color(0xFF0F2335)],
);

/// Fills its area with [kAppBackgroundGradient] and lays [child] on top.
///
/// Use as the body of a [Scaffold] to get the consistent app background.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: kAppBackgroundGradient),
      child: SizedBox.expand(child: child),
    );
  }
}
