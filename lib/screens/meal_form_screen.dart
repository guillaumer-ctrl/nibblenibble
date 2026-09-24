import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/baby_profile.dart';
import '../models/food.dart';
import '../models/meal.dart';
import '../models/reaction.dart';
import '../motion/motion.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../utils/diacritics.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/reaction_face_icon.dart';

/// Add or edit a meal (mockup screens 04 "Ajouter / enregistrer un repas"
/// and 10 "Modifier le repas" — same form, edit just pre-fills it).
class MealFormScreen extends ConsumerStatefulWidget {
  const MealFormScreen({super.key, required this.babyId, this.existingMeal});

  final String babyId;
  final Meal? existingMeal;

  @override
  ConsumerState<MealFormScreen> createState() => _MealFormScreenState();
}

class _MealFormScreenState extends ConsumerState<MealFormScreen> {
  late DateTime _dateTime;
  // A new meal defaults _dateTime to "now" internally (see below), but the
  // user must still actively confirm it via the picker before touching the
  // food list — an edited meal already has a real, deliberately-set date,
  // so it starts out already "chosen".
  late bool _dateTimeChosen;
  final List<String> _selectedFoodIds = [];
  final Map<String, Reaction> _reactions = {};
  final Map<String, TextEditingController> _noteControllers = {};
  final _mealNoteController = TextEditingController();
  final _searchController = TextEditingController();
  String _search = '';
  bool _saving = false;

  bool get _isEditing => widget.existingMeal != null;

  // A meal at or before the current moment counts as past — its foods get
  // reactions/notes. A meal scheduled later is upcoming, with no reactions
  // yet. This used to be a manual switch; deriving it from the picked date
  // means it can never drift out of sync with what "Repas passés"/"Repas à
  // venir" actually show.
  bool get _isPastMeal => !_dateTime.isAfter(DateTime.now());

  @override
  void initState() {
    super.initState();
    final existing = widget.existingMeal;
    _dateTime = existing?.dateTime ?? DateTime.now();
    _dateTimeChosen = existing != null;
    if ((existing?.note ?? '').isNotEmpty) {
      _mealNoteController.text = existing!.note!;
    }
    if (existing != null) {
      // A food only ever has one current reaction: if this meal itself
      // didn't record one for a food, fall back to whatever was last
      // recorded for it elsewhere, so it's never shown/edited as "blank"
      // when it's actually already known.
      final knownReactions = ref.read(foodReactionsProvider);
      for (final entry in existing.foods) {
        _selectedFoodIds.add(entry.foodId);
        final reaction = entry.reaction ?? knownReactions[entry.foodId];
        if (reaction != null) _reactions[entry.foodId] = reaction;
        if ((entry.note ?? '').isNotEmpty) {
          _noteControllerFor(entry.foodId).text = entry.note!;
        }
      }
    }
  }

  @override
  void dispose() {
    for (final c in _noteControllers.values) {
      c.dispose();
    }
    _mealNoteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  TextEditingController _noteControllerFor(String foodId) =>
      _noteControllers.putIfAbsent(foodId, TextEditingController.new);

  void _toggleFood(String foodId, bool selected) {
    setState(() {
      if (selected) {
        _selectedFoodIds.add(foodId);
        // Pre-fill with the food's already-known reaction, if any — still
        // editable below, since a baby's taste can genuinely change.
        final known = ref.read(foodReactionsProvider)[foodId];
        if (known != null) _reactions[foodId] = known;
      } else {
        _selectedFoodIds.remove(foodId);
        _reactions.remove(foodId);
        _noteControllers.remove(foodId)?.dispose();
      }
    });
  }

  /// A food that isn't in the shared database yet, added by this family and
  /// scoped to this baby only (see FoodRepository's doc comment) — asks for
  /// a category, then immediately selects it for this meal like any other.
  Future<void> _addCustomFood(String name) async {
    final s = AppStrings.of(context);
    // Case/accent-insensitive exact match only — deliberately not a fuzzy
    // substring match (e.g. "carotte" vs "carottes"): that would also catch
    // unrelated pairs like "pomme" vs "pomme de terre" and silently select
    // the wrong food instead of adding the one actually typed.
    final folded = foldDiacritics(name.toLowerCase());
    final existing = ref
        .read(allFoodsProvider)
        .where(
          (f) => foldDiacritics(f.displayName(context).toLowerCase()) == folded,
        )
        .firstOrNull;
    if (existing != null) {
      setState(() {
        _selectedFoodIds.add(existing.id);
        _search = '';
        _searchController.clear();
      });
      AppSnackBar.show(context, s.customFoodAlreadyExists(existing.displayName(context)));
      return;
    }
    final category = await showDialog<FoodCategory>(
      context: context,
      builder: (context) => _CategoryPickerDialog(name: name),
    );
    if (category == null || !mounted) return;
    try {
      final food = await ref
          .read(foodRepositoryProvider)
          .addCustomFood(widget.babyId, name, category);
      if (!mounted) return;
      setState(() {
        _selectedFoodIds.add(food.id);
        _search = '';
        _searchController.clear();
      });
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, s.addCustomFoodFailed);
      }
    }
  }

  Future<void> _pickDateTime() async {
    final s = AppStrings.of(context);
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: s.datePickerLocale,
      // Calendar only: the manual-entry keyboard field doesn't offer "/" on
      // some Android keyboards, making the date impossible to type.
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
      // Dial only: the keyboard-entry toggle in the default time picker
      // crashes/misbehaves on this device — same class of issue as the
      // date picker's manual entry mode.
      initialEntryMode: TimePickerEntryMode.dialOnly,
    );
    if (time == null) return;
    setState(() {
      _dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _dateTimeChosen = true;
    });
  }

  Future<void> _save() async {
    if (_selectedFoodIds.isEmpty) {
      AppSnackBar.show(context, AppStrings.of(context).addAtLeastOneFood);
      return;
    }
    setState(() => _saving = true);
    try {
      final isPast = _isPastMeal;
      final foods = _selectedFoodIds
          .map(
            (id) => MealFoodEntry(
              foodId: id,
              reaction: isPast ? _reactions[id] : null,
              note:
                  isPast && _noteControllers[id]?.text.trim().isNotEmpty == true
                  ? _noteControllers[id]!.text.trim()
                  : null,
            ),
          )
          .toList();
      final repo = ref.read(mealRepositoryProvider);
      final loggedByMemberId = ref.read(currentMemberIdProvider);
      final mealNote = _mealNoteController.text.trim();
      if (_isEditing) {
        await repo.updateMeal(
          Meal(
            id: widget.existingMeal!.id,
            babyId: widget.babyId,
            dateTime: _dateTime,
            foods: foods,
            loggedByMemberId: loggedByMemberId,
            note: mealNote.isEmpty ? null : mealNote,
          ),
        );
      } else {
        await repo.addMeal(
          Meal(
            id: '',
            babyId: widget.babyId,
            dateTime: _dateTime,
            foods: foods,
            loggedByMemberId: loggedByMemberId,
            note: mealNote.isEmpty ? null : mealNote,
          ),
        );
      }
      await _maybeSetDiversificationStart();
      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          _isEditing
              ? AppStrings.of(context).mealUpdated
              : AppStrings.of(context).mealAdded,
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, AppStrings.of(context).saveMealFailed);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Was never being set anywhere despite the model's own doc comment
  /// promising it ("should be set once the first meal is logged") — self-
  /// heals on every save rather than trying to catch the exact "first meal"
  /// moment: takes the earliest date across this meal and whatever's
  /// already loaded, so a backdated first entry or pre-existing meals from
  /// before this fix both correct it.
  ///
  /// Only ever considers *past* meals — a brand-new baby whose very first
  /// logged entry is a planned/upcoming meal (dateTime in the future) used
  /// to set the start date to that future date, making
  /// [BabyProfile.diversificationDays] come out negative until that date
  /// arrived. Diversification hasn't started until a meal has actually
  /// happened.
  Future<void> _maybeSetDiversificationStart() async {
    final baby = ref.read(selectedBabyProvider);
    if (baby == null || baby.diversificationStartDate != null) return;
    final meals = ref.read(mealsForSelectedBabyProvider).value ?? const [];
    final now = DateTime.now();
    final pastDates = [
      _dateTime,
      ...meals.map((m) => m.dateTime),
    ].where((d) => d.isBefore(now)).toList();
    if (pastDates.isEmpty) return;
    final earliest = pastDates.reduce((a, b) => a.isBefore(b) ? a : b);
    await ref
        .read(babyRepositoryProvider)
        .updateBaby(
          BabyProfile(
            id: baby.id,
            name: baby.name,
            birthDate: baby.birthDate,
            diversificationStartDate: earliest,
            gender: baby.gender,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    // A read-only member can't change the date or which foods were served —
    // only add/edit the baby's reaction on foods already selected (the sole
    // action the "accepter une invitation en lecture seule" role grants
    // beyond viewing). They only ever reach this screen via an existing,
    // already-past-or-not meal, never to create one.
    final canEdit = ref.watch(isCurrentUserAdminProvider);
    // Whether the reaction picker itself shows/is editable — past meals
    // only, for EITHER role: an upcoming meal has nothing to react to yet,
    // and a picker that showed but silently got discarded on save (because
    // _save() only keeps reactions for past meals) would be a real bug.
    final showReactionPicker = _isPastMeal;
    // Whether the bottom save button shows at all: an admin can always
    // save (date/foods, even for an upcoming meal), a read-only member only
    // when there's actually a reaction to save.
    final showSaveButton = canEdit || _isPastMeal;

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(_isEditing ? s.editMealTitle : s.addMealTitle),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: canEdit ? _pickDateTime : null,
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: s.dateAndTime),
                      child: _dateTimeChosen
                          ? Text(
                              DateFormat(
                                s.dateTimePattern,
                                s.intlLocale,
                              ).format(_dateTime),
                            )
                          : Text(
                              s.chooseDateAndTime,
                              style: TextStyle(
                                color: AppColors.of(context).inkSoft,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_dateTimeChosen)
                    Row(
                      children: [
                        Icon(
                          _isPastMeal ? Icons.check_circle : Icons.schedule,
                          size: 14,
                          color: _isPastMeal
                              ? AppColors.of(context).sageDark
                              : AppColors.of(context).amber,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _isPastMeal ? s.pastMealHint : s.upcomingMealHint,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.of(context).inkSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (canEdit) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _mealNoteController,
                      enabled: _dateTimeChosen,
                      decoration: InputDecoration(
                        labelText: s.mealNoteOptional,
                        isDense: true,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      enabled: _dateTimeChosen,
                      decoration: InputDecoration(
                        labelText: s.searchAFood,
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(
                        () => _search = foldDiacritics(v.toLowerCase()),
                      ),
                    ),
                  ] else
                    const SizedBox(height: 12),
                ],
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (canEdit && !_dateTimeChosen) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          s.chooseDateAndTimeFirst,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.of(context).inkSoft),
                        ),
                      ),
                    );
                  }
                  final foodsAsync = ref.watch(foodsProvider);
                  final customFoodsAsync = ref.watch(customFoodsProvider);
                  if (!foodsAsync.hasValue || !customFoodsAsync.hasValue) {
                    return AppLoadingIndicator.center();
                  }
                  final allFoods = ref.watch(allFoodsProvider);
                  final lastReactions = ref.watch(foodReactionsProvider);
                  final usageCounts = ref.watch(foodUsageCountsProvider);
                  final filtered =
                      allFoods
                          .where(
                            (f) => foldDiacritics(
                              f.displayName(context).toLowerCase(),
                            ).contains(_search),
                          )
                          .toList()
                        // Foods come back from Firestore in whatever order
                        // the shared import assigned (effectively French
                        // alphabetical) — re-sort by the name actually shown
                        // in the current language, not the underlying French
                        // one.
                        ..sort(
                          (a, b) => foldDiacritics(
                            a.displayName(context).toLowerCase(),
                          ).compareTo(
                            foldDiacritics(b.displayName(context).toLowerCase()),
                          ),
                        );
                  // Read-only: only the already-selected foods, nothing to
                  // add — the full searchable list would offer a toggle
                  // they're not allowed to use.
                  if (!canEdit) {
                    final foods = filtered
                        .where((f) => _selectedFoodIds.contains(f.id))
                        .toList();
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: foods.length,
                      itemBuilder: (context, index) {
                        final food = foods[index];
                        return _FoodTile(
                          food: food,
                          selected: true,
                          editable: false,
                          showReaction: showReactionPicker,
                          reaction: _reactions[food.id],
                          lastReaction: lastReactions[food.id],
                          usageCount: usageCounts[food.id] ?? 0,
                          noteController: _noteControllerFor(food.id),
                          onToggle: (_) {},
                          onReactionSelected: (r) =>
                              setState(() => _reactions[food.id] = r),
                        );
                      },
                    );
                  }
                  // Selected foods float to the top — easier to review/edit
                  // reactions without hunting through the whole list. Split
                  // instead of List.sort to keep each group's own order
                  // stable (Dart's sort isn't guaranteed stable).
                  final selectedFoods = filtered
                      .where((f) => _selectedFoodIds.contains(f.id))
                      .toList();
                  final unselectedFoods = filtered
                      .where((f) => !_selectedFoodIds.contains(f.id))
                      .toList();
                  final foods = [...selectedFoods, ...unselectedFoods];
                  // Only offer to add a new food once the search genuinely
                  // finds nothing — if a match already exists, adding a
                  // near-duplicate would just fragment stats/history.
                  final showAddCustom = _search.isNotEmpty && filtered.isEmpty;
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: foods.length + (showAddCustom ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == foods.length) {
                        final name = _searchController.text.trim();
                        return _AddCustomFoodTile(
                          name: name,
                          onTap: () => _addCustomFood(name),
                        );
                      }
                      final food = foods[index];
                      final selected = _selectedFoodIds.contains(food.id);
                      return _FoodTile(
                        food: food,
                        selected: selected,
                        editable: true,
                        showReaction: selected && showReactionPicker,
                        reaction: _reactions[food.id],
                        lastReaction: lastReactions[food.id],
                        usageCount: usageCounts[food.id] ?? 0,
                        noteController: selected
                            ? _noteControllerFor(food.id)
                            : null,
                        onToggle: (v) => _toggleFood(food.id, v),
                        onReactionSelected: (r) =>
                            setState(() => _reactions[food.id] = r),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: showSaveButton
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: PressableScale(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? AppLoadingIndicator(size: 18, color: AppColors.of(context).onPrimary)
                        : Text(
                            canEdit
                                ? (_selectedFoodIds.isEmpty
                                      ? s.save
                                      : s.saveWithCount(
                                          _selectedFoodIds.length,
                                        ))
                                : s.saveReactions,
                          ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({
    required this.food,
    required this.selected,
    required this.showReaction,
    required this.reaction,
    required this.lastReaction,
    required this.usageCount,
    required this.noteController,
    required this.onToggle,
    required this.onReactionSelected,
    this.editable = true,
  });

  final Food food;
  final bool selected;
  final bool showReaction;
  final Reaction? reaction;

  /// The most recent reaction previously recorded for this food (across
  /// other meals) — shown as a hint so a parent knows what to expect even
  /// before picking a reaction for this meal.
  final Reaction? lastReaction;

  /// Total number of past meals this food has appeared in.
  final int usageCount;
  final TextEditingController? noteController;
  final ValueChanged<bool> onToggle;
  final ValueChanged<Reaction> onReactionSelected;

  /// False for a read-only member: the food list is fixed, so there's
  /// nothing to toggle — shown as a plain row instead of a checkbox tile.
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AnimatedContainer(
      duration: Motion.reduced(context)
          ? MotionDurations.reduced
          : MotionDurations.micro,
      curve: MotionCurves.standard,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: selected ? AppColors.of(context).card : null,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: selected ? Border.all(color: AppColors.of(context).line) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (editable)
            // Material(transparency), not the bare tile: the Container's
            // own background above would otherwise hide the ListTile's
            // ink/bg.
            Material(
              type: MaterialType.transparency,
              child: CheckboxListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                value: selected,
                onChanged: (v) => onToggle(v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(food.displayName(context)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      food.category.label(context),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.of(context).inkSoft,
                      ),
                    ),
                    if (usageCount > 0)
                      _HistoryLine(
                        lastReaction: lastReaction,
                        usageCount: usageCount,
                      ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.displayName(context),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    food.category.label(context),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.of(context).inkSoft,
                    ),
                  ),
                  if (usageCount > 0)
                    _HistoryLine(
                      lastReaction: lastReaction,
                      usageCount: usageCount,
                    ),
                ],
              ),
            ),
          if (showReaction) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(s.theirReaction, style: AppTextStyles.badge(context)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _ReactionPicker(
                selected: reaction,
                onSelected: onReactionSelected,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: s.noteOptional,
                  isDense: true,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small "already tried N times, last reaction X" line shown under a food
/// with history — visible whether or not the food is currently selected, so
/// it can inform the decision to add it in the first place.
class _HistoryLine extends StatelessWidget {
  const _HistoryLine({required this.lastReaction, required this.usageCount});

  final Reaction? lastReaction;
  final int usageCount;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = lastReaction != null
        ? '${s.previousReactionLabel(lastReaction!.label(context))} · ${s.usedTimesCount(usageCount)}'
        : s.usedTimesCount(usageCount);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lastReaction != null) ...[
            ReactionFaceIcon(
              reaction: lastReaction!,
              color: lastReaction!.color(context),
              size: 12,
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.of(context).inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The trailing row offering to add the current search term as a new food
/// — only shown while the search box has text (see the itemCount above).
class _AddCustomFoodTile extends StatelessWidget {
  const _AddCustomFoodTile({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Icon(
          Icons.add_circle_outline,
          color: AppColors.of(context).primary,
        ),
        title: Text(
          s.addCustomFoodPrompt(name),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.of(context).primary,
          ),
        ),
        onTap: name.isEmpty ? null : onTap,
      ),
    );
  }
}

/// Asks which category a new custom food belongs to — required, since every
/// other food has one (used for grouping in Stats and the PDF export).
class _CategoryPickerDialog extends StatefulWidget {
  const _CategoryPickerDialog({required this.name});

  final String name;

  @override
  State<_CategoryPickerDialog> createState() => _CategoryPickerDialogState();
}

class _CategoryPickerDialogState extends State<_CategoryPickerDialog> {
  FoodCategory? _selected;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AlertDialog(
      backgroundColor: AppColors.of(context).card,
      title: Text(s.addCustomFoodTitle(widget.name)),
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: FoodCategory.values.map((c) {
          final selected = _selected == c;
          return PressableScale(
            child: ChoiceChip(
              label: Text(c.label(context)),
              selected: selected,
              selectedColor: AppColors.of(context).sage.withValues(alpha: 0.3),
              checkmarkColor: AppColors.of(context).sageDark,
              labelStyle: TextStyle(
                color: selected
                    ? AppColors.of(context).sageDark
                    : AppColors.of(context).ink,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              ),
              onSelected: (_) => setState(() => _selected = c),
            ),
          );
        }).toList(),
      ),
      actions: [
        PressableScale(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.cancel),
          ),
        ),
        PressableScale(
          child: TextButton(
            onPressed: _selected == null
                ? null
                : () => Navigator.of(context).pop(_selected),
            child: Text(s.addShort),
          ),
        ),
      ],
    );
  }
}

/// Three big, unmissable reaction buttons — replaces small ChoiceChips that
/// were easy to miss entirely (this was explicit user feedback).
class _ReactionPicker extends StatelessWidget {
  const _ReactionPicker({required this.selected, required this.onSelected});

  final Reaction? selected;
  final ValueChanged<Reaction> onSelected;

  @override
  Widget build(BuildContext context) {
    final duration = Motion.reduced(context)
        ? Duration.zero
        : MotionDurations.micro;
    return Row(
      children: Reaction.values.map((r) {
        final isSelected = selected == r;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: r == Reaction.values.last ? 0 : 8),
            child: InkWell(
              onTap: () => onSelected(r),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: AnimatedContainer(
                duration: duration,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? r.tint(context).withValues(alpha: 0.28)
                      : AppColors.of(context).primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isSelected
                        ? r.tint(context)
                        : AppColors.of(context).line,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    ReactionFaceIcon(
                      reaction: r,
                      color: isSelected
                          ? r.color(context)
                          : AppColors.of(context).inkSoft,
                      size: 26,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.label(context),
                      style: AppTextStyles.badge(
                        context,
                        color: isSelected ? r.color(context) : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
