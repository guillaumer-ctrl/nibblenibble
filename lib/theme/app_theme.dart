import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../motion/slide_parallax_route_builder.dart';

/// Theme-aware design tokens (indigo reskin, light + dark).
///
/// Registered on [ThemeData.extensions] as [AppColorsX]; call sites read it
/// through the [AppColors.of] accessor, e.g. `AppColors.of(context).ink`.
/// This is the one place that knows the actual hex values — every widget in
/// the app should go through the accessor instead of hardcoding a Color, so
/// the same call site automatically follows the active light/dark theme.
class AppColorsX extends ThemeExtension<AppColorsX> {
  const AppColorsX({
    required this.background,
    required this.card,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.onPrimary,
    required this.sage,
    required this.sageDark,
    required this.sageLight,
    required this.sageBorder,
    required this.amber,
    required this.amberDark,
    required this.amberLight,
    required this.onAmber,
    required this.red,
    required this.redDark,
    required this.redLight,
    required this.redBorder,
    required this.ink,
    required this.inkSoft,
    required this.inkVerySoft,
    required this.line,
    required this.accentOrange,
    required this.accentTeal,
    required this.accentGreen,
    required this.accentPurple,
  });

  final Color background;
  final Color card;

  /// Brand indigo.
  final Color primary;

  /// Deeper indigo — accent icons/text on light backgrounds.
  final Color primaryDark;

  /// Tinted background used behind chips/pills (e.g. the food chip).
  final Color primaryLight;

  /// Text/icon color to place on top of a filled [primary] surface.
  final Color onPrimary;

  /// "Aimé" reaction state + family note accents.
  final Color sage;
  final Color sageDark;
  final Color sageLight;
  final Color sageBorder;

  /// "Mitigé" reaction state.
  final Color amber;
  final Color amberDark;
  final Color amberLight;

  /// Text/icon color to place on top of a filled [amber] surface (e.g. the
  /// offline banner) — [amber] itself is light enough in dark mode that
  /// white text loses contrast, unlike [onPrimary]'s single-color case.
  final Color onAmber;

  /// "Pas aimé" reaction state + destructive/error actions.
  final Color red;
  final Color redDark;
  final Color redLight;
  final Color redBorder;

  final Color ink;
  final Color inkSoft;
  final Color inkVerySoft;

  final Color line;

  // Vivid accents used for stat categories.
  final Color accentOrange;
  final Color accentTeal;
  final Color accentGreen;
  final Color accentPurple;

  static const light = AppColorsX(
    background: Color(0xFFFBF6EF),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFF4B3B8C),
    primaryDark: Color(0xFF332759),
    primaryLight: Color(0xFFE7E2F7),
    onPrimary: Colors.white,
    sage: Color(0xFF6B8F66),
    sageDark: Color(0xFF4C6B48),
    sageLight: Color(0xFFE4EDE1),
    sageBorder: Color(0xFFD7E6D3),
    amber: Color(0xFFC08A2E),
    amberDark: Color(0xFF785A19),
    amberLight: Color(0xFFF5E9D2),
    onAmber: Colors.white,
    red: Color(0xFFD64545),
    redDark: Color(0xFFB23A3A),
    redLight: Color(0xFFFBE4E1),
    redBorder: Color(0xFFF0C7C1),
    ink: Color(0xFF2E2620),
    inkSoft: Color(0xFF7C6F5E),
    inkVerySoft: Color(0xFFB3A692),
    line: Color(0xFFEDE2D3),
    accentOrange: Color(0xFFF2994A),
    accentTeal: Color(0xFF29B6C6),
    accentGreen: Color(0xFF27AE60),
    accentPurple: Color(0xFF8B7CE0),
  );

  static const dark = AppColorsX(
    background: Color(0xFF1E1B2E),
    card: Color(0xFF2A2640),
    primary: Color(0xFFB3A2F2),
    primaryDark: Color(0xFFB3A2F2),
    primaryLight: Color(0xFF3A3555),
    onPrimary: Color(0xFF241B47),
    sage: Color(0xFF6BE3A6),
    sageDark: Color(0xFF6BE3A6),
    sageLight: Color(0xFF1F3327),
    sageBorder: Color(0xFF2C4A3A),
    amber: Color(0xFFFFB46B),
    amberDark: Color(0xFFFFD199),
    amberLight: Color(0xFF3A2E14),
    onAmber: Color(0xFF1E1B2E),
    red: Color(0xFFF3B3B5),
    redDark: Color(0xFFF3B3B5),
    redLight: Color(0xFF3A1F1F),
    redBorder: Color(0xFF4A2A2A),
    ink: Color(0xFFF3F1F8),
    inkSoft: Color(0xFF9C94B8),
    inkVerySoft: Color(0xFF726A8C),
    line: Color(0xFF3A3555),
    accentOrange: Color(0xFFFFB46B),
    accentTeal: Color(0xFF5FD3DE),
    accentGreen: Color(0xFF6BE3A6),
    accentPurple: Color(0xFFC4B8F5),
  );

  @override
  AppColorsX copyWith({
    Color? background,
    Color? card,
    Color? primary,
    Color? primaryDark,
    Color? primaryLight,
    Color? onPrimary,
    Color? sage,
    Color? sageDark,
    Color? sageLight,
    Color? sageBorder,
    Color? amber,
    Color? amberDark,
    Color? amberLight,
    Color? onAmber,
    Color? red,
    Color? redDark,
    Color? redLight,
    Color? redBorder,
    Color? ink,
    Color? inkSoft,
    Color? inkVerySoft,
    Color? line,
    Color? accentOrange,
    Color? accentTeal,
    Color? accentGreen,
    Color? accentPurple,
  }) {
    return AppColorsX(
      background: background ?? this.background,
      card: card ?? this.card,
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryLight: primaryLight ?? this.primaryLight,
      onPrimary: onPrimary ?? this.onPrimary,
      sage: sage ?? this.sage,
      sageDark: sageDark ?? this.sageDark,
      sageLight: sageLight ?? this.sageLight,
      sageBorder: sageBorder ?? this.sageBorder,
      amber: amber ?? this.amber,
      amberDark: amberDark ?? this.amberDark,
      amberLight: amberLight ?? this.amberLight,
      onAmber: onAmber ?? this.onAmber,
      red: red ?? this.red,
      redDark: redDark ?? this.redDark,
      redLight: redLight ?? this.redLight,
      redBorder: redBorder ?? this.redBorder,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      inkVerySoft: inkVerySoft ?? this.inkVerySoft,
      line: line ?? this.line,
      accentOrange: accentOrange ?? this.accentOrange,
      accentTeal: accentTeal ?? this.accentTeal,
      accentGreen: accentGreen ?? this.accentGreen,
      accentPurple: accentPurple ?? this.accentPurple,
    );
  }

  @override
  AppColorsX lerp(ThemeExtension<AppColorsX>? other, double t) {
    if (other is! AppColorsX) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColorsX(
      background: c(background, other.background),
      card: c(card, other.card),
      primary: c(primary, other.primary),
      primaryDark: c(primaryDark, other.primaryDark),
      primaryLight: c(primaryLight, other.primaryLight),
      onPrimary: c(onPrimary, other.onPrimary),
      sage: c(sage, other.sage),
      sageDark: c(sageDark, other.sageDark),
      sageLight: c(sageLight, other.sageLight),
      sageBorder: c(sageBorder, other.sageBorder),
      amber: c(amber, other.amber),
      amberDark: c(amberDark, other.amberDark),
      amberLight: c(amberLight, other.amberLight),
      onAmber: c(onAmber, other.onAmber),
      red: c(red, other.red),
      redDark: c(redDark, other.redDark),
      redLight: c(redLight, other.redLight),
      redBorder: c(redBorder, other.redBorder),
      ink: c(ink, other.ink),
      inkSoft: c(inkSoft, other.inkSoft),
      inkVerySoft: c(inkVerySoft, other.inkVerySoft),
      line: c(line, other.line),
      accentOrange: c(accentOrange, other.accentOrange),
      accentTeal: c(accentTeal, other.accentTeal),
      accentGreen: c(accentGreen, other.accentGreen),
      accentPurple: c(accentPurple, other.accentPurple),
    );
  }
}

/// Accessor for the active [AppColorsX] token set. Every call site should
/// read colors through here (`AppColors.of(context).ink`) instead of a
/// hardcoded Color, so light/dark both work from one code path.
class AppColors {
  AppColors._();

  static AppColorsX of(BuildContext context) =>
      Theme.of(context).extension<AppColorsX>() ?? AppColorsX.light;
}

/// Shared corner radii. [pill] is reserved for buttons, icon-buttons,
/// toggles and segmented controls — never cards, chips-as-badges or tiles.
class AppRadius {
  AppRadius._();

  static const double pill = 999.0;
  static const double card = 20.0;
  static const double dialog = 26.0;
}

/// Named spacing scale — use instead of ad hoc `EdgeInsets`/`SizedBox` gap
/// values.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

/// Named type styles that don't map to a default Material [TextTheme] role
/// but recur across screens — use instead of re-declaring the same
/// `TextStyle(fontSize: ...)` locally.
class AppTextStyles {
  AppTextStyles._();

  /// Card/list-row title (e.g. an account name row) — distinct from
  /// [TextTheme.titleMedium] (17/w600) since call sites want it visibly
  /// smaller but bolder.
  static TextStyle cardTitle(BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.of(context).ink,
    height: 1.25,
  );

  /// Compact pill/badge label (pending pill, quantity chips, section
  /// eyebrow labels).
  static TextStyle badge(BuildContext context, {Color? color}) => TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    height: 1.2,
    color: color ?? AppColors.of(context).inkSoft,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppColorsX.light, Brightness.light);

  static ThemeData get dark => _build(AppColorsX.dark, Brightness.dark);

  static ThemeData _build(AppColorsX colors, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        primary: colors.primary,
        secondary: colors.sageDark,
        surface: colors.card,
        error: colors.red,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: colors.background,
      textTheme: GoogleFonts.poppinsTextTheme(
        brightness == Brightness.dark ? ThemeData.dark().textTheme : null,
      ),
      extensions: [colors],
    );

    // One font everywhere (Poppins). Sizes follow the design spec:
    // greeting title 28-30/700, section title 22/600, subtitle 17/600,
    // body 15/400-500, caption/meta 13/500.
    final titleLargeStyle = base.textTheme.titleLarge?.copyWith(
      color: colors.ink,
      fontWeight: FontWeight.w600,
      fontSize: 22,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          color: colors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 28,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          color: colors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 28,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          color: colors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 26,
        ),
        titleLarge: titleLargeStyle,
        titleMedium: base.textTheme.titleMedium?.copyWith(
          color: colors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(color: colors.ink),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: colors.ink,
          fontWeight: FontWeight.w400,
          fontSize: 15,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          color: colors.inkSoft,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.ink,
        elevation: 0,
        titleTextStyle: titleLargeStyle?.copyWith(
          color: colors.primary,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: colors.line),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: colors.line,
          disabledForegroundColor: colors.inkVerySoft,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              disabledForegroundColor: colors.inkVerySoft,
              side: BorderSide(color: colors.primary),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ).copyWith(
              side: WidgetStateProperty.resolveWith(
                (states) => BorderSide(
                  color: states.contains(WidgetState.disabled)
                      ? colors.line
                      : colors.primary,
                ),
              ),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          disabledForegroundColor: colors.inkVerySoft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.primary,
          disabledForegroundColor: colors.inkVerySoft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        // Without these, the resting label (sitting inside the empty field,
        // e.g. "Prénom" before anything is typed) defaulted to a color close
        // enough to real input text to read as already-filled-in rather than
        // a placeholder. Muted + italic at rest, primary once it floats up.
        labelStyle: TextStyle(
          color: colors.inkSoft,
          fontStyle: FontStyle.italic,
        ),
        floatingLabelStyle: TextStyle(color: colors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          borderSide: BorderSide(color: colors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          borderSide: BorderSide(color: colors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colors.primaryLight,
        labelStyle: TextStyle(color: colors.primaryDark),
        side: BorderSide(color: colors.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SlideParallaxRouteBuilder(),
          TargetPlatform.iOS: SlideParallaxRouteBuilder(),
        },
      ),
    );
  }
}
