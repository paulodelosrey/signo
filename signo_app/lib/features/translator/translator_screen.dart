import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../widgets/kinetic_button.dart';

/// Traductor tab: placeholder for the offline-first translator (M4).
class TranslatorScreen extends StatelessWidget {
  const TranslatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        Text('Traductor offline', style: textTheme.headlineSmall),
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
              const Text('🖐️', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 12),
              Text(
                'Escribe una frase y tradúcela a LSC',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'El traductor local funciona sin conexión: convierte tu texto en una secuencia de videos de señas con controles de velocidad y voz.',
                style: textTheme.bodyMedium?.copyWith(
                  color: KineticColors.textLow,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: KineticColors.surfaceContainerMid,
                  borderRadius: BorderRadius.circular(KineticRadii.md),
                  border: Border.all(color: KineticColors.outline),
                ),
                child: Text(
                  'Escribe aquí tu frase…',
                  style: textTheme.bodyMedium?.copyWith(
                    color: KineticColors.textLow,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              KineticButton(
                label: 'Traducir',
                variant: KineticButtonVariant.primary,
                expand: true,
                icon: Icons.translate,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
