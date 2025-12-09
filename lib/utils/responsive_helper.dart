// lib/utils/responsive_helper.dart

import 'package:flutter/material.dart';

class ResponsiveHelper {
  final BuildContext context;
  late final MediaQueryData _mediaQuery;
  late final double screenWidth;
  late final double screenHeight;
  late final double blockSizeHorizontal;
  late final double blockSizeVertical;
  late final double safeBlockHorizontal;
  late final double safeBlockVertical;

  ResponsiveHelper(this.context) {
    _mediaQuery = MediaQuery.of(context);
    screenWidth = _mediaQuery.size.width;
    screenHeight = _mediaQuery.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    final safeAreaHorizontal = _mediaQuery.padding.left + _mediaQuery.padding.right;
    final safeAreaVertical = _mediaQuery.padding.top + _mediaQuery.padding.bottom;

    safeBlockHorizontal = (screenWidth - safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - safeAreaVertical) / 100;
  }

  // Responsive padding
  double wp(double percentage) => screenWidth * (percentage / 100);
  double hp(double percentage) => screenHeight * (percentage / 100);

  // Responsive font sizes
  double sp(double size) {
    if (screenWidth < 360) return size * 0.9;
    if (screenWidth < 400) return size * 0.95;
    if (screenWidth > 600) return size * 1.1;
    return size;
  }

  // Device type checks
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;
  bool get isSmallPhone => screenWidth < 360;
}