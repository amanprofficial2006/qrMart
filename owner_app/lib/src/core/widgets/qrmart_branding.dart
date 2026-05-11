import 'package:flutter/material.dart';

class QrMartBrandAssets {
  static const logo = 'assets/branding/qrmart_logo.png';
  static const logoAlt = 'assets/branding/qrmart_logo_alt.png';
}

class QrMartPalette {
  static const background = Color(0xFFFFF8F1);
  static const backgroundStrong = Color(0xFFFFF2E7);
  static const surface = Color(0xFFFFFCF8);
  static const card = Color(0xFFFFFEFB);
  static const softSurface = Color(0xFFFFF3E8);
  static const primary = Color(0xFFC94F27);
  static const primaryDark = Color(0xFFAA3F1B);
  static const primarySoft = Color(0xFFFFE6DA);
  static const accentGold = Color(0xFFD58A2C);
  static const leaf = Color(0xFF2D7550);
  static const ink = Color(0xFF2F2117);
  static const mutedInk = Color(0xFF6D594A);
  static const border = Color(0xFFE8D6C5);
  static const shadow = Color(0x1F462C1B);

  static List<BoxShadow> get softShadow => const [
        BoxShadow(
          color: shadow,
          blurRadius: 26,
          offset: Offset(0, 14),
        ),
      ];
}

class QrMartBackground extends StatelessWidget {
  const QrMartBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            QrMartPalette.background,
            QrMartPalette.backgroundStrong,
            Color(0xFFFFFAF4),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -50,
            child: _GlowOrb(
              size: 240,
              color: QrMartPalette.primary.withOpacity(0.16),
            ),
          ),
          Positioned(
            top: 140,
            left: -70,
            child: _GlowOrb(
              size: 170,
              color: QrMartPalette.accentGold.withOpacity(0.12),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: _GlowOrb(
              size: 190,
              color: QrMartPalette.leaf.withOpacity(0.08),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class QrMartSurfaceCard extends StatelessWidget {
  const QrMartSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.alignment,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        color: QrMartPalette.card.withOpacity(0.96),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: QrMartPalette.border),
        boxShadow: QrMartPalette.softShadow,
      ),
      child: child,
    );
  }
}

class QrMartLogo extends StatelessWidget {
  const QrMartLogo({
    super.key,
    this.iconSize = 34,
    this.wordmarkHeight,
    this.showWordmark = true,
    this.center = false,
    this.textColor,
  });

  final double iconSize;
  final double? wordmarkHeight;
  final bool showWordmark;
  final bool center;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    if (showWordmark) {
      return Image.asset(
        QrMartBrandAssets.logo,
        height: wordmarkHeight ?? iconSize * 1.9,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          center ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        _QrMartBagIcon(size: iconSize),
        if (textColor != null) ...[
          SizedBox(width: iconSize * 0.28),
          Text(
            'qrMart',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
          ),
        ],
      ],
    );
  }
}

class QrMartSectionEyebrow extends StatelessWidget {
  const QrMartSectionEyebrow({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: QrMartPalette.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: QrMartPalette.primaryDark,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withOpacity(0),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrMartBagIcon extends StatelessWidget {
  const _QrMartBagIcon({
    required this.size,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: size * 0.2,
            left: size * 0.08,
            right: size * 0.08,
            bottom: size * 0.04,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFD46034),
                    QrMartPalette.primary,
                    QrMartPalette.primaryDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(size * 0.24),
                boxShadow: [
                  BoxShadow(
                    color: QrMartPalette.primary.withOpacity(0.3),
                    blurRadius: size * 0.34,
                    offset: Offset(0, size * 0.14),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: size * 0.02,
            left: size * 0.27,
            right: size * 0.27,
            height: size * 0.34,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: QrMartPalette.ink.withOpacity(0.7),
                  width: size * 0.055,
                ),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(size * 0.22),
                ),
              ),
            ),
          ),
          Positioned(
            top: size * 0.38,
            left: size * 0.22,
            child: _QrSquare(size: size * 0.13),
          ),
          Positioned(
            top: size * 0.38,
            left: size * 0.39,
            child: _QrSquare(size: size * 0.13),
          ),
          Positioned(
            top: size * 0.55,
            left: size * 0.22,
            child: _QrSquare(size: size * 0.13),
          ),
          Positioned(
            top: size * 0.55,
            left: size * 0.49,
            child: _QrSquare(size: size * 0.08),
          ),
          Positioned(
            top: size * 0.5,
            right: size * 0.22,
            child: Container(
              width: size * 0.09,
              height: size * 0.18,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.94),
                borderRadius: BorderRadius.circular(size * 0.04),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrSquare extends StatelessWidget {
  const _QrSquare({
    required this.size,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(size * 0.18),
      ),
    );
  }
}
