import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/settings.dart';
import 'theme.dart';
import '../features/dictionary/dictionary_screen.dart';
import '../features/learn/learn_tree_screen.dart';
import '../features/paywall/premium_screen.dart';
import '../features/practice/practice_hub_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/translator/translator_screen.dart';

/// Kinetic app shell.
///
/// Spec (app-shell): the navigation is a 5-tab rail — Aprender, Práctica,
/// Bingo, Traductor, Premium — with the Bingo destination HIDDEN for the MVP.
/// Bingo is intentionally absent from the destination list below; when the
/// mini-game ships it must be re-inserted between Práctica and Traductor
/// without changing the IndexedStack contract.
class SignoShell extends ConsumerStatefulWidget {
  const SignoShell({super.key});

  @override
  ConsumerState<SignoShell> createState() => _SignoShellState();
}

class _SignoShellState extends ConsumerState<SignoShell> {
  static const List<String> _titles = <String>[
    'Aprender',
    'Práctica',
    'Traductor',
    'Premium',
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final AppSettings settings = ref.watch(settingsProvider);
    final int avatarIndex = settings.avatarIndex.clamp(
      0,
      kAvatarEmojis.length - 1,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Visual dictionary entry lives on the Aprender tab (spec
          // `visual-dictionary`; not a nav tab — the rail keeps its 4 visible
          // destinations with Bingo hidden).
          if (_index == 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                tooltip: 'Diccionario',
                icon: const Icon(Icons.menu_book_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        const DictionaryScreen(),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Perfil',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const ProfileScreen(),
                ),
              ),
              icon: CircleAvatar(
                backgroundColor: KineticColors.surfaceContainerHigh,
                child: Text(
                  kAvatarEmojis[avatarIndex],
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          LearnTreeScreen(),
          PracticeHubScreen(),
          TranslatorScreen(),
          PremiumScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int newIndex) =>
            setState(() => _index = newIndex),
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Aprender',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Práctica',
          ),
          NavigationDestination(
            icon: Icon(Icons.translate),
            selectedIcon: Icon(Icons.translate),
            label: 'Traductor',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium_outlined),
            selectedIcon: Icon(Icons.workspace_premium),
            label: 'Premium',
          ),
          // Bingo destination intentionally omitted (hidden tab per spec).
        ],
      ),
    );
  }
}
