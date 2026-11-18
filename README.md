# CNNO Mobile App

Flutter app for **CNNO**, a cinnamon roll business. Customers browse the menu, pre-order for a chosen date, choose pickup or delivery and track their order. The admin manages products, prices, availability and order status. Two Generative AI features are included: Smart Recommendation and an Order Assistant.

UNIMAS TMA3084 Software Engineering Lab, Group 19 "Cinnamon Codes".

## Stack

- Flutter / Dart 3, Material Design 3, Android 8.0+ (API 26+)
- State management: Provider
- Firebase: Authentication (email and password), Cloud Firestore, Cloud Storage, Cloud Functions
- Generative AI: Gemini API, called **only** from Cloud Functions (no API key in the app)

## Screens (Figma UI-01 to UI-09)

| Screen | File | Requirements |
|---|---|---|
| UI-01 Login and Register | `lib/screens/auth/login_screen.dart` | FR-01, FR-02 |
| UI-02 Menu + AI recommendation | `lib/screens/customer/menu_screen.dart` | FR-03, FR-04, FR-AI-01 |
| UI-03 Product detail | `lib/screens/customer/product_detail_screen.dart` | FR-03, FR-04, FR-05 |
| UI-04 Cart | `lib/screens/customer/cart_screen.dart` | FR-05 |
| UI-05 Checkout and pre-order | `lib/screens/customer/checkout_screen.dart` | FR-06, FR-07, FR-08 |
| UI-06 Order status | `lib/screens/customer/order_detail_screen.dart`, `orders_screen.dart` | FR-09, FR-14 |
| UI-07 AI Order Assistant | `lib/screens/customer/assistant_screen.dart` | FR-AI-02 |
| UI-08 Admin orders | `lib/screens/admin/admin_orders_screen.dart` | FR-12, FR-13 |
| UI-09 Admin products | `lib/screens/admin/admin_products_screen.dart`, `product_edit_screen.dart` | FR-11 |
| Email receipt | `functions/index.js` (`sendReceipt`) | FR-10 |

Not built yet: FR-15 order status notification (Could), Reports screen (placeholder).

## Project layout

```
lib/
  config.dart          values still to confirm with the client (lead time, payment methods)
  theme.dart           colours from Figma, font (Inter placeholder)
  data/menu_seed.dart  agreed menu and prices
  models/  services/  state/  screens/  widgets/
functions/             Cloud Functions (Gemini AI, email receipt)
firestore.rules        security rules (customers cannot do admin actions)
storage.rules
test/                  unit tests for business rules
docs/                  Firebase setup guide, LOGAI
```

## Run it

1. Install Flutter and the Android SDK.
2. Set up Firebase once: see [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md).
3. Run:
   ```
   flutter pub get
   flutter run
   ```
4. Tests and checks:
   ```
   flutter analyze
   flutter test
   ```

## Admin account

Register normally in the app, then in the Firebase console open **Firestore > users > (that user)** and change `role` from `customer` to `admin`. Log in again: the admin dashboard opens. Go to **Settings > Load CNNO menu** to load the agreed menu.

## Still to confirm with the client

Pre-order lead time (1 day for now) and accepted payment methods are in `lib/config.dart`. The font is a placeholder (Inter) in `lib/theme.dart`. Also open: CNNO phone number for delivery, cancellation rule.

## AI use

AI-assisted work is logged in [docs/LOGAI.md](docs/LOGAI.md).
