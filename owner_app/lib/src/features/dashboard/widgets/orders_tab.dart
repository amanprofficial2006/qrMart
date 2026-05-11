import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/order.dart';
import '../dashboard_controller.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({
    super.key,
    required this.controller,
  });

  final DashboardController controller;

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final orders = _showHistory
        ? widget.controller.historyOrders
        : widget.controller.activeOrders;

    return RefreshIndicator(
      onRefresh: widget.controller.refreshOrders,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            children: [
              ChoiceChip(
                label: const Text('Current orders'),
                selected: !_showHistory,
                onSelected: (_) => setState(() => _showHistory = false),
              ),
              ChoiceChip(
                label: const Text('History'),
                selected: _showHistory,
                onSelected: (_) => setState(() => _showHistory = true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (orders.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _showHistory
                      ? 'Completed and closed orders will appear here.'
                      : 'No current orders right now.',
                ),
              ),
            )
          else
            ...orders.map(
              (order) => Padding(
                key: ValueKey(order.id),
                padding: const EdgeInsets.only(bottom: 12),
                child: _OrderCard(
                  controller: widget.controller,
                  order: order,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  const _OrderCard({
    required this.controller,
    required this.order,
  });

  final DashboardController controller;
  final Order order;

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    final ok = await widget.controller.sendOrderNotification(
      orderId: widget.order.id,
      status: widget.order.status,
      message: _messageController.text,
    );

    if (ok && mounted) {
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.orderNumber,
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${formatDateTime(order.createdAt)} - ${order.customer.name.isEmpty ? 'Customer' : order.customer.name}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(label: Text(statusLabel(order.status))),
              ],
            ),
            const SizedBox(height: 14),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text('${item.quantity} x ${item.name}')),
                    Text(formatCurrency(item.subtotal)),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),
            _MetaRow(
                label: 'Item total',
                value: formatCurrency(order.pricing.itemTotal)),
            _MetaRow(
                label: 'Delivery',
                value: formatCurrency(order.pricing.deliveryCharge)),
            _MetaRow(
              label: 'Payment',
              value: order.payment.declaredPaid
                  ? 'Marked paid'
                  : 'Pending or unknown',
            ),
            _MetaRow(
                label: 'Final total', value: formatCurrency(order.totalAmount)),
            if (order.customer.phone.isNotEmpty ||
                order.customer.address.isNotEmpty ||
                order.customer.note.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                [
                  if (order.customer.phone.isNotEmpty)
                    'Phone: ${order.customer.phone}',
                  if (order.customer.address.isNotEmpty)
                    'Address: ${order.customer.address}',
                  if (order.customer.note.isNotEmpty)
                    'Note: ${order.customer.note}',
                ].join('\n'),
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._statusButtons(order),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Send update to customer',
                hintText: 'Your order is being prepared',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed:
                        widget.controller.mutating ? null : _sendNotification,
                    child: const Text('Send notification'),
                  ),
                ),
                if (order.whatsappFallbackUrl.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: null,
                      child: const Text('WhatsApp fallback on web'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _statusButtons(Order order) {
    switch (order.status) {
      case 'placed':
      case 'seen':
        return [
          FilledButton(
            onPressed: widget.controller.mutating
                ? null
                : () => widget.controller
                    .updateOrderStatus(orderId: order.id, status: 'accepted'),
            child: const Text('Accept'),
          ),
          OutlinedButton(
            onPressed: widget.controller.mutating
                ? null
                : () => widget.controller
                    .updateOrderStatus(orderId: order.id, status: 'rejected'),
            child: const Text('Reject'),
          ),
        ];
      case 'accepted':
        return [
          FilledButton(
            onPressed: widget.controller.mutating
                ? null
                : () => widget.controller
                    .updateOrderStatus(orderId: order.id, status: 'preparing'),
            child: const Text('Mark preparing'),
          ),
        ];
      case 'preparing':
        return [
          FilledButton(
            onPressed: widget.controller.mutating
                ? null
                : () => widget.controller
                    .updateOrderStatus(orderId: order.id, status: 'ready'),
            child: const Text('Mark ready'),
          ),
        ];
      case 'ready':
        return [
          FilledButton(
            onPressed: widget.controller.mutating
                ? null
                : () => widget.controller
                    .updateOrderStatus(orderId: order.id, status: 'completed'),
            child: const Text('Complete'),
          ),
        ];
      default:
        return const [];
    }
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value),
        ],
      ),
    );
  }
}
