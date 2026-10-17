# ⚖️ Lexspense

**Privacy-First, 100% Offline Expense Tracker for Advocates & Lawyers**

Lexspense is a purpose-built Flutter application designed specifically for Advocates and lawyers to log court fees, printing, typing, notary charges, stamp paper, and travel errands on the fly, and cleanly settle batches with senior advocates with formal PDF vouchers.

---

## 🔒 Privacy & Architecture Highlights

- **100% Offline**: No network permissions are declared in the Android Manifest. The app cannot make internet calls, leak analytics, or track telemetry.
- **Local SQLite Storage**: Normalized SQLite schema enforced by SQLite foreign keys (`PRAGMA foreign_keys = ON`).
- **Lossless Currency Handling**: All financial figures are stored as integer **paise** ($1\text{ INR} = 100\text{ paise}$) to eliminate floating-point rounding errors.
- **Private Receipt Storage**: Receipt images are preserved strictly within the application's private documents directory and referenced by filename.
- **Formal PDF Vouchers**: Generates itemized vouchers with chamber/firm headers, counsel signature lines, and high-resolution attached receipt pages.
- **Home Screen Widget**: Android widget showing live pending expenses and a 1-tap quick add deep link.

---

## 📁 Project Architecture

```
lib/
├── app.dart                                 # Main app shell & bottom navigation
├── main.dart                                # Database bootstrap & entry point
│
├── core/
│   ├── database/
│   │   ├── database_helper.dart             # Singleton SQLite helper & lifecycle hooks
│   │   └── schema.dart                      # DDL statements & category seeds
│   ├── theme/
│   │   ├── app_colors.dart                  # Legal-themed color palette
│   │   └── app_theme.dart                   # Material 3 light & dark themes
│   └── utils/
│       ├── constants.dart                   # Storage and app constants
│       ├── currency_utils.dart              # Paise <-> Rupee conversions & Indian grouping
│       ├── date_utils.dart                  # DB <-> Display date utilities
│       └── icon_map.dart                    # Dynamic icon resolver for DB keys
│
├── data/
│   ├── models/                              # Data models with SQLite serialization
│   │   ├── client_matter.dart               # Cases / client matters
│   │   ├── expense.dart                     # Expenses (unpaid if reimbursement_id is null)
│   │   ├── expense_category.dart            # Categories with soft-delete
│   │   ├── expense_view.dart                # Denormalized JOIN view for fast UI rendering
│   │   ├── receipt_image.dart               # Associated receipt files
│   │   └── reimbursement.dart               # Reimbursement payout batches
│   │
│   └── repositories/                        # Repository layer
│       ├── category_repository.dart         # Category queries & soft-delete
│       ├── expense_repository.dart          # Expense queries, JOINs, file cleanup
│       ├── matter_repository.dart           # Matter CRUD & archive management
│       ├── receipt_repository.dart          # Receipt image queries
│       └── reimbursement_repository.dart    # Atomic batch reimbursement transaction
│
├── providers/                               # Riverpod state management
│   ├── category_provider.dart               # Active & all categories
│   ├── database_provider.dart               # Repositories & services registry
│   ├── expense_provider.dart                # Unpaid expenses & batch expenses
│   ├── matter_provider.dart                 # Active & all matters
│   ├── reimbursement_provider.dart          # Reimbursements list & detail
│   ├── selection_provider.dart              # Multi-select state for dashboard
│   └── settings_provider.dart               # SharedPreferences counsel profile
│
├── services/                                # Business & hardware services
│   ├── pdf_service.dart                     # PDF voucher layout & system share sheet
│   ├── receipt_storage_service.dart         # App-private filesystem management
│   └── widget_sync_service.dart             # Android HomeWidget sync
│
└── ui/
    └── screens/
        ├── dashboard/                       # Unpaid expenses dashboard & batch claim
        │   ├── dashboard_screen.dart
        │   └── widgets/
        │       ├── expense_list_tile.dart
        │       ├── mark_paid_bottom_sheet.dart
        │       └── summary_header.dart
        │
        ├── add_expense/                     # Fast on-the-go expense logging
        │   ├── add_expense_screen.dart
        │   └── widgets/
        │       ├── amount_input.dart
        │       ├── category_picker.dart
        │       ├── matter_picker.dart
        │       └── receipt_capture.dart
        │
        ├── history/                         # Reimbursement archive & PDF generation
        │   ├── history_screen.dart
        │   ├── reimbursement_detail_screen.dart
        │   └── widgets/
        │       ├── reimbursement_tile.dart
        │
        ├── matters/                         # Case & matter management
        │   └── matters_screen.dart
        │
        └── settings/                        # Counsel profile & category settings
            ├── category_management_screen.dart
            └── settings_screen.dart
```
## 🧪 Running Unit Tests

Run the included unit tests for currency precision and SQLite models:
```bash
flutter test
```
