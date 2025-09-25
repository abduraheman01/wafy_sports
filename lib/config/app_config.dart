import 'package:flutter/material.dart';

class AppConfig {
  static const String adminPassword = 'abdu15211';

  static const Duration splashDuration = Duration(milliseconds: 3500);

  static const String appName = 'Sportify';
  static const String appTagline = 'Your Music-Powered Sports Hub';

  // Official Brand Colors
  static const Color primaryColor = Color(0xFFDF1A19); // Red
  static const Color secondaryColor = Color(0xFF002675); // Blue
  static const Color accentColor = Color(0xFFFFCB29); // Yellow
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);

  // Clean design colors (no gradients)
  static const Color primaryDark = Color(0xFFB71C1C);
  static const Color secondaryDark = Color(0xFF001A4A);
  static const Color accentDark = Color(0xFFFFA500);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color borderColor = Color(0xFFE0E0E0);

  static const double webBreakpoint = 800.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

  static bool isWeb(double screenWidth) => screenWidth > webBreakpoint;
  static bool isTablet(double screenWidth) => screenWidth > tabletBreakpoint;
  static bool isDesktop(double screenWidth) => screenWidth > desktopBreakpoint;
}