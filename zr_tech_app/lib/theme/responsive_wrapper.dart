import 'package:flutter/material.dart';

/// Responsive breakpoints
class Breakpoints {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
}

/// Responsive scaling utility based on screen width.
/// Call `Responsive.init(context)` once in your build method,
/// then use `Responsive.sp(16)` for scaled font sizes, etc.
class Responsive {
  static late double _screenWidth;
  static late double _screenHeight;
  static late double _scaleFactor;

  /// Initialize with current context — call at top of build()
  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _screenWidth = size.width;
    _screenHeight = size.height;

    // Base design width is 390 (iPhone 14 baseline)
    // Scale up slightly on bigger screens, down on smaller
    if (_screenWidth < Breakpoints.mobile) {
      _scaleFactor = _screenWidth / 390;
    } else if (_screenWidth < Breakpoints.tablet) {
      _scaleFactor = 1.0;
    } else if (_screenWidth < Breakpoints.desktop) {
      _scaleFactor = 1.05;
    } else {
      _scaleFactor = 1.1;
    }

    // Clamp so things never get absurdly big or small
    _scaleFactor = _scaleFactor.clamp(0.8, 1.25);
  }

  static double get screenWidth => _screenWidth;
  static double get screenHeight => _screenHeight;

  static bool get isMobile => _screenWidth < Breakpoints.mobile;
  static bool get isTablet =>
      _screenWidth >= Breakpoints.tablet && _screenWidth < Breakpoints.desktop;
  static bool get isDesktop => _screenWidth >= Breakpoints.desktop;
  static bool get isWide => _screenWidth >= Breakpoints.tablet;

  /// Scale a pixel value (font size, icon size, spacing)
  static double sp(double value) => value * _scaleFactor;

  /// Scale only for font sizes — uses a slightly more conservative scale
  static double fp(double value) {
    final fontScale = _scaleFactor.clamp(0.85, 1.15);
    return value * fontScale;
  }

  /// Scale for padding / margin
  static double pp(double value) => value * _scaleFactor;

  /// Returns adaptive horizontal padding
  static double get horizontalPadding {
    if (_screenWidth < Breakpoints.mobile) return 16;
    if (_screenWidth < Breakpoints.tablet) return 24;
    return 32;
  }
}

/// Wraps content with a max-width constraint and centers on wide screens.
/// On mobile, the child fills the full width.
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = 480,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
