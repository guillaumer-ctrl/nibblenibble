import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'pressable_scale.dart';

/// Same as [showConfirmDeleteDialog], but the confirm button only enables
/// once the user has typed [nameToType] exactly — extra friction for a
/// deletion that cascades (e.g. a baby profile and every meal tied to it)
/// and can't be undone by a snackbar, unlike a single meal.
Future<bool> showTypeToConfirmDeleteDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String nameToType,
  String? confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => _TypeToConfirmDialog(
      title: title,
      message: message,
      nameToType: nameToType,
      confirmLabel: confirmLabel,
    ),
  );
  return result ?? false;
}

/// A dedicated [StatefulWidget] (rather than a [TextEditingController] owned
/// by the surrounding function + a [StatefulBuilder]) so Flutter disposes
/// the controller exactly when this dialog's element is actually removed
/// from the tree — i.e. once its exit transition finishes. Disposing it
/// manually right after `await showDialog(...)` returns was too early: the
/// dialog (and its TextField) is still animating out at that point, and a
/// stray listener callback landing on the now-disposed controller during
/// that window is what threw "A TextEditingController was used after being
/// disposed."
class _TypeToConfirmDialog extends StatefulWidget {
  const _TypeToConfirmDialog({
    required this.title,
    required this.message,
    required this.nameToType,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String nameToType;
  final String? confirmLabel;

  @override
  State<_TypeToConfirmDialog> createState() => _TypeToConfirmDialogState();
}

class _TypeToConfirmDialogState extends State<_TypeToConfirmDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _controller.text.trim() == widget.nameToType;
    return AlertDialog(
      backgroundColor: AppColors.of(context).card,
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.message,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.of(context).typeToConfirmHint(widget.nameToType),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: widget.nameToType,
              // Default hint style is close enough to real input text that
              // the pre-filled-looking name reads as already typed — italic
              // + lower opacity makes it unambiguously a placeholder.
              hintStyle: TextStyle(
                color: AppColors.of(context).inkSoft.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
      actions: [
        PressableScale(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.of(context).cancel),
          ),
        ),
        PressableScale(
          child: TextButton(
            onPressed: matches ? () => Navigator.of(context).pop(true) : null,
            style: TextButton.styleFrom(foregroundColor: AppColors.of(context).red),
            child: Text(widget.confirmLabel ?? AppStrings.of(context).delete),
          ),
        ),
      ],
    );
  }
}

/// Shows the mockup's "Confirmer la suppression" dialog (screen 11).
/// Returns true if the user confirmed.
Future<bool> showConfirmDeleteDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.of(context).card,
      title: Text(title),
      actions: [
        PressableScale(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.of(context).cancel),
          ),
        ),
        PressableScale(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.of(context).red),
            child: Text(confirmLabel ?? AppStrings.of(context).delete),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
