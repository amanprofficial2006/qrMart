# qrMart

QR-based ordering MVP for small shops.

## Project Structure

```txt
.
├── src/                # Express API, MongoDB models, FCM, WhatsApp fallback
├── frontend/           # React customer QR ordering app
├── .env                # Local backend secrets, ignored by git
└── .env.example        # Safe backend env template
```

## Local Setup

Backend:

```bash
npm install
npm run seed
npm start
```

Frontend:

```bash
cd frontend
npm install
npm run dev
```

Render deployment:

```txt
Frontend/customer app: https://qrmart-01.onrender.com
Backend API: https://qrmart.onrender.com
```

Use these backend env values on Render:

```txt
APP_BASE_URL=https://qrmart-01.onrender.com
CORS_ORIGIN=https://qrmart-01.onrender.com,https://qrmart.onrender.com
```

Open:

```txt
http://localhost:5173/shop/aman-general-store
```

Owner panel:

```txt
http://localhost:5173/
http://localhost:5173/register
http://localhost:5173/login
http://localhost:5173/dashboard
```

Customer QR route:

```txt
http://localhost:5173/shop/:slug
```

Old development links under `/owner/*` and `/s/:slug` still work as aliases, but new QR codes use `/shop/:slug`.

## Important Security Notes

- Do not commit `.env`.
- Do not commit Firebase service account JSON files.
- Rotate the MongoDB password if this URI was shared anywhere public.
- Replace the local `ADMIN_API_KEY` and `OWNER_API_KEY` before deployment.
- Browser FCM notifications need Firebase web config values in `frontend/.env`.

## Useful API Calls

Create a shop:

```http
POST /api/v1/admin/shops
x-api-key: your-admin-api-key
```

Create a product:

```http
POST /api/v1/admin/shops/:shopId/products
x-api-key: your-admin-api-key
```

Customer shop page data:

```http
GET /api/v1/public/shops/:slug
```

Create customer order:

```http
POST /api/v1/public/shops/:slug/orders
```

Register owner FCM token:

```http
POST /api/v1/owner/devices
Authorization: Bearer owner-jwt-token
```

Owner authentication:

```http
POST /api/v1/auth/register
POST /api/v1/auth/login
GET /api/v1/auth/me
```

Owner dashboard APIs:

```http
GET /api/v1/owner/profile
PATCH /api/v1/owner/profile
POST /api/v1/owner/profile/logo
GET /api/v1/owner/products
POST /api/v1/owner/products
PATCH /api/v1/owner/products/:productId
DELETE /api/v1/owner/products/:productId
GET /api/v1/owner/orders
PATCH /api/v1/owner/orders/:orderId/status
GET /api/v1/owner/qr
```

Payment settings live in the owner shop profile:

```txt
Delivery charge
UPI ID
Payment QR image
```

Real-time order updates use Socket.IO. The frontend connects with the owner JWT and listens for:

```txt
order:new
order:updated
```

For browser FCM push notifications, add these to `frontend/.env`:

```txt
VITE_FIREBASE_API_KEY=
VITE_FIREBASE_AUTH_DOMAIN=
VITE_FIREBASE_PROJECT_ID=
VITE_FIREBASE_MESSAGING_SENDER_ID=
VITE_FIREBASE_APP_ID=
VITE_FIREBASE_VAPID_KEY=
```
