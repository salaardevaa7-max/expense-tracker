// ===========================================================================
//  The glass design system, carried over from the prototype.
//
//  Two things make translucency read as glass rather than as a grey film:
//  a blur of what is behind it, and a crisp specular highlight along the top
//  edge where light would catch. Skip the highlight and you get flat tinted
//  plastic. Every surface here has both.
//
//  Transparency is applied with withAlpha() throughout, never withOpacity()
//  and never Color.red/.green/.blue — those three are deprecated in current
//  Flutter, and a deprecated call in a hundred places is a migration waiting
//  to happen.
// ===========================================================================

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';

/// White at a given opacity. Used constantly, so it earns a short name.
Color w(double o) => Colors.white.withAlpha((o * 255).round().clamp(0, 255));

/// Any colour, softened.
Color fade(Color c, double o) => c.withAlpha((o * 255).round().clamp(0, 255));

/// The palette. Named [Hue] rather than the obvious `Ink`, which is already
/// a Material widget.
class Hue {
  // A deep navy background that lets warm accents sing against it.
  static const bg = Color(0xFF06111D);
  static const lift = Color(0xFF0B1B2B);

  static const text = Color(0xFFEAF2F9);
  static const text2 = Color(0xFFB6C7D6);
  static const text3 = Color(0xFF7E93A6);

  // The liquid in the vessel travels along these three as the month fills up,
  // so its colour alone tells you how deep in you are.
  static const calm = Color(0xFF2E8FD6);
  static const mid = Color(0xFF9A86D4);
  static const hot = Color(0xFFF2A93B);

  static const good = Color(0xFF6FD3A3);
  static const bad = Color(0xFFE9705F);

  // Category colours, drawn from the palette of Indian banknotes.
  static const food = Color(0xFF6FD3A3);
  static const travel = Color(0xFF2E8FD6);
  static const shopping = Color(0xFFE07AB0);
  static const bills = Color(0xFFF2A93B);
  static const rent = Color(0xFF9A86D4);
  static const fun = Color(0xFFE9705F);

  static Color forCategory(String c) {
    switch (c) {
      case Cat.food:
        return food;
      case Cat.travel:
        return travel;
      case Cat.shopping:
        return shopping;
      case Cat.bills:
        return bills;
      case Cat.rent:
        return rent;
      case Cat.fun:
        return fun;
      default:
        return text3;
    }
  }

  static IconData iconFor(String c) {
    switch (c) {
      case Cat.food:
        return Icons.local_cafe_outlined;
      case Cat.travel:
        return Icons.directions_car_outlined;
      case Cat.shopping:
        return Icons.shopping_bag_outlined;
      case Cat.bills:
        return Icons.receipt_long_outlined;
      case Cat.rent:
        return Icons.home_outlined;
      case Cat.fun:
        return Icons.local_activity_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  /// Where the liquid surface sits on the blue → lavender → amber walk.
  static Color liquidAt(double t) {
    final x = t.clamp(0.0, 1.0);
    if (x <= 0.5) {
      return Color.lerp(calm, mid, x / 0.5) ?? calm;
    }
    return Color.lerp(mid, hot, (x - 0.5) / 0.5) ?? hot;
  }
}

/// Figures are set in a serif and with tabular figures, so a column of them
/// lines up and a number reads like money rather than like UI chrome.
/// 'serif' is a platform alias — Android resolves it to Noto Serif — so
/// there is no font file to bundle, and none to ship wrongly.
const String figureFamily = 'serif';

TextStyle figure(double size,
        {Color color = Hue.text, FontWeight weight = FontWeight.w600}) =>
    TextStyle(
      fontFamily: figureFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.06,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

TextStyle label(double size,
        {Color color = Hue.text3, FontWeight weight = FontWeight.w500}) =>
    TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: 0.1,
      height: 1.35,
    );

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Hue.bg,
      colorScheme: const ColorScheme.dark(
        primary: Hue.calm,
        secondary: Hue.hot,
        surface: Hue.lift,
        error: Hue.bad,
      ),
      splashFactory: NoSplash.splashFactory,
      textSelectionTheme: const TextSelectionThemeData(cursorColor: Hue.calm),
    );

/// The system bars take the app's own colour, so it runs edge to edge rather
/// than sitting in a box of someone else's grey.
void paintSystemBars() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Hue.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
}

/// A translucent panel with a real blur behind it and a specular top edge.
///
/// [blur] costs GPU time every frame, so it is only worth paying where
/// something interesting sits behind the panel. Rows in a long list pass
/// blur: 0 and get the tint and the highlight without the expense — on a
/// mid-range Android phone that is the difference between smooth and not.
class Glass extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blur;
  final double tint;
  final EdgeInsetsGeometry padding;
  final Color? glow;
  final VoidCallback? onTap;

  const Glass({
    super.key,
    required this.child,
    this.radius = 22,
    this.blur = 16,
    this.tint = 0.055,
    this.padding = const EdgeInsets.all(16),
    this.glow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);

    Widget body = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        border: Border.all(color: w(0.11), width: 0.7),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [w(tint + 0.045), w(tint * 0.5)],
        ),
      ),
      child: Stack(
        children: [
          Padding(padding: padding, child: child),
          // The specular edge: bright at the crown, gone by the shoulders.
          Positioned(
            left: radius * 0.55,
            right: radius * 0.55,
            top: 0,
            height: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [w(0), w(0.5), w(0)]),
              ),
            ),
          ),
        ],
      ),
    );

    if (blur > 0) {
      body = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: body,
      );
    }

    Widget out = ClipRRect(borderRadius: shape, child: body);

    final g = glow;
    if (g != null) {
      out = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: shape,
          boxShadow: [
            BoxShadow(
              color: g,
              blurRadius: 34,
              spreadRadius: -14,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: out,
      );
    }

    final tap = onTap;
    if (tap != null) {
      out = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          tap();
        },
        child: out,
      );
    }

    return out;
  }
}

/// A small pill — category chips, filters, tags.
class Pill extends StatelessWidget {
  final String text;
  final bool on;
  final Color? dot;
  final VoidCallback? onTap;

  const Pill({super.key, required this.text, this.on = false, this.dot, this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = dot ?? Hue.calm;
    final tap = onTap;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: tap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              tap();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: on ? fade(accent, 0.18) : w(0.05),
          border: Border.all(
            color: on ? fade(accent, 0.55) : w(0.10),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: on ? Hue.text : Hue.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The primary action — solid and warm, and the only thing on a screen that
/// looks like this, so it is never ambiguous which button to press.
class Solid extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final Color color;
  final IconData? icon;

  const Solid({
    super.key,
    required this.text,
    this.onTap,
    this.color = Hue.calm,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final tap = onTap;
    final off = tap == null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: off
          ? null
          : () {
              HapticFeedback.mediumImpact();
              tap();
            },
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: off ? w(0.06) : color,
          boxShadow: off
              ? null
              : [
                  BoxShadow(
                    color: fade(color, 0.34),
                    blurRadius: 22,
                    spreadRadius: -6,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19, color: off ? Hue.text3 : Hue.bg),
              const SizedBox(width: 9),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: off ? Hue.text3 : Hue.bg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A quiet secondary button.
class Ghost extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color color;

  const Ghost({
    super.key,
    required this.text,
    this.onTap,
    this.icon,
    this.color = Hue.text2,
  });

  @override
  Widget build(BuildContext context) {
    final tap = onTap;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: tap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              tap();
            },
      child: Container(
        height: 46,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: w(0.05),
          border: Border.all(color: w(0.10), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A section heading, set small and wide so it recedes behind the numbers.
class Heading extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const Heading(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.3,
                color: Hue.text3,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A brief message at the bottom of the screen. Uses the app's own look
/// rather than the stock Material snackbar, which would stand out as
/// borrowed the moment it appeared.
void say(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Hue.lift,
    elevation: 0,
    duration: const Duration(milliseconds: 2200),
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: w(0.12), width: 0.8),
    ),
    content: Text(
      message,
      style: const TextStyle(fontSize: 13.5, color: Hue.text, fontWeight: FontWeight.w500),
    ),
  ));
}
