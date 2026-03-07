import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F3D34), Color(0xFF081916)],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.7),
              radius: 1.3,
              colors: [
                const Color(0xFF1E6F5C).withValues(alpha: 0.55),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.9),
              radius: 1.6,
              colors: [
                const Color(0xFF1E6F5C).withValues(alpha: 0.25),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
