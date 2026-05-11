import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/adaptive_image.dart';
import '../../../core/widgets/qrmart_branding.dart';
import '../dashboard_controller.dart';

class ShopMediaScreen extends StatefulWidget {
  const ShopMediaScreen({
    super.key,
    required this.controller,
  });

  final DashboardController controller;

  @override
  State<ShopMediaScreen> createState() => _ShopMediaScreenState();
}

class _ShopMediaScreenState extends State<ShopMediaScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickLogo() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (file == null) {
      return;
    }

    await widget.controller.uploadLogo(file.path);
  }

  Future<void> _pickPaymentQr() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (file == null) {
      return;
    }

    await widget.controller.uploadPaymentQr(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final busy = widget.controller.mutating;
        final error = widget.controller.error;
        final shop = widget.controller.shop;

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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const QrMartSectionEyebrow(
                                label: 'Manage media on separate page',
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Update logo and payment QR',
                                style: theme.textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Customers see these first, so you can update them here without disturbing other shop settings.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: QrMartPalette.mutedInk,
                                ),
                              ),
                              if ((error ?? '').isNotEmpty) ...[
                                const SizedBox(height: 18),
                                _EditorBanner(message: error!),
                              ],
                              const SizedBox(height: 22),
                              _MediaEditorCard(
                                title: 'Shop logo',
                                subtitle:
                                    'Use a clear square or wide logo so your brand is easy to recognise.',
                                imageSource: widget.controller
                                    .resolveAsset(shop?.logoUrl ?? ''),
                                emptyText: 'No logo uploaded yet.',
                                buttonLabel: 'Upload logo',
                                busy: busy,
                                onTap: _pickLogo,
                              ),
                              const SizedBox(height: 18),
                              _MediaEditorCard(
                                title: 'Payment QR',
                                subtitle:
                                    'Upload the latest QR customers should scan for payment.',
                                imageSource: widget.controller
                                    .resolveAsset(shop?.paymentQrCodeUrl ?? ''),
                                emptyText: 'No payment QR uploaded yet.',
                                buttonLabel: 'Upload payment QR',
                                busy: busy,
                                onTap: _pickPaymentQr,
                              ),
                            ],
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

class _MediaEditorCard extends StatelessWidget {
  const _MediaEditorCard({
    required this.title,
    required this.subtitle,
    required this.imageSource,
    required this.emptyText,
    required this.buttonLabel,
    required this.busy,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String imageSource;
  final String emptyText;
  final String buttonLabel;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.74),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: QrMartPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: QrMartPalette.mutedInk,
                ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 210,
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
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onTap,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(buttonLabel),
            ),
          ),
        ],
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
