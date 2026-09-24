import 'package:flutter/material.dart';

import '../models/reaction.dart';
import '../theme/app_theme.dart';
import 'reaction_face_icon.dart';

/// A food name with its reaction, as a true pill chip. Shared by meal cards
/// and the Stats "foods tried" list so both look alike.
///
/// The chip's own background/text always follow the primary-light /
/// primary-dark tokens (per the visual spec) regardless of reaction — the
/// reaction itself is only shown via the small face icon.
class FoodBlock extends StatelessWidget {
  const FoodBlock({
    super.key,
    required this.name,
    required this.reaction,
    this.expand = true,
    this.showLabel = true,
  });

  /// False: only the reaction icon, without its text.
  final bool showLabel;

  final String name;
  final Reaction? reaction;

  /// True: fills the available width (name left, reaction right).
  /// False: shrink-wraps its content, for use inside a [Wrap].
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final label = Text(
      name,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: colors.primaryDark,
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (expand) Expanded(child: label) else Flexible(child: label),
          if (reaction != null) ...[
            SizedBox(width: expand ? 4 : 8),
            ReactionFaceIcon(
              reaction: reaction!,
              color: reaction!.color(context),
              size: 16,
            ),
            if (showLabel) ...[
              const SizedBox(width: 4),
              Text(
                reaction!.label(context),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: reaction!.color(context),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
