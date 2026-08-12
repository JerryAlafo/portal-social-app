import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Logótipo do PORTAL (favicon oficial do projeto de referência).
/// O PNG já tem fundo transparente e é mostrado diretamente, como na web.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/favicon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Icon(
        Icons.rocket_launch,
        color: AppColors.accentSoft,
        size: size,
      ),
    );
  }
}
