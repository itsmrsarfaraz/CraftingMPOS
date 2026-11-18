import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  /// Compact phones and narrow application windows.
  static const double compactBreakpoint = 360;

  /// Standard phone layouts.
  static const double mediumBreakpoint = 600;

  /// Tablet and wider layouts.
  static const double expandedBreakpoint = 840;

  static bool isCompact(BuildContext context) {
  return MediaQuery.sizeOf(context).width < mediumBreakpoint;
}

static bool isMedium(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;

  return width >= mediumBreakpoint && width < expandedBreakpoint;
}

static bool isExpanded(BuildContext context) {
  return MediaQuery.sizeOf(context).width >= expandedBreakpoint;
}

  static int gridColumns(double availableWidth) {
    if (availableWidth < compactBreakpoint) {
      return 1;
    }

    if (availableWidth < expandedBreakpoint) {
      return 2;
    }

    return 3;
  }

  static double horizontalPadding(double availableWidth) {
    if (availableWidth < compactBreakpoint) {
      return 12;
    }

    if (availableWidth < mediumBreakpoint) {
      return 16;
    }

    if (availableWidth < expandedBreakpoint) {
      return 24;
    }

    return 32;
  }
}
