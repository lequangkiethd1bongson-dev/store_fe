# SSM4 Flutter frontend

This app recreates a supermarket shopping flow as a standalone Flutter
frontend, using the supplied SSM4 logo and blue/white branding.

## Run

```powershell
cd ShoppingSmartMart4
flutter pub get
flutter run
```

For a browser preview:

```powershell
flutter run -d chrome
```

## Screens and interactions

- Home, categories, searchable product list, and product details
- Shared in-memory cart with quantity editing and calculated totals
- Checkout address, delivery and payment selection, then a demo success screen
- Order history/status tabs, account page, and validated demo login form
- Pinned home search, floating glass-style tab bar, and slide-out account menu
- Local meat and seasoning banners, with logo-centered placeholders for remote
  images while loading or when the network is unavailable
- Demo sign-in/sign-up screens and a full-screen welcome transition
- Separate staff workspace, opened from the account menu, with shelf map,
  shelf details, warehouse stock, demo sales/invoices, and a simple attendance
  placeholder
- Four product tiers per shelf, with explicit empty-tier indicators, low-stock
  alerts below five units, product-to-shelf search, and three-pulse highlighting
- Warehouse product search and detail sheets with product information and
  received-stock dates
- Camera barcode scanning for intake, shelf stocking, and sales
- Responsive phone-width layout using Material widgets, `Scaffold`, `ListView`,
  `GridView`, `CustomScrollView`, `Navigator`, and local `setState`
- `StoreController` uses `ChangeNotifier` for app-wide demo cart/order state
- Clamped scrolling avoids stretch/overscroll layout distortion; pulling down at
  the top of a main tab runs the demo refresh action

This stage uses sample data only. Sign-in and sign-up validate the interface
and transition but do not authenticate or persist an account. Connect a real
authentication service before using this flow with real user credentials.

The staff workspace is also frontend-only. Inventory, shelf quantities, and
sales are kept in memory and reset when the app restarts. Barcode scanning uses
the device camera, with manual code entry as a fallback. Each `Product` needs
its real package barcode in `barcode` for the scanner to match it; current
sample barcodes are placeholders, not guaranteed product-package codes. Invoice
printing only shows a preview. Backend authorization, persistent inventory,
and physical printer support still need to be integrated.

Sample barcodes for the staff demo:

| Product | Barcode |
| --- | --- |
| Milk | `8938501001001` |
| Apple | `8938501001002` |
| Eggs | `8938501001003` |
| Rice | `8938501001004` |
| Water | `8938501001005` |
| Beef | `8938501001006` |

`GlassButton` in `lib/widgets/common_widgets.dart` is a reusable frosted-glass
button: provide a label, an `onPressed` callback, and optionally an icon. The
bottom navigation uses the same blur, translucency, border, and shadow style.

## Frontend source guide

The main Dart frontend is under `lib/`. Function and screen comments are written
in Vietnamese to explain what each part does:

- `lib/main.dart` starts the app and connects the top-level screens.
- `lib/screens/` contains the customer, checkout, account, and staff screens.
- `lib/state/` contains the in-memory state controllers for shopping and staff.
- `lib/models/` defines product, cart, and order data structures.
- `lib/data/` contains sample products and categories.
- `lib/widgets/` contains reusable interface components.
- `lib/theme/` defines shared colors and visual styles.

The staff workspace is currently opened from the account menu as a frontend
demo. This entry point is for testing the interface only, not real staff access.
When a backend is added, replace the demo entry with an authenticated session
and a role returned by the server. Keep `StaffWorkspace` as the separate staff
interface, but require server-side authorization for every staff operation;
hiding the entry point in the app alone is not access control.
