const QRCode = require("qrcode");

async function toDataUrl(text) {
  return QRCode.toDataURL(text, {
    margin: 1,
    width: 512
  });
}

module.exports = {
  toDataUrl
};

