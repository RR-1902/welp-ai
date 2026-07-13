import 'dart:ui';

import 'package:flutter/material.dart';

class BrandGlowLogo extends StatelessWidget {
  const BrandGlowLogo({
    super.key,
    required this.assetPath,
    this.height = 100,
    this.showGlow = true,
  });

  final String assetPath;
  final double height;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showGlow)
            Container(
              width: height * 0.88,
              height: height * 0.88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00E5FF).withOpacity(0.32),
                    const Color(0xFF00E5FF).withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          Image.asset(
            assetPath,
            height: height,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

class BrandAppBarTitle extends StatelessWidget {
  const BrandAppBarTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/images/welp_logo.png',
            height: 30,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Welp.Ai',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class BrandGlassHero extends StatelessWidget {
  const BrandGlassHero({
    super.key,
    this.height = 180,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.04),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Center(
            child: BrandGlowLogo(
              assetPath: 'assets/images/welp_logo.png',
              height: height,
            ),
          ),
        ),
      ),
    );
  }
}
