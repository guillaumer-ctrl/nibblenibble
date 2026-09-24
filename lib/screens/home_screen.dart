import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../models/baby_profile.dart';
import '../motion/motion.dart';
import '../motion/slide_up_route.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_modal_sheet.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/error_retry_view.dart';
import '../widgets/family_note_card.dart';
import '../widgets/meal_card.dart';
import '../widgets/nibble_wordmark.dart';
import '../widgets/pending_invitations_card.dart';
import '../widgets/pressable_scale.dart';
import 'add_baby_screen.dart';
import 'baby_profile_screen.dart';
import 'meal_form_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final babiesAsync = ref.watch(babiesProvider);
    final baby = ref.watch(selectedBabyProvider);
    final currentUser = ref.watch(currentUserProvider);
    // myDisplayNameProvider (Firestore), not currentUser.displayName
    // (Firebase Auth) — see that provider's doc comment: Google Sign-In can
    // silently overwrite Firebase's copy on a later sign-in.
    final currentMemberName =
        ref.watch(myDisplayNameProvider).value ?? currentUser.displayName ?? '';
    final mealsAsync = ref.watch(mealsForSelectedBabyProvider);
    final canEdit = ref.watch(isCurrentUserAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const NibbleWordmark(height: 20),
                  if (baby != null)
                    _BabySwitcher(
                      currentBaby: baby,
                      babies: babiesAsync.value ?? [baby],
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  const PendingInvitationsCard(),
                  Text(
                    s.hello(currentMemberName),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  if (baby != null)
                    Text(
                      s.babyAgeSummary(baby.name, baby.ageInMonths) +
                          (baby.diversificationDays != null
                              ? s.diversificationDaysSuffix(
                                  baby.diversificationDays!,
                                )
                              : ''),
                    ),
                  const SizedBox(height: 24),
                  babiesAsync.when(
                    data: (babies) => babies.isEmpty
                        ? const _NoBabyYet()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const FamilyNoteCard(),
                              const SizedBox(height: 20),
                              Text(
                                s.upcomingMeals,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              mealsAsync.when(
                                data: (meals) {
                                  // Next meals first (soonest at the top).
                                  final sorted =
                                      meals.where((m) => !m.isPast).toList()
                                        ..sort(
                                          (a, b) =>
                                              a.dateTime.compareTo(b.dateTime),
                                        );
                                  if (sorted.isEmpty) {
                                    return Text(
                                      s.noUpcomingMeals,
                                      style: TextStyle(
                                        color: AppColors.of(context).inkSoft,
                                      ),
                                    );
                                  }
                                  return Column(
                                    children: sorted
                                        .take(2)
                                        .toList()
                                        .asMap()
                                        .entries
                                        .map(
                                          (entry) => _StaggeredEntrance(
                                            index: entry.key,
                                            child: MealCard(
                                              meal: entry.value,
                                              canEdit: canEdit,
                                              onTap: () =>
                                                  Navigator.of(context).push(
                                                    slideUpRoute(
                                                      (_) => MealFormScreen(
                                                        babyId: baby!.id,
                                                        existingMeal:
                                                            entry.value,
                                                      ),
                                                    ),
                                                  ),
                                              // No delete affordance here on
                                              // purpose — the home screen is
                                              // a quick glance at what's
                                              // next, not where meals get
                                              // managed. Deleting stays on
                                              // the Repas tab.
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  );
                                },
                                loading: () => const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(child: AppLoadingIndicator()),
                                ),
                                error: (_, _) => ErrorRetryView(
                                  onRetry: () => ref.invalidate(
                                    mealsForSelectedBabyProvider,
                                  ),
                                ),
                              ),
                            ],
                          ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: AppLoadingIndicator()),
                    ),
                    error: (_, _) => ErrorRetryView(
                      onRetry: () => ref.invalidate(babiesProvider),
                    ),
                  ),
                  const BannerAdWidget(
                    androidAdUnitId: homeBannerAdUnitIdAndroid,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoBabyYet extends StatelessWidget {
  const _NoBabyYet();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.of(context).line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.noBabyYetTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(s.noBabyYetSubtitle),
          const SizedBox(height: 16),
          PressableScale(
            child: ElevatedButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AddBabyScreen())),
              child: Text(s.addBaby),
            ),
          ),
        ],
      ),
    );
  }
}

class _BabySwitcher extends ConsumerWidget {
  const _BabySwitcher({required this.currentBaby, required this.babies});

  final BabyProfile currentBaby;
  final List<BabyProfile> babies;

  void _openPicker(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    showAnimatedModalBottomSheet(
      context,
      backgroundColor: AppColors.of(context).background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ...babies.map(
              (b) => ListTile(
                title: Text(b.name),
                trailing: b.id == currentBaby.id
                    ? Icon(Icons.check, color: AppColors.of(context).primary)
                    : null,
                onTap: () {
                  ref.read(selectedBabyIdProvider.notifier).state = b.id;
                  Navigator.of(sheetContext).pop();
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(s.profileOfThisBaby),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BabyProfileScreen(baby: currentBaby),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(s.addBaby),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddBabyScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: () => _openPicker(context, ref),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentBaby.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: AppColors.of(context).inkSoft,
          ),
        ],
      ),
    );
  }
}

/// Fades + slides a card up into place on first build, with a small delay
/// per [index] so a short list of cards enters one after another instead of
/// all at once.
class _StaggeredEntrance extends StatefulWidget {
  const _StaggeredEntrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<_StaggeredEntrance> {
  bool _visible = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) {
      _visible = true;
      return;
    }
    Future.delayed(Duration(milliseconds: 70 * widget.index), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: MotionDurations.list,
      curve: MotionCurves.standard,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.08),
        duration: MotionDurations.list,
        curve: MotionCurves.standard,
        child: widget.child,
      ),
    );
  }
}
