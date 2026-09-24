import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'animated_modal_sheet.dart';
import 'app_snackbar.dart';
import 'confirm_delete_dialog.dart';
import 'pressable_scale.dart';

/// The shared family note from the home screen (mockup screen 01):
/// editable by admins only, with access to the history of past notes.
class FamilyNoteCard extends ConsumerWidget {
  const FamilyNoteCard({super.key});

  Future<void> _editNote(BuildContext context, WidgetRef ref) async {
    final s = AppStrings.of(context);
    final current = ref.read(currentNoteProvider);
    final controller = TextEditingController(text: current?.text ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        title: Text(s.familyNote),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(
            hintText: s.noteHint,
            suffixIcon: Tooltip(
              message: s.clearNoteTooltip,
              child: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: controller.clear,
              ),
            ),
          ),
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
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: Text(s.save),
            ),
          ),
        ],
      ),
    );
    if (text == null) return;
    final baby = ref.read(selectedBabyProvider);
    if (baby == null) return;
    // myDisplayNameProvider (Firestore), not Firebase Auth's own
    // displayName — see that provider's doc comment.
    final authorName =
        ref.read(myDisplayNameProvider).value ??
        ref.read(currentUserProvider).displayName ??
        s.fallbackDisplayName;
    try {
      final repo = ref.read(noteRepositoryProvider);
      if (text.isEmpty) {
        await repo.clearNote(baby.id, authorName);
      } else {
        await repo.addNote(baby.id, text, authorName);
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackBar.showError(context, s.addNoteFailed);
      }
    }
  }

  Future<void> _deleteHistoryEntry(
    BuildContext context,
    WidgetRef ref,
    String noteId,
  ) async {
    final s = AppStrings.of(context);
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: s.deleteNoteTitle,
      message: s.deleteNoteMessage,
    );
    if (!confirmed) return;
    final baby = ref.read(selectedBabyProvider);
    if (baby == null) return;
    try {
      await ref.read(noteRepositoryProvider).deleteNote(baby.id, noteId);
      if (context.mounted) {
        AppSnackBar.showSuccess(context, s.noteDeleted);
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackBar.showError(context, s.deleteNoteFailed);
      }
    }
  }

  void _showHistory(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final isAdmin = ref.read(isCurrentUserAdminProvider);
    showAnimatedModalBottomSheet(
      context,
      backgroundColor: AppColors.of(context).background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // Consumer so the list stays live: deleting an entry (here or from
      // another device) updates this sheet immediately via the same
      // familyNotesProvider stream, instead of freezing a snapshot at open
      // time.
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          // Clearing the note (an empty save) shouldn't leave a blank entry
          // visible in the history — it's still stored so "current" can go
          // back to empty, but it's filtered out here rather than shown as
          // nothing.
          final notes = (ref.watch(familyNotesProvider).value ?? const [])
              .where((n) => n.text.isNotEmpty)
              .toList();
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.noteHistoryTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: notes.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(s.noNotesYet),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: notes.length,
                            separatorBuilder: (_, _) =>
                                Divider(color: AppColors.of(context).line),
                            itemBuilder: (context, index) {
                              final n = notes[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(n.text),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${n.authorName} · ${DateFormat(s.shortDateTimePattern, s.intlLocale).format(n.updatedAt)}',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: AppColors.of(
                                                context,
                                              ).inkSoft,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isAdmin)
                                      InkWell(
                                        onTap: () => _deleteHistoryEntry(
                                          context,
                                          ref,
                                          n.id,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color: AppColors.of(context).red,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final note = ref.watch(currentNoteProvider);
    final allNotes = ref.watch(familyNotesProvider).value ?? const [];
    // Same filtering as _showHistory — a cleared (empty) current note must
    // not count towards whether there's anything worth showing in history.
    final pastNotesCount = allNotes
        .where((n) => n.text.isNotEmpty && n.id != note?.id)
        .length;
    final isAdmin = ref.watch(isCurrentUserAdminProvider);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.of(context).primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.of(context).line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sticky_note_2_outlined,
                size: 16,
                color: AppColors.of(context).inkSoft,
              ),
              const SizedBox(width: 6),
              Text(
                s.familyNote,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: AppColors.of(context).inkSoft,
                ),
              ),
              const Spacer(),
              if (pastNotesCount > 0)
                InkWell(
                  onTap: () => _showHistory(context, ref),
                  child: Text(
                    s.history,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.of(context).inkSoft,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              if (isAdmin) ...[
                const SizedBox(width: 10),
                Tooltip(
                  message: s.editNoteTooltip,
                  child: InkWell(
                    onTap: () => _editNote(context, ref),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppColors.of(context).inkSoft,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            (note != null && note.text.isNotEmpty)
                ? note.text
                : (isAdmin ? s.noNoteYetAdmin : s.noNoteYetReadOnly),
          ),
        ],
      ),
    );
  }
}
