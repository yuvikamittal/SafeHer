import 'package:flutter/material.dart';

/// The circular shield brand mark used on the login screen.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 82});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1A73E8).withValues(alpha: 0.15),
        border: Border.all(
          color: const Color(0xFF1A73E8).withValues(alpha: 0.55),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A73E8).withValues(alpha: 0.25),
            blurRadius: 28,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(
        Icons.security_rounded,
        color: const Color(0xFF4DA3FF),
        size: size * 0.49,
      ),
    );
  }
}
