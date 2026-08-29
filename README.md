# Expense Calculator

A full-featured personal finance management app built with Flutter — track
income and expenses, manage budgets, automate recurring transactions, and
work entirely offline with optional one-tap sync to the cloud.

## Features

- **Income & Expense Tracking** — log transactions against custom,
  user-specific categories
- **Budgets** — set monthly/weekly/custom budgets per category or overall,
  with progress tracking
- **Spending Comparison** — compare income/expense across different periods
- **Recurring Transactions** — define rules (salary, rent, bills, etc.); the
  app surfaces due/upcoming occurrences for review instead of silently
  creating them, with bulk-apply, skip, and "run now" actions
- **Offline Mode** — register and use every feature without an account or
  internet connection, backed by a local (Drift/SQLite) database; sync
  everything to the cloud later in one step, whenever you're ready
- **Security** — session auto-lock with password or fingerprint
  (biometric) authentication
- **Dark Mode** — clean, modern UI with full light/dark theme support

## Tech Stack

- **Flutter** — cross-platform UI
- **Riverpod** — state management
- **Firebase** — Authentication, Cloud Firestore, Storage
- **Drift (SQLite)** — local, offline-first database
- **local_auth** — biometric authentication

## Screenshots

### Authentication

<table>
<tr>
<td align="center"><img src="public/01_LoginScreen.jpeg" width="250"/><br/>Login</td>
<td align="center"><img src="public/02_Signup_Screen.jpeg" width="250"/><br/>Signup</td>
</tr>
</table>

### Dashboard

<table>
<tr>
<td align="center"><img src="public/03_Dashboard_01.jpeg" width="250"/><br/>Dashboard</td>
<td align="center"><img src="public/04_Dashboard_02.jpeg" width="250"/><br/>Dashboard</td>
</tr>
</table>

### Transactions

<table>
<tr>
<td align="center"><img src="public/05_TransectionTypeSetupScreen.jpeg" width="250"/><br/>Category Setup</td>
<td align="center"><img src="public/06_TransectionScreen.jpeg" width="250"/><br/>Transactions</td>
<td align="center"><img src="public/07_TransectionFilterOptions.jpeg" width="250"/><br/>Filter Options</td>
</tr>
</table>

### Budgets

<table>
<tr>
<td align="center"><img src="public/08_Budget_Dashboard.jpeg" width="250"/><br/>Budget Dashboard</td>
<td align="center"><img src="public/090_Single_Budget_Details_View_Screen.jpeg" width="250"/><br/>Budget Details</td>
<td align="center"><img src="public/10_Budget_List_Screen.jpeg" width="250"/><br/>Budget List</td>
</tr>
<tr>
<td align="center"><img src="public/11_AddNewBudgetPage.jpeg" width="250"/><br/>Add New Budget</td>
</tr>
</table>

### Recurring Transactions

<table>
<tr>
<td align="center"><img src="public/12_RecurringTransectionOverviewPage_Today_Tab.jpeg" width="250"/><br/>Today Tab</td>
<td align="center"><img src="public/13_RecurringTransection_Upcoming_Tab.jpeg" width="250"/><br/>Upcoming Tab</td>
<td align="center"><img src="public/14_AddNewRecurringTransectionRule.jpeg" width="250"/><br/>New Rule</td>
</tr>
</table>

### Settings

<table>
<tr>
<td align="center"><img src="public/Settings_Screen.jpeg" width="250"/><br/>Settings</td>
</tr>
</table>

## Getting Started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

For a signed production release build (APK + App Bundle):

```bash
scripts/build_release.sh
```
