import 'package:flutter/material.dart';

import '../../../core/widgets/qrmart_branding.dart';
import '../../../models/shop.dart';
import '../dashboard_controller.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({
    super.key,
    required this.controller,
    required this.shop,
  });

  final DashboardController controller;
  final Shop shop;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _deliveryChargeController = TextEditingController();
  final _upiIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final shop = widget.shop;
    _nameController.text = shop.name;
    _ownerNameController.text = shop.ownerName;
    _phoneController.text = shop.phone;
    _whatsappController.text = shop.whatsappNumber;
    _addressController.text = shop.address;
    _descriptionController.text = shop.description;
    _deliveryChargeController.text =
        shop.deliveryCharge.truncateToDouble() == shop.deliveryCharge
            ? shop.deliveryCharge.toStringAsFixed(0)
            : shop.deliveryCharge.toString();
    _upiIdController.text = shop.upiId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _deliveryChargeController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ok = await widget.controller.updateProfile(
      name: _nameController.text,
      ownerName: _ownerNameController.text,
      phone: _phoneController.text,
      whatsappNumber: _whatsappController.text,
      address: _addressController.text,
      description: _descriptionController.text,
      deliveryCharge: _deliveryChargeController.text,
      upiId: _upiIdController.text,
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

        return Scaffold(
          body: QrMartBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
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
                                const QrMartSectionEyebrow(
                                  label: 'Edit shop on separate page',
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Update shop details',
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Important business details are grouped here so changing your shop profile feels easier.',
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
                                  'Business details',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Shop name',
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Shop name is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _ownerNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Owner name',
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _descriptionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Description',
                                  ),
                                  maxLines: 4,
                                ),
                                const SizedBox(height: 22),
                                Text(
                                  'Contact',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone',
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _whatsappController,
                                  decoration: const InputDecoration(
                                    labelText: 'WhatsApp number',
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _addressController,
                                  decoration: const InputDecoration(
                                    labelText: 'Address',
                                  ),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 22),
                                Text(
                                  'Payment and delivery',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _deliveryChargeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Delivery charge',
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  validator: (value) {
                                    final trimmed = value?.trim() ?? '';
                                    if (trimmed.isEmpty) {
                                      return null;
                                    }
                                    if (double.tryParse(trimmed) == null) {
                                      return 'Enter a valid delivery charge';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _upiIdController,
                                  decoration: const InputDecoration(
                                    labelText: 'UPI ID',
                                  ),
                                ),
                                const SizedBox(height: 22),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: busy ? null : _save,
                                    child: Text(
                                      busy ? 'Saving...' : 'Save shop profile',
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
