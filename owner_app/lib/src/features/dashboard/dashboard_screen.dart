import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/qrmart_branding.dart';
import '../auth/session_controller.dart';
import 'dashboard_controller.dart';
import 'owner_repository.dart';
import 'widgets/orders_tab.dart';
import 'widgets/products_tab.dart';
import 'widgets/profile_tab.dart';
import 'widgets/qr_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.repository,
    required this.sessionController,
    required this.onLogout,
  });

  final OwnerRepository repository;
  final SessionController sessionController;
  final VoidCallback onLogout;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardController _controller;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = DashboardController(
      repository: widget.repository,
      sessionController: widget.sessionController,
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.loading && _controller.shop == null) {
          return const _DashboardLoadingState();
        }

        if (_controller.shop == null) {
          return _DashboardErrorState(
            message: _controller.error ??
                'The dashboard could not be loaded for this account.',
            onRetry: _controller.load,
            onLogout: widget.onLogout,
          );
        }

        final tabs = [
          OrdersTab(controller: _controller),
          ProductsTab(controller: _controller),
          ProfileTab(controller: _controller),
          QrTab(controller: _controller),
        ];

        return Scaffold(
          body: QrMartBackground(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _DashboardHeader(
                      controller: _controller,
                      onRefresh: _controller.mutating
                          ? null
                          : () => _controller.load(showLoader: false),
                      onLogout: widget.onLogout,
                    ),
                  ),
                  if ((_controller.error ?? '').isNotEmpty ||
                      (_controller.notice ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _BannerStrip(
                        error: _controller.error,
                        notice: _controller.notice,
                        onClose: _controller.clearBanner,
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: IndexedStack(
                        index: _tabIndex,
                        children: tabs,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: (index) => setState(() => _tabIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Orders',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: 'Products',
              ),
              NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront),
                label: 'Shop',
              ),
              NavigationDestination(
                icon: Icon(Icons.qr_code_2_outlined),
                selectedIcon: Icon(Icons.qr_code_2),
                label: 'QR',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.controller,
    required this.onRefresh,
    required this.onLogout,
  });

  final DashboardController controller;
  final VoidCallback? onRefresh;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 430;
    final summaryText = compact
        ? 'Manage orders, products, and your shop QR from one dashboard.'
        : 'Manage orders and products for ${controller.owner?.name ?? 'your team'} from one clean local-shop dashboard.';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              QrMartLogo(
                iconSize: compact ? 30 : 32,
                wordmarkHeight: compact ? 54 : 60,
                showWordmark: true,
              ),
              const Spacer(),
              _HeaderActionButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh',
                onTap: onRefresh,
              ),
              const SizedBox(width: 10),
              _HeaderActionButton(
                icon: Icons.logout_rounded,
                tooltip: 'Logout',
                onTap: onLogout,
                compact: compact,
              ),
            ],
          ),
          SizedBox(height: compact ? 14 : 18),
          QrMartSectionEyebrow(label: _greetingForNow()),
          SizedBox(height: compact ? 12 : 14),
          Text(
            controller.shop?.name ?? 'Your shop',
            style: compact
                ? theme.textTheme.titleLarge?.copyWith(fontSize: 22)
                : theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            summaryText,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: QrMartPalette.mutedInk,
            ),
          ),
          SizedBox(height: compact ? 14 : 18),
          _RevenueStrip(
            value: formatCurrency(controller.todayRevenue),
            compact: compact,
          ),
        ],
      ),
    );
  }

  String _greetingForNow() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }
}

class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: QrMartBackground(
        child: SafeArea(
          child: Center(
            child: QrMartSurfaceCard(
              padding: EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QrMartLogo(
                    wordmarkHeight: 84,
                    showWordmark: true,
                    center: true,
                  ),
                  SizedBox(height: 18),
                  CircularProgressIndicator(strokeWidth: 2.6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({
    required this.message,
    required this.onRetry,
    required this.onLogout,
  });

  final String message;
  final Future<void> Function({bool showLoader}) onRetry;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: QrMartBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: QrMartSurfaceCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const QrMartLogo(
                      wordmarkHeight: 88,
                      showWordmark: true,
                      center: true,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Dashboard unavailable',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: QrMartPalette.mutedInk,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: () => onRetry(),
                      child: const Text('Retry'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: onLogout,
                      child: const Text('Logout'),
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

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: compact ? 42 : 46,
          height: compact ? 42 : 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: QrMartPalette.border),
          ),
          child: Icon(icon),
        ),
      ),
    );
  }
}

class _RevenueStrip extends StatelessWidget {
  const _RevenueStrip({
    required this.value,
    required this.compact,
  });

  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 16,
        vertical: compact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: QrMartPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            width: compact ? 36 : 40,
            height: compact ? 36 : 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4ED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: QrMartPalette.leaf,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today earning',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: QrMartPalette.mutedInk,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: compact ? 20 : 22,
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

class _BannerStrip extends StatelessWidget {
  const _BannerStrip({
    required this.error,
    required this.notice,
    required this.onClose,
  });

  final String? error;
  final String? notice;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isError = (error ?? '').isNotEmpty;
    final message = isError ? error! : notice!;

    return Container(
      decoration: BoxDecoration(
        color: isError ? colors.errorContainer : colors.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isError ? colors.error.withOpacity(0.15) : QrMartPalette.border,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError
                    ? colors.onErrorContainer
                    : colors.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}
