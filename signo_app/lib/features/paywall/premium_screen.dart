import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../widgets/kinetic_button.dart';

/// Premium tab: placeholder for the RevenueCat paywall (M6).
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: KineticColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(KineticRadii.lg),
            border: Border.all(color: KineticColors.mint, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('👑', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 12),
              Text('Signo Premium', style: textTheme.headlineSmall),
              const SizedBox(height: 8),
              _benefit(context, '💜', 'Corazones infinitos'),
              _benefit(context, '🧩', 'Módulos ilimitados'),
              _benefit(context, '📥', 'Copia offline de videos'),
              _benefit(context, '🎓', 'Vista previa del certificado'),
              const SizedBox(height: 16),
              KineticButton(
                label: 'Prueba 7 días gratis',
                variant: KineticButtonVariant.primary,
                expand: true,
              ),
              const SizedBox(height: 8),
              Text(
                'El pago se activa en la fase M6. USD 49.99/año o USD 9.99/mes, cancela cuando quieras.',
                style: textTheme.bodySmall?.copyWith(
                  color: KineticColors.textLow,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _benefit(BuildContext context, String emoji, String label) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
