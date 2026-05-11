import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/adaptive_image.dart';
import '../../../core/widgets/qrmart_branding.dart';
import '../../../models/product.dart';
import '../dashboard_controller.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({
    super.key,
    required this.controller,
    this.product,
  });

  final DashboardController controller;
  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController(text: 'General');
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isAvailable = true;
  String? _imagePath;

  Product? get _product => widget.product;
  bool get _editing => _product != null;

  @override
  void initState() {
    super.initState();
    final product = _product;
    if (product == null) {
      return;
    }

    _nameController.text = product.name;
    _priceController.text = product.price.truncateToDouble() == product.price
        ? product.price.toStringAsFixed(0)
        : product.price.toStringAsFixed(2);
    _categoryController.text = product.category;
    _descriptionController.text = product.description;
    _isAvailable = product.isAvailable;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (file == null || !mounted) {
      return;
    }

    setState(() => _imagePath = file.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ok = await widget.controller.saveProduct(
      productId: _product?.id,
      name: _nameController.text,
      price: _priceController.text,
      category: _categoryController.text,
      description: _descriptionController.text,
      isAvailable: _isAvailable,
      imagePath: _imagePath,
    );

    if (ok && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final busy = widget.controller.mutating;
        final error = widget.controller.error;
        final remoteImageSource = _product == null
            ? ''
            : widget.controller.resolveAsset(_product!.imageUrl);

        return Scaffold(
          body: QrMartBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton.filledTonal(
                          onPressed: busy
                              ? null
                              : () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          tooltip: 'Back',
                        ),
                        const SizedBox(height: 12),
                        QrMartSurfaceCard(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                QrMartSectionEyebrow(
                                  label: _editing
                                      ? 'Edit product on separate page'
                                      : 'Add product on separate page',
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _editing
                                      ? 'Update product details'
                                      : 'Create a new product',
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Price, category, photo, and availability stay in one clean screen so editing is easier.',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: QrMartPalette.mutedInk,
                                  ),
                                ),
                                if ((error ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 18),
                                  _EditorBanner(message: error!),
                                ],
                                const SizedBox(height: 22),
                                Text(
                                  'Preview',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                _ProductPreviewCard(
                                  name: _nameController.text.trim().isEmpty
                                      ? 'Product name'
                                      : _nameController.text.trim(),
                                  category:
                                      _categoryController.text.trim().isEmpty
                                          ? 'General'
                                          : _categoryController.text.trim(),
                                  price: _previewPrice(),
                                  description:
                                      _descriptionController.text.trim().isEmpty
                                          ? 'Short product description'
                                          : _descriptionController.text.trim(),
                                  isAvailable: _isAvailable,
                                  remoteImageSource: remoteImageSource,
                                  selectedImageName: _imagePath == null
                                      ? null
                                      : _fileName(_imagePath!),
                                ),
                                const SizedBox(height: 22),
                                Text(
                                  'Product info',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Product name',
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  onChanged: (_) => setState(() {}),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Product name is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _priceController,
                                  decoration: const InputDecoration(
                                    labelText: 'Price',
                                    hintText: 'Enter price',
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Price is required';
                                    }
                                    if (double.tryParse(value.trim()) == null) {
                                      return 'Enter a valid price';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _categoryController,
                                  decoration: const InputDecoration(
                                    labelText: 'Category',
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _descriptionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Description',
                                  ),
                                  maxLines: 4,
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 12),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Available for ordering'),
                                  subtitle: const Text(
                                    'Turn this off if you want to hide the item for now.',
                                  ),
                                  value: _isAvailable,
                                  onChanged: busy
                                      ? null
                                      : (value) {
                                          setState(() => _isAvailable = value);
                                        },
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: busy ? null : _pickImage,
                                  icon: const Icon(Icons.image_outlined),
                                  label: Text(
                                    _imagePath == null &&
                                            (_product?.imageUrl ?? '').isEmpty
                                        ? 'Choose product image'
                                        : 'Change product image',
                                  ),
                                ),
                                if (_imagePath != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Selected image: ${_fileName(_imagePath!)}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: QrMartPalette.mutedInk,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 22),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: busy ? null : _save,
                                    child: Text(
                                      busy
                                          ? 'Saving...'
                                          : _editing
                                              ? 'Update product'
                                              : 'Save product',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: busy
                                        ? null
                                        : () =>
                                            Navigator.of(context).maybePop(),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _previewPrice() {
    final value = double.tryParse(_priceController.text.trim());
    return value == null ? 'Add price' : formatCurrency(value);
  }
}

class _ProductPreviewCard extends StatelessWidget {
  const _ProductPreviewCard({
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.isAvailable,
    required this.remoteImageSource,
    required this.selectedImageName,
  });

  final String name;
  final String category;
  final String price;
  final String description;
  final bool isAvailable;
  final String remoteImageSource;
  final String? selectedImageName;

  @override
  Widget build(BuildContext context) {
    final hasRemoteImage =
        remoteImageSource.isNotEmpty && selectedImageName == null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: QrMartPalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            height: 86,
            child: hasRemoteImage
                ? AdaptiveImage(
                    source: remoteImageSource,
                    borderRadius: BorderRadius.circular(20),
                    placeholder: _PreviewPlaceholder(
                        selectedImageName: selectedImageName),
                  )
                : _PreviewPlaceholder(selectedImageName: selectedImageName),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  price,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: QrMartPalette.primaryDark,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PreviewChip(label: category),
                    _PreviewChip(
                      label: isAvailable ? 'Available' : 'Hidden',
                      active: isAvailable,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: QrMartPalette.mutedInk,
                      ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (selectedImageName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'New image selected: $selectedImageName',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: QrMartPalette.primaryDark,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder({
    required this.selectedImageName,
  });

  final String? selectedImageName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Icon(
        selectedImageName == null
            ? Icons.image_outlined
            : Icons.check_circle_outline_rounded,
        color: selectedImageName == null
            ? QrMartPalette.mutedInk
            : QrMartPalette.leaf,
        size: 30,
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({
    required this.label,
    this.active = false,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE7F3EA) : QrMartPalette.softSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: active ? QrMartPalette.leaf : QrMartPalette.ink,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _EditorBanner extends StatelessWidget {
  const _EditorBanner({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

String _fileName(String path) {
  final segments = path.split(RegExp(r'[\\/]'));
  return segments.isEmpty ? path : segments.last;
}
