import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../widgets/kinetic_button.dart';
import '../dictionary/dictionary_screen.dart';

/// Aprender tab: placeholder for the 4-unit learning path (M3).
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: KineticColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(KineticRadii.lg),
          ),
          child: Row(
            children: [
              const Text('🤟', style: TextStyle(fontSize: 44)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UNIDAD 1',
                      style: textTheme.labelMedium?.copyWith(
                        color: KineticColors.mint,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Saludos y abecedario',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(KineticRadii.pill),
                      child: LinearProgressIndicator(
                        value: 0,
                        minHeight: 8,
                        backgroundColor: KineticColors.outline,
                        color: KineticColors.mint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
              Text(
                'Las lecciones llegan en la fase M3',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Cuatro unidades con ejercicios de reconocimiento y emparejamiento de videos en LSC.',
                style: textTheme.bodyMedium?.copyWith(
                  color: KineticColors.textLow,
                ),
              ),
              const SizedBox(height: 16),
              KineticButton(
                label: 'Lecciones en camino',
                variant: KineticButtonVariant.secondary,
                expand: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: KineticColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(KineticRadii.lg),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            leading: const Text('📖', style: TextStyle(fontSize: 28)),
            title: Text('Diccionario visual', style: textTheme.titleMedium),
            subtitle: Text(
              'Busca señas por palabra',
              style: textTheme.bodyMedium?.copyWith(
                color: KineticColors.textLow,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const DictionaryScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
