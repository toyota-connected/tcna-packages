import 'package:flutter/material.dart';

class Responsive {
  // Design breakpoints
  static const double designWidth = 1440.0;
  static const double mobileBreakpoint = 768.0;
  static const double tabletBreakpoint = 1024.0;

  static bool isMobile(BuildContext context) => 
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) => 
      MediaQuery.of(context).size.width >= mobileBreakpoint && 
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) => 
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  static double width(BuildContext context) => 
      MediaQuery.of(context).size.width;

  static double height(BuildContext context) => 
      MediaQuery.of(context).size.height;

  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }

  static double responsiveValue(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return responsive(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  // Scale a dimension from Figma design to current screen
  static double scale(BuildContext context, double figmaSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / designWidth;
    
    if (isMobile(context)) {
      return (figmaSize * scaleFactor * 1.2).clamp(figmaSize * 0.6, figmaSize * 1.2);
    } else if (isTablet(context)) {
      return (figmaSize * scaleFactor).clamp(figmaSize * 0.8, figmaSize * 1.1);
    } else {
      return (figmaSize * scaleFactor).clamp(figmaSize * 0.9, figmaSize * 1.3);
    }
  }

  static double scaleWithConstraints(
    BuildContext context, 
    double figmaSize, {
    double? minSize,
    double? maxSize,
  }) {
    final scaled = scale(context, figmaSize);
    return scaled.clamp(
      minSize ?? figmaSize * 0.5, 
      maxSize ?? figmaSize * 2.0,
    );
  }

}