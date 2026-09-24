import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/interstitial_ad_manager.dart';
import '../l10n/app_strings.dart';
import '../models/baby_profile.dart';
import '../models/food.dart';
import '../models/meal.dart';
import '../models/reaction.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/pressable_scale.dart';
import '../utils/meal_stats.dart';

/// Matches AppColors.of(context).sageDark/yellow/inkSoft — hardcoded here rather than
/// converted from the Flutter Color used elsewhere, since the `pdf` package
/// has its own PdfColor type with no shared conversion in this codebase.
int _reactionColor(Reaction? r) => switch (r) {
  Reaction.aime => 0xFF5F7D5C,
  Reaction.mitige => 0xFFA9822F,
  Reaction.pasAime => 0xFFB3261E,
  null => 0xFF8A7B68,
};

/// Filesystem-safe slug for the PDF's filename — a baby's name has no
/// format validation at entry, so nothing stops it from containing a `/` or
/// other character that would otherwise break the save/share sheet.
String _slugify(String input) {
  final slug = input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'bebe' : slug;
}

class ExportPdfScreen extends ConsumerStatefulWidget {
  const ExportPdfScreen({super.key});

  @override
  ConsumerState<ExportPdfScreen> createState() => _ExportPdfScreenState();
}

class _ExportPdfScreenState extends ConsumerState<ExportPdfScreen> {
  bool _generating = false;

  Future<void> _generateAndShare() async {
    final s = AppStrings.of(context);
    final baby = ref.read(selectedBabyProvider);
    if (baby == null) return;
    setState(() => _generating = true);
    try {
      // Guards against generating on a cold start / slow network: without
      // this, foodsByIdProvider could still be empty and every food would
      // fall back to showing its raw id instead of its name.
      await ref.read(foodsProvider.future);
      if (!mounted) return;

      final meals = ref.read(mealsForSelectedBabyProvider).value ?? [];
      final foodsById = ref.read(foodsByIdProvider);
      final pastMeals = meals.where((m) => m.isPast).toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      final stats = computeMealStats(pastMeals);

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          footer: (context) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'nibblenibble',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey500,
                ),
              ),
              pw.Text(
                '${context.pageNumber}/${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey500,
                ),
              ),
            ],
          ),
          build: (context) => [
            pw.Text(
              'nibblenibble',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFFE8734F),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '${s.pdfJournalTitle} — ${baby.name}',
              style: pw.TextStyle(fontSize: 14),
            ),
            pw.Text(
              s.pdfGeneratedOn(
                DateFormat(
                  s.dateOnlyPattern,
                  s.intlLocale,
                ).format(DateTime.now()),
              ),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 12),
            _buildBabyInfoCard(baby, s),
            pw.SizedBox(height: 10),
            _buildSummaryCard(
              stats.reactionCounts,
              stats.triedFoodIds.length,
              pastMeals.length,
              s,
            ),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 8),
            if (pastMeals.isEmpty)
              pw.Text(s.pdfNoMeals)
            else
              ...pastMeals.map((meal) => _buildMealSection(meal, foodsById, s)),
          ],
        ),
      );

      try {
        // layoutPdf (not sharePdf): opens the platform's print-preview
        // sheet, which offers "Enregistrer en PDF" and sharing/printing
        // from the same screen, instead of only a raw share-sheet.
        await Printing.layoutPdf(
          onLayout: (_) => doc.save(),
          name:
              'nibblenibble-${_slugify(baby.name)}-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
        );
        // A natural transition point — the export flow just closed — and
        // never shown on failure (see the catch below). Capped at once per
        // session inside the manager itself.
        unawaited(InterstitialAdManager.instance.showIfAvailable());
      } catch (_) {
        if (mounted) {
          AppSnackBar.showError(context, s.generatePdfFailed);
        }
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  pw.Widget _buildBabyInfoCard(BabyProfile baby, AppStrings s) {
    final days = baby.diversificationDays;
    // Wrap, not a Row with spaceBetween: a Row here can't wrap to a new
    // line, so a long value (a long name, or "Diversifying since : 340
    // days" in English) could overlap the next one instead of flowing —
    // the pdf package doesn't clip/warn about this the way Flutter does
    // on-screen. Also skips the diversification part entirely rather than
    // rendering an empty Text when it hasn't started yet.
    final parts = <String>[
      '${s.sex} : ${s.babyGenderLabel(baby.gender.name)}',
      '${s.pdfAge} : ${baby.ageInMonths} ${s.months}',
      if (days != null)
        '${s.pdfDiversificationDuration} : ${s.pdfDiversificationDays(days)}',
    ];
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFFBF5EC),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Wrap(
        spacing: 16,
        runSpacing: 4,
        children: parts
            .map((p) => pw.Text(p, style: const pw.TextStyle(fontSize: 10)))
            .toList(),
      ),
    );
  }

  pw.Widget _buildSummaryCard(
    Map<Reaction, int> reactionCounts,
    int foodsTriedCount,
    int mealsCount,
    AppStrings s,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            s.pdfSummaryTitle,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            s.pdfSummaryMeals(mealsCount),
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            s.pdfSummaryFoodsTried(foodsTriedCount),
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 6),
          pw.Wrap(
            spacing: 14,
            children: Reaction.values.map((r) {
              final count = reactionCounts[r] ?? 0;
              return pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Container(
                    width: 7,
                    height: 7,
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(_reactionColor(r)),
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.SizedBox(width: 4),
                  pw.Text(
                    '${s.reactionLabel(r.name)} : $count',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMealSection(
    Meal meal,
    Map<String, Food> foodsById,
    AppStrings s,
  ) {
    final dateLabel = DateFormat(
      s.longDateTimePattern,
      s.intlLocale,
    ).format(meal.dateTime);
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            dateLabel[0].toUpperCase() + dateLabel.substring(1),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
          pw.SizedBox(height: 4),
          ...meal.foods.map((f) {
            final name = foodsById[f.foodId]?.displayNameFor(s) ?? f.foodId;
            final reaction = f.reaction != null
                ? s.reactionLabel(f.reaction!.name)
                : s.pdfNotRecorded;
            final note = (f.note ?? '').isEmpty ? '' : ' — ${f.note}';
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 3, right: 5),
                    width: 7,
                    height: 7,
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(_reactionColor(f.reaction)),
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      '$name : $reaction$note',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final baby = ref.watch(selectedBabyProvider);
    ref.watch(foodsProvider); // warm the cache foodsByIdProvider reads from

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(title: Text(s.dataScreenTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.generatePdfIntro),
              const SizedBox(height: 24),
              PressableScale(
                child: ElevatedButton.icon(
                  onPressed: baby == null || _generating
                      ? null
                      : _generateAndShare,
                  icon: _generating
                      ? AppLoadingIndicator(
                          size: 16,
                          color: AppColors.of(context).onPrimary,
                        )
                      : const Icon(Icons.picture_as_pdf, size: 18),
                  label: Text(_generating ? s.generating : s.generatePdf),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
