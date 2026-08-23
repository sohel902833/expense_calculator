# Pending Features

## Budget Notifications

Each `BudgetModel` (`lib/models/budget_model.dart`) persists a `notificationsEnabled` flag, set via a toggle in the create/edit budget sheet (`lib/features/budget/widgets/budget_form_sheet.dart`). The flag is stored but not yet wired to any real notification delivery.

**What real implementation needs:**

- A notifications package (e.g. `flutter_local_notifications`, or Firebase Cloud Messaging if server-side triggers are wanted).
- A trigger point: budget usage only changes when a transaction is added/edited/deleted, so the check should run from `TransactionController` (`lib/features/transactions/controller/transaction_controller.dart`) after a write succeeds — recompute `BudgetProgress` (`lib/features/budget/models/budget_progress.dart`) for any budget whose category matches the transaction (or any Overall budget), for budgets with `notificationsEnabled == true`.
- Threshold checks reusing `BudgetStatus` (`lib/features/budget/models/budget_progress.dart`): fire at 75% (warning), 90% (critical), 100%+ (exceeded) — matching the same thresholds already used for in-app status colors, so the notification copy and the UI never disagree.
- De-duplication so the same threshold doesn't notify repeatedly (e.g. store "last notified status" per budget, or per budget+day).
- Local notification permission request flow (iOS requires explicit opt-in; Android 13+ also requires runtime permission).

Until this lands, budget alerts are surfaced only in-app: colored status badges (Healthy/Warning/Critical/Exceeded) and the "Insights" panel on the Budget Dashboard (`lib/features/budget/models/budget_insights.dart`), both computed at runtime from live transaction data.
