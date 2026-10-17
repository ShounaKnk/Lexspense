# SECURITY AUDIT REPORT — Lexspense (LexLedger)

> **Branch:** `security-audit`
> **Auditor role:** Authorized security engineer — self-audit of own open-source project.
> **Audit date:** 2026-10-18
> **App version:** 1.0.0+1 (single git commit: `998b38a`)
> **Scope:** Android build only; Flutter/Dart source + Android manifests/Kotlin; authorized local testing only.

---

## Table of Contents

1. [Phase 1 – Recon & Threat Model](#phase-1--recon--threat-model)
2. [Phase 2 – Static Analysis (SAST)](#phase-2--static-analysis-sast)
3. [Phase 3 – Build & Binary Analysis](#phase-3--build--binary-analysis)
4. [Phase 4 – Dynamic Testing](#phase-4--dynamic-testing)
5. [Phase 5 – Input Fuzzing & Abuse Cases](#phase-5--input-fuzzing--abuse-cases)
6. [Phase 6 – Business-Logic Tests](#phase-6--business-logic-tests)
7. [Findings Table](#findings-table)
8. [Verified-OK Controls](#verified-ok-controls)
9. [Prioritized Remediation Checklist](#prioritized-remediation-checklist)

---

## Phase 1 – Recon & Threat Model

### 1.1 Repository Map (VERIFIED against real code)

| Area | Files / Notes |
|---|---|
| **Dart entry point** | `lib/main.dart` — calls `WidgetsFlutterBinding.ensureInitialized()`, pre-warms DB, runs `ProviderScope(child: LexspenseApp())` |
| **App shell** | `lib/app.dart` — ConsumerStatefulWidget; handles widget cold-start URI and ongoing widget clicks via `HomeWidget.widgetClicked` stream |
| **Database** | `lib/core/database/database_helper.dart` — Singleton, sqflite, `PRAGMA foreign_keys = ON` in `onConfigure`, DB at `<databases>/lexledger.db`, version 2 |
| **Schema** | `lib/core/database/schema.dart` — 6 tables: court_forums, client_matters, expense_categories, reimbursements, expenses, receipt_images. FK constraints present. No PRAGMA inside DDL (correct). |
| **Repositories** | expense_repository.dart, reimbursement_repository.dart, matter_repository.dart, court_forum_repository.dart, category_repository.dart, receipt_repository.dart |
| **Services** | pdf_service.dart (pdf + printing packages), receipt_storage_service.dart (file copy to `<appDocs>/receipts/`), widget_sync_service.dart (HomeWidget data push) |
| **Providers** | Riverpod providers in `lib/providers/`; settings_provider.dart reads/writes shared_preferences for `lawyer_name` and `firm_name` |
| **UI** | `lib/ui/screens/{dashboard,history,add_expense,settings,matters,forums}/` |
| **Android manifest** | `android/app/src/main/AndroidManifest.xml` — 57 lines |
| **Kotlin** | `MainActivity.kt` (empty FlutterActivity), `LexLedgerWidgetProvider.kt` (HomeWidgetProvider subclass) |
| **Widget info** | `res/xml/lexledger_widget_info.xml` — 30-minute auto-update period |
| **Build** | `android/app/build.gradle.kts` — compileSdk/targetSdk from flutter vars; release signing config uses **debug keys** (TODO comment present) |
| **Dependencies** | `pubspec.yaml` — flutter_riverpod, sqflite, path_provider, path, image_picker, pdf, printing, home_widget, intl, shared_preferences |
| **Assets** | `assets/fonts/` (custom fonts only — no bundled DB or sensitive data) |
| **Tests** | `test/` directory exists (to be examined in Phase 2) |
| **CI** | No CI config found (no `.github/`, `.gitlab-ci.yml`, `Makefile`) |

### 1.2 Entry Points

| # | Entry Point | Type | Details |
|---|---|---|---|
| EP-1 | `android.intent.action.MAIN / LAUNCHER` | Activity | MainActivity, `exported="true"`, `launchMode="singleTop"` |
| EP-2 | `lexledger://add` deep link | Intent filter on MainActivity | `scheme=lexledger`, `host=add`; received by `_handleWidgetLaunch()` and `_listenToWidgetClicks()` in app.dart; validated by `uri.host == 'add'` check before acting |
| EP-3 | `android.appwidget.action.APPWIDGET_UPDATE` | BroadcastReceiver | `LexLedgerWidgetProvider`, `exported="true"`. Reads SharedPreferences data written by home_widget package |
| EP-4 | `image_picker` (camera / gallery) | Runtime permission request | CAMERA + READ_MEDIA_IMAGES / READ_EXTERNAL_STORAGE (<=API 32) |
| EP-5 | `Printing.sharePdf()` | Implicit Intent (share sheet) | Sends PDF bytes to system share dialog; no file written to external storage by app code |
| EP-6 | `HomeWidget.saveWidgetData` / `updateWidget` | IPC to widget | Writes two values: `pending_amount` (formatted String) and `pending_count` (int) |

**No backup/restore import feature found** (no zip-slip surface, no import dialog). No deep links beyond `lexledger://add`. No FileProvider declared (consistent with no direct file-sharing URI).

### 1.3 Threat Model

#### Assets

| Asset | Sensitivity | Where stored |
|---|---|---|
| Expense amounts (in paise) | Medium — financial data | SQLite DB in app-private storage |
| Matter/case titles | High — legal professional privilege | SQLite DB |
| Court forum names | Low | SQLite DB |
| Lawyer name & firm | Medium — PII | shared_preferences XML |
| Receipt photos | High — may contain invoices, client data | `<appDocs>/receipts/` (app-private) |
| Generated PDFs | High — contains all of the above | NOT written to disk; passed as bytes to system share sheet |
| Widget display data | Low — rupee total + count only, no matter names | home_widget SharedPreferences (app-private) |

#### Attackers & Scenarios

| Attacker | Capability | Realistic threat to Lexspense |
|---|---|---|
| **Malicious app on same device** | Can send intents to exported components; cannot read app-private files on non-rooted devices | Can send `lexledger://add` intent to open Add Expense screen (no auth; minor). Can send `APPWIDGET_UPDATE` broadcast (only redraws widget from stored prefs). **Cannot read DB or receipts** without root. |
| **Physical access (unlocked device)** | Full UI access | All data visible in the app. No app-level PIN/biometric lock. Acceptable for single-user offline app. |
| **Physical access (ADB-enabled device, debug build)** | `run-as` to read private data | DB and receipts readable. Standard for debug builds; mitigated by not distributing debug builds. |
| **Malicious backup/import file** | N/A — no import feature | Not applicable. |
| **Lost/stolen device (encrypted)** | Android FBE | SQLite DB and receipts encrypted at rest by OS if device encryption enabled (Android default since API 23). Acceptable. |
| **Lost/stolen device (rooted)** | Full filesystem access | DB is plaintext SQLite. All data recoverable. SQLCipher would add a layer but requires key management story — low priority for single-user offline app. |
| **Shoulder-surfing** | Visual observation | Widget shows rupee total + count only — no matter names. Acceptable. |
| **Malformed deep link** | Craft `lexledger://evil` URIs | App checks `uri.host == 'add'`; other hosts silently ignored. Low risk. |

#### Summary Risk Assessment

The attack surface is intentionally very small — no network, no cloud sync, no login, no backup/import. Primary residual risks from recon:

1. `allowBackup` not explicitly `false` — could allow `adb backup` on older devices.
2. Release signing config uses debug keystore — unsuitable for distribution.
3. No `FLAG_SECURE` — screenshots/recents capture sensitive UI.
4. `developer.log()` in production widget sync error path.
5. Receipt filename uses non-cryptographic `hashCode` — collision risk.
6. `key.properties` not in `.gitignore` — risk if production signing is added later.

---

## Phase 2 – Static Analysis (SAST)

### 2.1 flutter analyze

> TODO: Run and record output (requires Flutter SDK).

### 2.2 dart pub outdated

> TODO: Run and record output.

### 2.3 Dependency Vulnerability Scan (osv-scanner)

> TODO: Run osv-scanner on `pubspec.lock`.

### 2.4 Secrets Scan

**Working tree (manual grep):** No API keys, hardcoded passwords, keystore credentials, or `google-services.json` found.

**Git history:** Only one commit (`998b38a`). No secret files added in history.

> TODO: Run `gitleaks` for automated confirmation.

### 2.5 SQL Review

All rawQuery/rawUpdate calls reviewed:

| Location | SQL | Injection Risk |
|---|---|---|
| `expense_repository.dart:84` | `IN ($marks)` where `marks = List.filled(n, '?').join(',')` | SAFE — placeholders only |
| `reimbursement_repository.dart:36,55` | Same `IN ($marks)` pattern | SAFE |
| All other rawQuery calls | Static SQL strings with `?` args | SAFE |

No user-controlled string interpolation found in any SQL. All WHERE clauses use `whereArgs` or `?` placeholders.

### 2.6 AndroidManifest Audit

| Check | Value | Assessment |
|---|---|---|
| `android:debuggable` | Not set | OK — defaults to `false` in release. Must verify in built APK. |
| `android:allowBackup` | **Not set** | WARNING — defaults to `true` on API < 31 (see SEC-04) |
| `android:usesCleartextTraffic` | Not set | OK — defaults to `false` on API >= 28; app has no INTERNET permission anyway |
| `networkSecurityConfig` | Not set | OK — no network usage |
| `taskAffinity` | Not set | OK — defaults to package name; no task hijacking risk |
| `android:exported` on MainActivity | `true` | Required (MAIN/LAUNCHER). Acceptable. |
| `android:exported` on LexLedgerWidgetProvider | `true` | Required for AppWidget receivers. Acceptable. |
| Intent filter — deep link | `lexledger://add`, BROWSABLE | See SEC-02 |
| `FileProvider` | Not declared | OK — no file:// URI sharing |
| Permissions | CAMERA, READ_MEDIA_IMAGES, READ_EXTERNAL_STORAGE (<=32) | Appropriate. No INTERNET, no WRITE_EXTERNAL_STORAGE. |

### 2.7 Logging Review

| Location | Log call | Content risk |
|---|---|---|
| `widget_sync_service.dart:27` | `developer.log('WidgetSyncService error: $e', ...)` | `$e` could contain partial data in exception message. Low severity. |

No `print()` or `debugPrint()` calls found anywhere. No `Log.*` calls in Kotlin.

### 2.8 File Handling Review

| Area | Finding |
|---|---|
| Receipt save path | `<appDocs>/receipts/rcpt_<timestamp>_<hashCode>.<ext>` — app-private directory |
| Receipt filename | Uses `sourceImage.hashCode` (non-cryptographic). See SEC-03. |
| Path construction | Uses `path` package `p.join()` consistently — no manual string concatenation |
| PDF generation | PDF bytes passed directly to `Printing.sharePdf()` — no temp file written by app code |
| No archive import | No zip handling exists — no zip-slip surface |
| `image_picker` temp files | Plugin may leave temp copies in system cache. Phase 4 will verify. |

### 2.9 Backup/Restore

No backup/restore feature exists. `allowBackup` attribute absent (see SEC-04).

### 2.10 Deep Link & Widget Handling

- `uri.host == 'add'` guard in `app.dart:30,45` is correct.
- Only action: push `AddExpenseScreen(fromWidget: true)` — benign navigation, no destructive capability.
- `LexLedgerWidgetProvider.kt` only reads from its own SharedPreferences; accepts no user input.

### 2.11 Release Config

| Check | Finding |
|---|---|
| Minify/shrink | Not configured — no `minifyEnabled`/`shrinkResources` |
| Obfuscation | No `--obfuscate --split-debug-info` flags referenced |
| Signing | Release build uses debug keystore (see SEC-05) |
| `key.properties` | File does not exist; not explicitly in `.gitignore` (see SEC-01) |

---

## Phase 3 – Build & Binary Analysis

> Pending — requires Flutter SDK on PATH and local emulator.

---

## Phase 4 – Dynamic Testing

> Pending — requires Android emulator or device.

---

## Phase 5 – Input Fuzzing & Abuse Cases

> Pending.

---

## Phase 6 – Business-Logic Tests

> Pending.

---

## Findings Table

| ID | Title | Severity | MASVS | Status | File : Line |
|---|---|---|---|---|---|
| SEC-01 | `key.properties` not in `.gitignore` | Medium | MASVS-CODE-2 | SUSPECTED | `.gitignore` |
| SEC-02 | Deep link `lexledger://add` has unnecessary `BROWSABLE` category | Low | MASVS-PLATFORM-3 | CONFIRMED | `AndroidManifest.xml:30` |
| SEC-03 | Receipt filename uses non-cryptographic `hashCode` — silent overwrite risk | Low | MASVS-STORAGE-2 | CONFIRMED | `receipt_storage_service.dart:26` |
| SEC-04 | `android:allowBackup` not explicitly set to `false` | Medium | MASVS-STORAGE-8 | CONFIRMED | `AndroidManifest.xml:8` |
| SEC-05 | Release build signed with debug keystore | High | MASVS-CODE-2 | CONFIRMED | `build.gradle.kts:35` |
| SEC-06 | No `FLAG_SECURE` — screenshots / recents capture sensitive UI | Low | MASVS-STORAGE-10 | SUSPECTED | `main.dart` / `app.dart` |
| SEC-07 | No code shrinking / obfuscation in release build | Low | MASVS-RESILIENCE-4 | CONFIRMED | `build.gradle.kts` |
| SEC-08 | `developer.log()` in production widget sync error path | Info | MASVS-CODE-4 | CONFIRMED | `widget_sync_service.dart:27` |

---

## Finding Details

---

### SEC-01 — `key.properties` Not in `.gitignore` (Medium | MASVS-CODE-2 | SUSPECTED)

**Description:**
The Flutter Android signing convention stores keystore credentials in `android/key.properties`. This file is not present in the repo's `.gitignore`. While the file doesn't currently exist (the project uses the debug keystore), adding production signing later could accidentally commit credentials.

**Impact:**
If `key.properties` containing a production keystore password is committed to a public repo, an attacker could sign malicious APKs with the same certificate.

**Status:** SUSPECTED — file doesn't exist yet; risk manifests only when production signing is set up.

**Recommended Fix:**
```
# Add to android/.gitignore (or root .gitignore)
key.properties
*.keystore
*.jks
```

---

### SEC-02 — Deep Link Has Unnecessary `BROWSABLE` Category (Low | MASVS-PLATFORM-3 | CONFIRMED)

**Description:**
`AndroidManifest.xml:30-37` registers `lexledger://add` with the `BROWSABLE` category. This means any app or browser can resolve this URI, and another app could register the same scheme and intercept it.

**Impact:**
For this app, the link only opens the Add Expense screen with no sensitive data in the URI. Risk is **Low** in context, but scheme hijacking is a recognized Android vulnerability pattern.

**Recommended Fix:**
Remove the `BROWSABLE` category — the widget PendingIntent works without it:
```diff
 <intent-filter>
     <action android:name="android.intent.action.VIEW" />
     <category android:name="android.intent.category.DEFAULT" />
-    <category android:name="android.intent.category.BROWSABLE" />
     <data android:scheme="lexledger" android:host="add" />
 </intent-filter>
```

---

### SEC-03 — Receipt Filename Uses Non-Cryptographic `hashCode` (Low | MASVS-STORAGE-2 | CONFIRMED)

**Description:**
`receipt_storage_service.dart:26`:
```dart
final fileName = 'rcpt_${DateTime.now().millisecondsSinceEpoch}_${sourceImage.hashCode}$ext';
```
`File.hashCode` is object-identity hash — non-deterministic and can collide at the same millisecond. A collision silently overwrites an existing receipt file.

**Impact:**
Silent data loss (one receipt image overwritten by another). No confidentiality breach — both files are in private storage. Extremely unlikely in normal single-user usage.

**Recommended Fix:**
```dart
import 'dart:math';
final rng = Random.secure();
final rand = rng.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
final fileName = 'rcpt_${DateTime.now().millisecondsSinceEpoch}_$rand$ext';
```

---

### SEC-04 — `android:allowBackup` Not Explicitly Disabled (Medium | MASVS-STORAGE-8 | CONFIRMED)

**Description:**
`AndroidManifest.xml:8`: The `<application>` tag does not set `android:allowBackup`. On **Android <= 11 (API 31)**, this defaults to `true`, allowing `adb backup` to extract the SQLite database and SharedPreferences without root on ADB-enabled devices.

**Impact:**
Attacker with physical access + USB cable on an Android <= 11 device:
```
adb backup -noapk com.lexledger.app
```
Can extract the plaintext SQLite database (all expenses, matter names) and shared_preferences (lawyer name, firm name).

**Recommended Fix:**
```diff
 <application
     android:label="Lexspense"
     android:name="${applicationName}"
+    android:allowBackup="false"
+    android:dataExtractionRules="@xml/data_extraction_rules"
     android:icon="@mipmap/ic_launcher">
```

Create `res/xml/data_extraction_rules.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
    <cloud-backup>
        <exclude domain="root" />
        <exclude domain="database" />
        <exclude domain="sharedpref" />
        <exclude domain="file" />
    </cloud-backup>
    <device-transfer>
        <exclude domain="root" />
        <exclude domain="database" />
        <exclude domain="sharedpref" />
        <exclude domain="file" />
    </device-transfer>
</data-extraction-rules>
```

---

### SEC-05 — Release Build Signed with Debug Keystore (High | MASVS-CODE-2 | CONFIRMED)

**Description:**
`build.gradle.kts:35`:
```kotlin
signingConfig = signingConfigs.getByName("debug")
```
The release build uses the shared Android debug keystore (publicly-known password `android`, located at `~/.android/debug.keystore` on any developer machine).

**Impact:**
Any developer with an Android SDK can sign a modified APK with the same debug certificate. A user who sideloads the app could be tricked into "updating" with a malicious version signed by the same key. (Play Store would reject it, so this is a sideloading risk only.)

**Recommended Fix:**
Generate a production keystore and reference it via `key.properties` (gitignored):
```kotlin
// build.gradle.kts
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}
android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String? ?: System.getenv("KEY_ALIAS")
            keyPassword = keystoreProperties["keyPassword"] as String? ?: System.getenv("KEY_PASSWORD")
            storeFile = file(keystoreProperties["storeFile"] as String? ?: "")
            storePassword = keystoreProperties["storePassword"] as String? ?: System.getenv("STORE_PASSWORD")
        }
    }
    buildTypes {
        release { signingConfig = signingConfigs.getByName("release") }
    }
}
```

---

### SEC-06 — No `FLAG_SECURE` (Low | MASVS-STORAGE-10 | SUSPECTED)

**Description:**
No `FLAG_SECURE` is set on the app window. Android's recents screen captures a live screenshot of the last app state. User screenshots are also unrestricted.

**Impact:**
If backgrounded while displaying the expense list, the recents thumbnail shows matter names, amounts, and dates — visible to anyone who picks up the device. For a legal expense tracker handling professionally privileged client matters, this is a meaningful data-leakage vector.

**Severity is Low** because an attacker needs physical device access.

**Recommended Fix:**
```dart
// main.dart, after WidgetsFlutterBinding.ensureInitialized()
// Add flutter_windowmanager: ^0.2.0 to pubspec.yaml
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'dart:io' show Platform;
if (Platform.isAndroid) {
  await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
}
```

> Trade-off: `FLAG_SECURE` also prevents user screenshots. Since the app has a PDF export, this is acceptable.

---

### SEC-07 — No Code Shrinking or Obfuscation (Low | MASVS-RESILIENCE-4 | CONFIRMED)

**Description:**
`build.gradle.kts` has no `minifyEnabled = true` / `shrinkResources = true`. The Flutter `--obfuscate --split-debug-info` flags are not in the build configuration.

**Impact:**
Release APK contains readable Dart symbol names. For an open-source app with no server-side secrets, practical impact is low. Still a useful defense-in-depth measure.

**Recommended Fix:**
```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info/
```

Add to `build.gradle.kts` release block:
```kotlin
minifyEnabled = true
shrinkResources = true
proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
```

Store `build/debug-info/` symbols securely for crash symbolication.

---

### SEC-08 — `developer.log()` in Production Error Path (Info | MASVS-CODE-4 | CONFIRMED)

**Description:**
`widget_sync_service.dart:27`:
```dart
developer.log('WidgetSyncService error: $e', error: e, stackTrace: st);
```
`dart:developer`'s `log()` emits to `adb logcat`. Exception messages may contain path information or partial SQL.

**Impact:**
Low — requires ADB access. Exception message is not user data per se.

**Recommended Fix:**
```dart
import 'package:flutter/foundation.dart';
if (kDebugMode) {
  developer.log('WidgetSyncService error: $e', error: e, stackTrace: st);
}
```

---

## Verified-OK Controls

| Control | Evidence |
|---|---|
| No INTERNET permission | AndroidManifest.xml — only CAMERA + READ_MEDIA_IMAGES + READ_EXTERNAL_STORAGE (<=32) |
| Parameterized SQL everywhere | All rawQuery/rawUpdate calls use `?` placeholders; IN lists use `List.filled(n, '?')` |
| FK enforcement per-connection | `PRAGMA foreign_keys = ON` in `onConfigure` (correct location — outside transactions) |
| No hardcoded secrets in code or git history | Manual grep + single-commit history confirmed |
| Receipts stored in app-private directory | `getApplicationDocumentsDirectory()` used exclusively |
| No FileProvider declared | No `file://` URI sharing; PDF bytes passed directly to `Printing.sharePdf()` |
| No backup/restore import attack surface | Feature doesn't exist; no zip handling code present |
| Deep link URI validated before action | `uri.host == 'add'` checked before navigating |
| Reimbursement total computed inside transaction | Never passed as parameter; summed from DB atomically |
| Double-reimbursement guard | `WHERE reimbursement_id IS NULL` in UPDATE + row-count verification |
| Currency parsed as integer paise | `CurrencyUtils.parseToPaise` uses regex to integer; no floating-point arithmetic |
| No analytics/tracking SDKs | No Firebase, Mixpanel, Sentry, or similar in pubspec.yaml |
| No network libraries | No `http`, `dio`, WebSocket, or gRPC packages present |

---

## Prioritized Remediation Checklist

### Before any distribution (Critical/High)
- [ ] **SEC-05** — Replace debug signing with production keystore; store credentials outside the repo
- [ ] **SEC-04** — Add `android:allowBackup="false"` and `dataExtractionRules` to manifest
- [ ] **SEC-01** — Add `key.properties`, `*.keystore`, `*.jks` to `.gitignore`

### Recommended for production hardening (Medium/Low)
- [ ] **SEC-02** — Remove `BROWSABLE` category from `lexledger://add` intent filter
- [ ] **SEC-06** — Add `FLAG_SECURE` via `flutter_windowmanager` to prevent recents screenshots
- [ ] **SEC-07** — Enable `--obfuscate` and R8 minification in release build pipeline
- [ ] **SEC-03** — Replace `hashCode` in receipt filename with `Random.secure()` hex string

### Informational (Info)
- [ ] **SEC-08** — Gate `developer.log()` in widget sync service behind `kDebugMode`

### Suggested regression tests (to add to `test/`)
- [ ] Unit test: `CurrencyUtils.parseToPaise` with int64-boundary inputs, Arabic-Indic digits, multiple dots
- [ ] Unit test: `ReimbursementRepository.createReimbursement` — already-reimbursed guard
- [ ] Unit test: `ExpenseRepository.deleteExpense` — FK RESTRICT behavior
- [ ] Integration test: `PRAGMA foreign_keys` confirmed ON per connection at test DB open time

---

*Phases 3-6 findings will be appended as testing progresses on an Android emulator.*
