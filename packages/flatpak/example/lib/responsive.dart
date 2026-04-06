import 'package:flutter/material.dart';

class Responsive {
  static const double _designWidth  = 1024.0;
  static const double _designHeight = 768.0;

  static const double _smallBreakpoint  = 600.0;   // small embedded / phone
  static const double _mediumBreakpoint = 1024.0;  // tablet / RPi screen
  static const double _largeBreakpoint  = 1440.0;  // desktop
  // anything above 1440 = xl (4K, large monitors)

  static bool isSmall(BuildContext context) =>
      _w(context) < _smallBreakpoint;

  static bool isMedium(BuildContext context) =>
      _w(context) >= _smallBreakpoint && _w(context) < _mediumBreakpoint;

  static bool isLarge(BuildContext context) =>
      _w(context) >= _mediumBreakpoint && _w(context) < _largeBreakpoint;

  static bool isXL(BuildContext context) =>
      _w(context) >= _largeBreakpoint;

  static bool isMobile(BuildContext context)  => isSmall(context);
  static bool isTablet(BuildContext context)  => isMedium(context);
  static bool isDesktop(BuildContext context) => isLarge(context) || isXL(context);

  static double width(BuildContext context)  => _w(context);
  static double height(BuildContext context) => _h(context);

  static double widthFraction(BuildContext context, double fraction) =>
      _w(context) * fraction;

  static double heightFraction(BuildContext context, double fraction) =>
      _h(context) * fraction;

  /// Returns the value matching the current screen category.
  /// Falls back to the next smaller value if a larger one is not provided.
  static T responsive<T>(
    BuildContext context, {
    required T small,
    T? medium,
    T? large,
    T? xl,
  }) {
    if (isXL(context)     && xl     != null) return xl;
    if (isLarge(context)  && large  != null) return large;
    if (isMedium(context) && medium != null) return medium;
    return small;
  }

  static double responsiveValue(
    BuildContext context, {
    required double small,
    double? medium,
    double? large,
    double? xl,
  }) =>
      responsive(context, small: small, medium: medium, large: large, xl: xl);

  /// Scales [figmaSize] (designed at 1024×768) to the current screen.
  ///
  /// Uses the geometric mean of the width and height ratios so the result
  /// feels correct in both axes — no overflow vertically on wide screens,
  /// no tiny text on tall narrow screens.
  static double scale(BuildContext context, double figmaSize) {
    final wRatio = _w(context) / _designWidth;
    final hRatio = _h(context) / _designHeight;

    // Geometric mean keeps proportions balanced across wildly different aspects
    final scale = _sqrt(wRatio * hRatio);

    // Per-category clamping so things stay sensible at extremes
    if (isSmall(context)) {
      return (figmaSize * scale).clamp(figmaSize * 0.45, figmaSize * 0.85);
    } else if (isMedium(context)) {
      return (figmaSize * scale).clamp(figmaSize * 0.70, figmaSize * 1.10);
    } else if (isLarge(context)) {
      return (figmaSize * scale).clamp(figmaSize * 0.90, figmaSize * 1.40);
    } else {
      // XL / 4K
      return (figmaSize * scale).clamp(figmaSize * 1.10, figmaSize * 2.00);
    }
  }

  /// Same as [scale] but lets call sites override the min/max clamp.
  static double scaleWithConstraints(
    BuildContext context,
    double figmaSize, {
    double? minSize,
    double? maxSize,
  }) {
    final scaled = scale(context, figmaSize);
    return scaled.clamp(
      minSize ?? figmaSize * 0.45,
      maxSize ?? figmaSize * 2.00,
    );
  }

  /// Like [scale] but never exceeds the system text-scale factor.
  /// Use this for font sizes so they respect accessibility settings.
  static double fontSize(BuildContext context, double figmaFontSize) {
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);
    final base = scale(context, figmaFontSize);
    return base / textScale; // let Flutter re-apply text scale naturally
  }

  /// Scaled SizedBox height gap — convenience shorthand.
  static Widget vGap(BuildContext context, double figmaGap) =>
      SizedBox(height: scale(context, figmaGap));

  /// Scaled SizedBox width gap — convenience shorthand.
  static Widget hGap(BuildContext context, double figmaGap) =>
      SizedBox(width: scale(context, figmaGap));

  /// Scaled EdgeInsets.all
  static EdgeInsets paddingAll(BuildContext context, double figmaPadding) =>
      EdgeInsets.all(scale(context, figmaPadding));

  /// Scaled EdgeInsets.symmetric
  static EdgeInsets paddingSymmetric(
    BuildContext context, {
    double vertical = 0,
    double horizontal = 0,
  }) =>
      EdgeInsets.symmetric(
        vertical:   scale(context, vertical),
        horizontal: scale(context, horizontal),
      );

  static double dialogMaxWidth(BuildContext context) =>
      (_w(context) * 0.90).clamp(280, 640);

  static double dialogMaxHeight(BuildContext context) =>
      _h(context) * 0.85;

  static double _w(BuildContext context) => MediaQuery.of(context).size.width;
  static double _h(BuildContext context) => MediaQuery.of(context).size.height;
  static double _sqrt(double x) => x <= 0 ? 1.0 : x < 1 ? x + (1 - x) * 0.5 : x * 0.5 + 0.5;
}