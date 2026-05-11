import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/widgets/qrmart_branding.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({
    super.key,
    required this.onStart,
    required this.onLogin,
    this.showIntroSplash = false,
    this.onIntroSplashComplete,
  });

  final VoidCallback onStart;
  final VoidCallback onLogin;
  final bool showIntroSplash;
  final VoidCallback? onIntroSplashComplete;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  static const List<_WelcomePageData> _pages = [
    _WelcomePageData(
      title: 'Launch your shop digitally without the usual setup stress',
      subtitle:
          'Set up your qrMart account, verify your number, and get your shop ready for QR ordering in a guided flow.',
      icon: Icons.storefront_rounded,
      accentColor: QrMartPalette.primary,
      highlights: [
        'Quick shop onboarding',
        'Built for local shops',
        'Clean dashboard setup',
      ],
    ),
    _WelcomePageData(
      title: 'Track orders, update products, and stay in control all day',
      subtitle:
          'Keep menus fresh, respond faster to customers, and manage your store from one focused workspace.',
      icon: Icons.receipt_long_rounded,
      accentColor: QrMartPalette.leaf,
      highlights: [
        'Live order handling',
        'Fast menu updates',
        'Shop profile controls',
      ],
    ),
    _WelcomePageData(
      title: 'Everything is ready. Register now and verify your shop profile',
      subtitle:
          'Complete your details, upload shop photos, verify by OTP, and we will place your shop into the review queue.',
      icon: Icons.verified_user_rounded,
      accentColor: QrMartPalette.accentGold,
      highlights: [
        '3 shop photos required',
        'OTP verification step',
        'Under verification status',
      ],
    ),
  ];

  int _pageIndex = 0;
  Timer? _introTimer;
  late bool _showIntroSplash;

  @override
  void initState() {
    super.initState();
    _showIntroSplash = widget.showIntroSplash;
    if (_showIntroSplash) {
      _startIntroTimer();
    }
  }

  @override
  void dispose() {
    _introTimer?.cancel();
    super.dispose();
  }

  void _startIntroTimer() {
    _introTimer?.cancel();
    _introTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) {
        return;
      }

      widget.onIntroSplashComplete?.call();
      setState(() => _showIntroSplash = false);
    });
  }

  void _goToPage(int index) {
    setState(
      () => _pageIndex = index.clamp(0, _pages.length - 1),
    );
  }

  void _goNext() {
    if (_pageIndex >= _pages.length - 1) {
      widget.onStart();
      return;
    }

    _goToPage(_pageIndex + 1);
  }

  @override
  Widget build(BuildContext context) {
    if (_showIntroSplash) {
      return const _IntroSplashScreen();
    }

    final theme = Theme.of(context);

    return Scaffold(
      body: QrMartBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final page = _pages[_pageIndex];
              final isLastPage = _pageIndex == _pages.length - 1;
              final screenWidth = MediaQuery.sizeOf(context).width;
              final availableHeight = constraints.maxHeight - 46;
              final compactHeight = availableHeight < 760;
              final compactWidth = screenWidth < 380;
              final compact = compactHeight || compactWidth;
              final logoHeight = compact ? 108.0 : 146.0;
              final content = _WelcomeContent(
                pageIndex: _pageIndex,
                totalPages: _pages.length,
                page: page,
                theme: theme,
                compact: compact,
                logoHeight: logoHeight,
                isLastPage: isLastPage,
                onPrevious:
                    _pageIndex == 0 ? null : () => _goToPage(_pageIndex - 1),
                onLogin: widget.onLogin,
                onPrimaryAction: isLastPage ? widget.onStart : _goNext,
                onSkip: isLastPage ? null : () => _goToPage(_pages.length - 1),
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: content,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _IntroSplashScreen extends StatelessWidget {
  const _IntroSplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: QrMartBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    QrMartLogo(
                      wordmarkHeight: 112,
                      showWordmark: true,
                      center: true,
                    ),
                    SizedBox(height: 22),
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.6),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BrandedSplashScreen extends StatelessWidget {
  const BrandedSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: QrMartBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: QrMartSurfaceCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const QrMartLogo(
                      wordmarkHeight: 86,
                      showWordmark: true,
                      center: true,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Preparing your shop dashboard',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Checking your session and loading qrMart.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: QrMartPalette.mutedInk,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.6),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({
    required this.icon,
    required this.accentColor,
    required this.compact,
  });

  final IconData icon;
  final Color accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final stackVertically = compact || screenWidth < 360;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: QrMartPalette.border),
      ),
      child: stackVertically
          ? Column(
              children: [
                _WelcomeHeroIcon(
                  accentColor: accentColor,
                  compact: compact,
                  icon: icon,
                ),
                const SizedBox(height: 14),
                Text(
                  'Easy shop setup',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Move from welcome to verification in a simple guided flow.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: QrMartPalette.mutedInk,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : Row(
              children: [
                _WelcomeHeroIcon(
                  accentColor: accentColor,
                  compact: compact,
                  icon: icon,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Easy shop setup',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Move from welcome to verification in a simple guided flow.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: QrMartPalette.mutedInk,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _WelcomeHeroIcon extends StatelessWidget {
  const _WelcomeHeroIcon({
    required this.accentColor,
    required this.compact,
    required this.icon,
  });

  final Color accentColor;
  final bool compact;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 74 : 88,
      height: compact ? 74 : 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withOpacity(0.2),
            accentColor.withOpacity(0.08),
          ],
        ),
      ),
      child: Icon(
        icon,
        size: compact ? 32 : 38,
        color: accentColor,
      ),
    );
  }
}

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent({
    required this.pageIndex,
    required this.totalPages,
    required this.page,
    required this.theme,
    required this.compact,
    required this.logoHeight,
    required this.isLastPage,
    required this.onLogin,
    required this.onPrimaryAction,
    this.onPrevious,
    this.onSkip,
  });

  final int pageIndex;
  final int totalPages;
  final _WelcomePageData page;
  final ThemeData theme;
  final bool compact;
  final double logoHeight;
  final bool isLastPage;
  final VoidCallback? onPrevious;
  final VoidCallback onLogin;
  final VoidCallback onPrimaryAction;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final cardContent = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Column(
        key: ValueKey(pageIndex),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _WelcomeHero(
            icon: page.icon,
            accentColor: page.accentColor,
            compact: compact,
          ),
          SizedBox(height: compact ? 18 : 22),
          Text(
            page.title,
            style: compact
                ? theme.textTheme.headlineSmall
                : theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            page.subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: QrMartPalette.mutedInk,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: compact ? 16 : 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final highlight in page.highlights)
                _FeaturePill(label: highlight),
            ],
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: onPrevious == null
                  ? null
                  : IconButton.filledTonal(
                      onPressed: onPrevious,
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Previous',
                    ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onLogin,
              child: const Text('Login'),
            ),
          ],
        ),
        SizedBox(height: compact ? 6 : 10),
        Center(
          child: QrMartLogo(
            wordmarkHeight: logoHeight,
            showWordmark: true,
            center: true,
          ),
        ),
        SizedBox(height: compact ? 14 : 16),
        QrMartSurfaceCard(child: cardContent),
        SizedBox(height: compact ? 16 : 18),
        _PageDots(
          total: totalPages,
          currentIndex: pageIndex,
        ),
        SizedBox(height: compact ? 16 : 18),
        FilledButton(
          onPressed: onPrimaryAction,
          child: Text(isLastPage ? 'Register Now' : 'Next'),
        ),
        if (onSkip != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: onSkip,
            child: const Text('Skip intro'),
          ),
        ],
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.74),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: QrMartPalette.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: QrMartPalette.ink,
            ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.total,
    required this.currentIndex,
  });

  final int total;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < total; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: index == currentIndex ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: index == currentIndex
                  ? QrMartPalette.primary
                  : QrMartPalette.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

class _WelcomePageData {
  const _WelcomePageData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.highlights,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<String> highlights;
}
