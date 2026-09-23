import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../widgets/kinetic_button.dart';

/// Práctica tab: placeholder for spaced review seeded from failed signs (M3).
class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        Text('Repaso rápido', style: textTheme.headlineSmall),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: KineticColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(KineticRadii.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🔁', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 12),
              Text(
                'Práctica espaciada con tus señas falladas',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Completa lecciones para sembrar señas aquí y repasarlas justo cuando empiezas a olvidarlas.',
                style: textTheme.bodyMedium?.copyWith(
                  color: KineticColors.textLow,
                ),
              ),
              const SizedBox(height: 16),
              KineticButton(
                label: 'Empezar práctica',
                variant: KineticButtonVariant.secondary,
                expand: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
