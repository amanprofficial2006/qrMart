import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/adaptive_image.dart';
import '../../../core/widgets/qrmart_branding.dart';
import '../../../models/shop.dart';
import '../dashboard_controller.dart';
import 'profile_edit_screen.dart';
import 'shop_media_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({
    super.key,
    required this.controller,
  });

  final DashboardController controller;

  Future<void> _openProfileEditor(BuildContext context, Shop shop) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProfileEditScreen(
          controller: controller,
          shop: shop,
        ),
      ),
    );
  }

  Future<void> _openMediaManager(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ShopMediaScreen(controller: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shop = controller.shop;

    if (shop == null) {
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: AdaptiveImage(
                        source: controller.resolveAsset(shop.logoUrl),
                        borderRadius: BorderRadius.circular(24),
                        placeholder: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            shop.name.isEmpty
                                ? '?'
                                : shop.name[0].toUpperCase(),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            shop.ownerName.isEmpty
                                ? 'Owner name not added yet'
                                : 'Owner: ${shop.ownerName}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: QrMartPalette.mutedInk,
                                ),
                          ),
                          const SizedBox(height: 10),
                          _StatusPill(
                            label: shop.isActive
                                ? 'Shop is active'
                                : 'Shop is inactive',
                            active: shop.isActive,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Open details and media on separate pages so editing stays simple.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: QrMartPalette.mutedInk,
                      ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: controller.mutating
                          ? null
                          : () => _openProfileEditor(context, shop),
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('Edit shop details'),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.mutating
                          ? null
                          : () => _openMediaManager(context),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Manage logo & QR'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick details',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _ProfileInfoRow(
                  label: 'Phone',
                  value: _safeValue(shop.phone),
                ),
                _ProfileInfoRow(
                  label: 'WhatsApp',
                  value: _safeValue(shop.whatsappNumber),
                ),
                _ProfileInfoRow(
                  label: 'Address',
                  value: _safeValue(shop.address),
                ),
                _ProfileInfoRow(
                  label: 'Description',
                  value: _safeValue(shop.description),
                ),
                _ProfileInfoRow(
                  label: 'Delivery charge',
                  value: formatCurrency(shop.deliveryCharge),
                ),
                _ProfileInfoRow(
                  label: 'UPI ID',
                  value: _safeValue(shop.upiId),
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current media',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _MediaPreviewTile(
                  title: 'Logo',
                  imageSource: controller.resolveAsset(shop.logoUrl),
                  emptyText: 'No logo uploaded yet.',
                ),
                const SizedBox(height: 14),
                _MediaPreviewTile(
                  title: 'Payment QR',
                  imageSource: controller.resolveAsset(shop.paymentQrCodeUrl),
                  emptyText: 'No payment QR uploaded yet.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: QrMartPalette.mutedInk,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _MediaPreviewTile extends StatelessWidget {
  const _MediaPreviewTile({
    required this.title,
    required this.imageSource,
    required this.emptyText,
  });

  final String title;
  final String imageSource;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 180,
          child: AdaptiveImage(
            source: imageSource,
            borderRadius: BorderRadius.circular(20),
            placeholder: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                emptyText,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.active,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE7F3EA) : QrMartPalette.primarySoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? const Color(0xFFB6D3BF) : QrMartPalette.border,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: active ? QrMartPalette.leaf : QrMartPalette.primaryDark,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

String _safeValue(String value) {
  return value.trim().isEmpty ? 'Not added yet' : value.trim();
}
