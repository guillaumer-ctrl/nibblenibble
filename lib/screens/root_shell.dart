import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../motion/motion.dart';
import '../motion/slide_up_route.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/pressable_scale.dart';
import 'account_screen.dart';
import 'home_screen.dart';
import 'meal_form_screen.dart';
import 'meals_screen.dart';
import 'stats_screen.dart';

/// Bottom nav, left to right: Accueil, Repas (à venir/passés), + (opens
/// "Ajouter un repas" directly — not a persistent tab), Stats, Compte.
class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  // Index into _tabs (there's no tab for the "+" button — it's an action,
  // not a screen, so it never becomes the selected index).
  int _tabIndex = 0;

  static const _tabs = [
    HomeScreen(),
    MealsScreen(),
    StatsScreen(),
    AccountScreen(),
  ];

  void _openAddMeal() {
    final babyId = ref.read(selectedBabyProvider)?.id;
    if (babyId == null) return;
    Navigator.of(context)
        .push(slideUpRoute((_) => MealFormScreen(babyId: babyId)));
  }

  @override
  Widget build(BuildContext context) {
    // Read-only members can't create meals, so the "+" action slot (visual
    // index 2, between Repas and Stats) is only shown to admins — the visual
    // <-> tab index maps shift accordingly rather than showing a dead button.
    final s = AppStrings.of(context);
    final canAddMeal = ref.watch(isCurrentUserAdminProvider);
    final visualIndexForTab = canAddMeal
        ? const {0: 0, 1: 1, 2: 3, 3: 4}
        : const {0: 0, 1: 1, 2: 2, 3: 3};
    final tabForVisualIndex = canAddMeal
        ? const {0: 0, 1: 1, 3: 2, 4: 3}
        : const {0: 0, 1: 1, 2: 2, 3: 3};
    final reduced = Motion.reduced(context);

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      // A Stack (not IndexedStack) so the outgoing and incoming tab can both
      // paint during the cross-fade — IndexedStack only ever paints one
      // child, so there'd be nothing to fade from. Every tab stays mounted
      // (same as IndexedStack) so none of them lose state on switch.
      body: Stack(
        children: [
          for (var i = 0; i < _tabs.length; i++)
            IgnorePointer(
              ignoring: i != _tabIndex,
              child: AnimatedOpacity(
                opacity: i == _tabIndex ? 1 : 0,
                duration: reduced
                    ? MotionDurations.reduced
                    : MotionDurations.micro,
                child: _tabs[i],
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: visualIndexForTab[_tabIndex]!,
        onDestinationSelected: (visualIndex) {
          if (canAddMeal && visualIndex == 2) {
            _openAddMeal();
            return;
          }
          setState(() => _tabIndex = tabForVisualIndex[visualIndex]!);
        },
        backgroundColor: AppColors.of(context).card,
        indicatorColor: AppColors.of(context).primary.withValues(alpha: 0.15),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: _NavIconPop(
              child: Icon(Icons.home, color: AppColors.of(context).primary),
            ),
            label: s.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.restaurant_outlined),
            selectedIcon: _NavIconPop(
              child: Icon(
                Icons.restaurant,
                color: AppColors.of(context).primary,
              ),
            ),
            label: s.navMeals,
          ),
          if (canAddMeal)
            NavigationDestination(
              icon: PressableScale(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.of(context).primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: AppColors.of(context).onPrimary,
                    size: 20,
                  ),
                ),
              ),
              label: s.addShort,
            ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: _NavIconPop(
              child: Icon(
                Icons.bar_chart,
                color: AppColors.of(context).primary,
              ),
            ),
            label: s.navStats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: _NavIconPop(
              child: Icon(Icons.person, color: AppColors.of(context).primary),
            ),
            label: s.navAccount,
          ),
        ],
      ),
    );
  }
}

/// Wraps a destination's `selectedIcon` — since `NavigationBar` only ever
/// mounts this widget while its destination is the selected one, a
/// self-starting pop plays each time it (re)mounts, i.e. each time this
/// tab *becomes* selected.
class _NavIconPop extends StatefulWidget {
  const _NavIconPop({required this.child});

  final Widget child;

  @override
  State<_NavIconPop> createState() => _NavIconPopState();
}

class _NavIconPopState extends State<_NavIconPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.15,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery (read inside Motion.reduced) can only be looked up once
    // this Element is fully attached — initState() is too early and trips
    // "dependOnInheritedWidgetOfExactType<MediaQuery>() was called before
    // initState() completed". didChangeDependencies() runs right after, so
    // this still plays before the first frame; the _started guard just
    // keeps it from replaying on later dependency changes (e.g. a
    // reduced-motion toggle mid-animation).
    if (!_started) {
      _started = true;
      if (!Motion.reduced(context)) _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
