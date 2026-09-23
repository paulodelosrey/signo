import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/settings.dart';
import '../widgets/kinetic_button.dart';
import 'theme.dart';

/// Static 3-page onboarding shown on first launch.
///
/// 1. Value proposition.
/// 2. Daily goal selection (5 / 15 / 20 minutes, persisted).
/// 3. Start confirmation that marks onboarding as seen.
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _page = 0;
  int _goalMinutes = 15;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref
        .read(settingsProvider.notifier)
        .completeOnboarding(dailyGoalMinutes: _goalMinutes);
  }

  void _goToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _finish,
            child: const Text('Saltar'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (int page) => setState(() => _page = page),
                children: <Widget>[
                  _ValuePropPage(onGoalChanged: (int m) {
                    setState(() => _goalMinutes = m);
                    _goToNextPage();
                  }),
                  _GoalPage(
                    selectedMinutes: _goalMinutes,
                    onSelect: (int m) => setState(() => _goalMinutes = m),
                  ),
                  _StartPage(
                    goalMinutes: _goalMinutes,
                    onStart: _finish,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(3, (int index) {
                  final bool active = index == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? KineticColors.mint
                          : KineticColors.outline,
                      borderRadius: BorderRadius.circular(KineticRadii.pill),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared layout for a single onboarding page; scrollable so large system
/// text scales never overflow the viewport.
class _OnboardingPageLayout extends StatelessWidget {
  const _OnboardingPageLayout({
    required this.emoji,
    required this.title,
    required this.body,
    required this.child,
  });

  final String emoji;
  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Text(emoji, textAlign: TextAlign.center, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(color: KineticColors.textHigh),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: KineticColors.textLow),
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }
}

class _ValuePropPage extends StatelessWidget {
  const _ValuePropPage({required this.onGoalChanged});

  final ValueChanged<int> onGoalChanged;

  @override
  Widget build(BuildContext context) {
    return _OnboardingPageLayout(
      emoji: '🤟',
      title: 'Aprende Lengua de Señas Colombiana',
      body:
          'Lecciones cortas y visuales para comunicarte en LSC desde el primer día, sin conexión y a tu ritmo.',
      child: KineticButton(
        label: 'Continuar',
        variant: KineticButtonVariant.primary,
        expand: true,
        onPressed: () => onGoalChanged(15),
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  const _GoalPage({required this.selectedMinutes, required this.onSelect});

  final int selectedMinutes;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return _OnboardingPageLayout(
      emoji: '🎯',
      title: 'Elige tu meta diaria',
      body: 'Dedica unos minutos al día a practicar y mantén tu racha activa.',
      child: Row(
        children: List<Widget>.generate(kDailyGoalChoices.length, (int index) {
          final int minutes = kDailyGoalChoices[index];
          final bool selected = minutes == selectedMinutes;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GestureDetector(
                onTap: () => onSelect(minutes),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: selected
                        ? KineticColors.mintContainer
                        : KineticColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(KineticRadii.md),
                    border: Border.all(
                      color: selected ? KineticColors.mint : KineticColors.outline,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$minutes',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: selected ? KineticColors.mint : KineticColors.textHigh,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'min',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: KineticColors.textLow,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StartPage extends StatelessWidget {
  const _StartPage({required this.goalMinutes, required this.onStart});

  final int goalMinutes;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return _OnboardingPageLayout(
      emoji: '🚀',
      title: 'Todo listo para empezar',
      body: 'Tu meta: $goalMinutes minutos al día. Podrás cambiarla cuando quieras desde tu perfil.',
      child: KineticButton(
        label: 'Empezar a aprender',
        variant: KineticButtonVariant.primary,
        expand: true,
        onPressed: onStart,
      ),
    );
  }
}
