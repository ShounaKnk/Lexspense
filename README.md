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

## 📱 User Guide: How to Use Lexspense

Lexspense is built to make on-the-go legal expense tracking frictionless. Here is a complete guide to using every feature of the app:

### 1. Initial Chamber & Profile Setup (First-Time Use)
Before generating your first PDF voucher, set up your counsel profile:
1. Tap the **Settings** icon on the bottom navigation bar.
2. In the **Advocate / Chamber Profile** section, tap the **Edit** icon.
3. Enter your details:
   - **Advocate / Counsel Name** (e.g., *Adv. Rajesh/Rani Sharma*)
   - **Chamber / Law Firm Name** (e.g., *Apex Chambers & Associates*)
   - **Designation** (e.g., *Senior Associate / Junior Counsel*)
   - **Phone / Email** (used for contact details in vouchers)
4. Tap **Save Profile**. These details will automatically appear on all formal PDF vouchers you export.

---

### 2. Managing Courts & Forums
Organize expenses by the courts or administrative tribunals where your matters are listed:
1. Go to **Settings** > **Courts & Tribunals** (or tap the **Courts / Forums** quick-nav card on the Dashboard).
2. Tap **+ Add Forum** at the bottom.
3. Enter the court name (e.g., *Supreme Court of India*, *High Court of Delhi*, *Saket District Court*, *NCLT Delhi*).
4. Tap **Save**.
5. *Tip:* You can tap the three-dot menu `⋮` on any forum to **Edit**, **Archive**, or **Delete** it.

---

### 3. Adding & Managing Client Matters (Cases)
Matters represent the client briefs or court cases you are working on:
1. Go to **Settings** > **Client Matters / Cases** (or tap the **Client Matters** quick-nav card on the Dashboard).
2. Tap **+ Add Matter** at the bottom.
3. Fill in:
   - **Case Title / Client Name** (e.g., *State v. Sharma*, *ABC Corp v. Union of India*, *Mehta Property Dispute*)
   - **Court / Forum (Optional)**: Select the court where this case is being heard from the dropdown.
4. Tap **Save**.
5. *Quick Add on the Fly:* You can also create a new matter directly while logging an expense without leaving the expense form!

---

### 4. Logging an Out-of-Pocket Expense
When you pay for court fees, photocopying, notarization, parking, or travel:
1. Tap the **+ Add Expense** button (floating action button or top right button on the Dashboard, or via the Home Screen Widget).
2. Enter the **Amount Spent** in Rupees (e.g., `450` or `1250.50`).
3. Select the **Client Matter / Case** from the dropdown. (If it's a new case, tap **+ Add New Matter** right beneath the dropdown to create it instantly).
4. Tap the appropriate **Expense Category** chip (*Court Fees*, *Xeroxing & Printing*, *Travel & Conveyance*, *Stamp Paper*, *Clerkage*, *Notary*, etc.).
5. Check or modify the **Expense Date** (defaults to today).
6. *(Optional)* Add **Notes / Description** (e.g., *3 sets of paperbooks for filing court copy*).
7. Attach Receipts:
   - Tap **Attach Photo** or the receipt container.
   - Choose **Capture with Camera** to snap a bill/memo directly, or **Choose from Gallery**.
   - You can attach multiple photos per expense.
8. Tap **Save Expense**. The expense is instantly saved locally, and your dashboard total updates.

---

### 5. Viewing Expense Details & Zooming Receipts
To review full details or view attached bills:
1. Tap anywhere on an expense card in the Dashboard or Reimbursement History.
2. The **Expense Details** screen displays:
   - Status badge (*Pending Settlement* or *Settled / Reimbursed*).
   - Case title and associated Court / Forum.
   - Expense date and time logged.
   - Any notes or description.
   - High-resolution receipt photo gallery.
3. Tap on any receipt thumbnail to view it in full screen with **pinch-to-zoom** and pan capabilities.
4. If an unpaid expense was entered by mistake, tap the **Delete** button at the top right to remove it and its stored images.

---

### 6. Claiming & Settling Reimbursements (Batch Payout)
When your senior or office administrator settles your out-of-pocket expenses:
1. On the **Home Dashboard**, select the expenses that are being reimbursed:
   - Tap the **checkbox** on individual expense cards to select specific items.
   - Or tap **Select All** in the green summary banner to select all pending items at once.
2. The bottom button will update to **Claim ₹X,XXX (N items)**. Tap it.
3. In the confirmation sheet:
   - Select the **Settlement Date**.
   - *(Optional)* Add a reference note (e.g., *Cash received from Chamber Clerk*, *UPI Ref #98765*, *Cheque #401201*).
4. Tap **Mark Reimbursed**. The selected items will be grouped into an immutable reimbursement voucher and moved to your **History**.

---

### 7. Generating & Sharing Formal PDF Vouchers
Generate formal, audit-ready reimbursement vouchers to share via WhatsApp, Email, or Print:
1. Go to the **History** tab in the bottom navigation.
2. Tap on any settled voucher entry (single expense or multi-item batch).
3. Tap **Share Formal PDF Voucher** (or the share icon in the top right).
4. Lexspense generates an itemized PDF that includes:
   - Header with your Chamber / Law Firm details.
   - Counsel name, designation, and contact info.
   - Itemized table of expenses with Case titles, Courts, Dates, and Categories.
   - Total settlement figure.
   - Signature / Approval lines.
   - High-resolution attached receipts printed directly on subsequent pages.
5. The Android system share sheet will open—send it directly via **WhatsApp**, **Gmail**, or save to **Google Drive / Downloads**.

---

### 8. Customizing Categories
Add or toggle categories according to your practice area:
1. Go to **Settings** > **Expense Categories**.
2. Toggle the switch off for categories you don't use (e.g., Fuel if you use public transport).
3. To add a new category:
   - Tap **+ New Category**.
   - Enter category name (e.g., *Arbitrator Sitting Fee*, *Courier & Speed Post*).
   - Choose a distinct icon from the picker.
   - Tap **Add**.

---

### 9. Android Home Screen Widget
Add the Lexspense widget to your phone's home screen for fast logging outside courtrooms:
1. Long-press on any empty space on your phone's home screen.
2. Select **Widgets**.
3. Scroll to **Lexspense**.
4. Drag the widget onto your home screen.
5. The widget displays your **Total Pending Amount** and has a **+** shortcut to log an expense in one tap.

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
---

## 🧪 Running Unit Tests

Run the included unit tests for currency precision and SQLite models:
```bash
flutter test
```
