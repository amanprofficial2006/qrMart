import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/adaptive_image.dart';
import '../../../core/widgets/qrmart_branding.dart';
import '../../../models/product.dart';
import '../dashboard_controller.dart';
import 'product_form_screen.dart';

class ProductsTab extends StatelessWidget {
  const ProductsTab({
    super.key,
    required this.controller,
  });

  final DashboardController controller;

  Future<void> _openProductForm(
    BuildContext context, {
    Product? product,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProductFormScreen(
          controller: controller,
          product: product,
        ),
      ),
    );
  }

  Future<void> _deleteProduct(BuildContext context, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete product'),
          content: Text('Delete ${product.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await controller.deleteProduct(product.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = controller.products;
    final availableCount =
        products.where((product) => product.isAvailable).length;
    final hiddenCount = products.length - availableCount;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Products', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Keep your product list clean and open add or edit on a separate page.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: QrMartPalette.mutedInk,
                      ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: controller.mutating
                        ? null
                        : () => _openProductForm(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add new product'),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ProductStatPill(
                      label: '${products.length}',
                      caption: 'Total items',
                    ),
                    _ProductStatPill(
                      label: '$availableCount',
                      caption: 'Visible now',
                    ),
                    _ProductStatPill(
                      label: '$hiddenCount',
                      caption: 'Hidden items',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (products.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: QrMartPalette.primarySoft,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      size: 34,
                      color: QrMartPalette.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No products added yet',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use the button above to open the add product page and create your first item.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: QrMartPalette.mutedInk,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...products.map(
            (product) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProductCard(
                product: product,
                imageSource: controller.resolveAsset(product.imageUrl),
                busy: controller.mutating,
                onEdit: () => _openProductForm(context, product: product),
                onDelete: () => _deleteProduct(context, product),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.imageSource,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final String imageSource;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 82,
                  height: 82,
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
                        product.name.isEmpty
                            ? '?'
                            : product.name[0].toUpperCase(),
                        style: Theme.of(context).textTheme.titleLarge,
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
                        product.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatCurrency(product.price),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: QrMartPalette.primaryDark,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _TagChip(
                            label: product.category.isEmpty
                                ? 'General'
                                : product.category,
                          ),
                          _TagChip(
                            label: product.isAvailable ? 'Available' : 'Hidden',
                            highlight: product.isAvailable,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (product.description.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                product.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: QrMartPalette.mutedInk,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductStatPill extends StatelessWidget {
  const _ProductStatPill({
    required this.label,
    required this.caption,
  });

  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: QrMartPalette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: QrMartPalette.primaryDark,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: QrMartPalette.mutedInk,
                ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    this.highlight = false,
  });

  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFE7F3EA)
            : Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlight ? const Color(0xFFB6D3BF) : QrMartPalette.border,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: highlight ? QrMartPalette.leaf : QrMartPalette.ink,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
