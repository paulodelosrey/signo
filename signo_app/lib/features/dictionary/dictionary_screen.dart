import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Read-only visual dictionary placeholder (M5). Entry point lives on the
/// Aprender tab.
class DictionaryScreen extends StatelessWidget {
  const DictionaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: kineticAppBar('Diccionario'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: KineticColors.surfaceContainerMid,
              borderRadius: BorderRadius.circular(KineticRadii.pill),
              border: Border.all(color: KineticColors.outline),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: KineticColors.textLow),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Buscar señas (próximamente)',
                    style: textTheme.bodyLarge?.copyWith(
                      color: KineticColors.textLow,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Column(
            children: [
              const Text('🔤', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(
                '189 señas en camino',
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'El diccionario se genera del vocabulario compilado en la fase M5.',
                style: textTheme.bodyMedium?.copyWith(
                  color: KineticColors.textLow,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
