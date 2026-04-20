function normalizeWhatsAppNumber(value) {
  return String(value || "").replace(/\D/g, "");
}

function formatOrderMessage(order, shop) {
  const lines = [
    `New order: ${order.orderNumber}`,
    `Shop: ${shop.name}`,
    "",
    "Customer:",
    order.customer.name ? `Name: ${order.customer.name}` : "Name: Not provided",
    order.customer.phone ? `Phone: ${order.customer.phone}` : "Phone: Not provided",
    `Address: ${order.customer.address}`,
    "",
    "Items:"
  ];

  for (const item of order.items) {
    lines.push(`${item.quantity} x ${item.name} = Rs. ${item.subtotal}`);
  }

  lines.push("");
  lines.push(`Item total: Rs. ${order.pricing?.itemTotal ?? order.totalAmount}`);
  lines.push(`Delivery charge: Rs. ${order.pricing?.deliveryCharge ?? 0}`);
  lines.push(`Final total: Rs. ${order.totalAmount}`);

  if (order.customer.note) {
    lines.push("");
    lines.push(`Note: ${order.customer.note}`);
  }

  if (order.customer.location?.mapsUrl) {
    lines.push("");
    lines.push(`Location: ${order.customer.location.mapsUrl}`);
  }

  return lines.join("\n");
}

function buildWhatsAppOrderUrl(order, shop) {
  const phone = normalizeWhatsAppNumber(shop.whatsappNumber);

  if (!phone) {
    return "";
  }

  const message = formatOrderMessage(order, shop);
  return `https://wa.me/${phone}?text=${encodeURIComponent(message)}`;
}

module.exports = {
  buildWhatsAppOrderUrl,
  formatOrderMessage,
  normalizeWhatsAppNumber
};
