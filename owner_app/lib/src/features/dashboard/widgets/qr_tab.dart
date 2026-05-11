import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/adaptive_image.dart';
import '../dashboard_controller.dart';

class QrTab extends StatefulWidget {
  const QrTab({
    super.key,
    required this.controller,
  });

  final DashboardController controller;

  @override
  State<QrTab> createState() => _QrTabState();
}

class _QrTabState extends State<QrTab> {
  final _baseUrlController = TextEditingController();
  String _syncedBaseUrl = '';

  @override
  void dispose() {
    _baseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentBase = widget.controller.qrBaseUrl;

    if (currentBase.isNotEmpty && currentBase != _syncedBaseUrl) {
      _syncedBaseUrl = currentBase;
      _baseUrlController.text = currentBase;
    }

    final qrInfo = widget.controller.qrInfo;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shop QR code', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                if (qrInfo != null)
                  Center(
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: AdaptiveImage(
                        source: qrInfo.qrDataUrl,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  )
                else
                  const Text('QR code is loading.'),
                if (qrInfo != null) ...[
                  const SizedBox(height: 16),
                  SelectableText(qrInfo.qrUrl),
                ],
                const SizedBox(height: 18),
                TextField(
                  controller: _baseUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Live website domain',
                    hintText: 'https://yourdomain.com',
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: widget.controller.mutating
                      ? null
                      : () => widget.controller.refreshQr(_baseUrlController.text),
                  child: const Text('Refresh QR with this URL'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: qrInfo == null
                      ? null
                      : () => Clipboard.setData(ClipboardData(text: qrInfo.qrUrl)),
                  child: const Text('Copy current shop link'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

