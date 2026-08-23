import 'package:expense_calculator/constants/color.dart';
import 'package:expense_calculator/features/comparison/screens/comparison_result_screen.dart';
import 'package:flutter/material.dart';

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const _accentA = Color(0xFF78909C);
const _accentB = tabColor;

String _formatDate(DateTime d) =>
    "${d.day} ${_monthNames[d.month - 1]} ${d.year}";

class ComparisonScreen extends StatefulWidget {
  static const routeName = '/comparison-screen';
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String? _comparisonType; // "Income" | "Expense"

  DateTime? _dayA;
  DateTime? _dayB;

  int? _monthAYear;
  int? _monthAMonth;
  int? _monthBYear;
  int? _monthBMonth;

  int? _yearA;
  int? _yearB;

  DateTimeRange? _rangeA;
  DateTimeRange? _rangeB;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showTypePicker());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showTypePicker() async {
    final type = await showDialog<String>(
      context: context,
      barrierDismissible: _comparisonType != null,
      builder: (_) => _ComparisonTypeDialog(initial: _comparisonType),
    );
    if (type != null) setState(() => _comparisonType = type);
  }

  void _showIncomplete() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please select both periods to compare"),
      ),
    );
  }

  void _applyComparison() {
    if (_comparisonType == null) {
      _showTypePicker();
      return;
    }

    DateTimeRange rA;
    DateTimeRange rB;
    String labelA;
    String labelB;

    switch (_tabController.index) {
      case 0: // Day
        if (_dayA == null || _dayB == null) {
          _showIncomplete();
          return;
        }
        rA = DateTimeRange(start: _dayA!, end: _dayA!);
        rB = DateTimeRange(start: _dayB!, end: _dayB!);
        labelA = _formatDate(_dayA!);
        labelB = _formatDate(_dayB!);
        break;

      case 1: // Month
        if (_monthAYear == null || _monthBYear == null) {
          _showIncomplete();
          return;
        }
        final lastA = DateTime(_monthAYear!, _monthAMonth! + 1, 0).day;
        final lastB = DateTime(_monthBYear!, _monthBMonth! + 1, 0).day;
        rA = DateTimeRange(
          start: DateTime(_monthAYear!, _monthAMonth!, 1),
          end: DateTime(_monthAYear!, _monthAMonth!, lastA),
        );
        rB = DateTimeRange(
          start: DateTime(_monthBYear!, _monthBMonth!, 1),
          end: DateTime(_monthBYear!, _monthBMonth!, lastB),
        );
        labelA = "${_monthNames[_monthAMonth! - 1]} $_monthAYear";
        labelB = "${_monthNames[_monthBMonth! - 1]} $_monthBYear";
        break;

      case 2: // Year
        if (_yearA == null || _yearB == null) {
          _showIncomplete();
          return;
        }
        rA = DateTimeRange(
          start: DateTime(_yearA!, 1, 1),
          end: DateTime(_yearA!, 12, 31),
        );
        rB = DateTimeRange(
          start: DateTime(_yearB!, 1, 1),
          end: DateTime(_yearB!, 12, 31),
        );
        labelA = "$_yearA";
        labelB = "$_yearB";
        break;

      case 3: // Range
      default:
        if (_rangeA == null || _rangeB == null) {
          _showIncomplete();
          return;
        }
        rA = _rangeA!;
        rB = _rangeB!;
        labelA = "${_formatDate(_rangeA!.start)} - ${_formatDate(_rangeA!.end)}";
        labelB = "${_formatDate(_rangeB!.start)} - ${_formatDate(_rangeB!.end)}";
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComparisonResultScreen(
          comparisonType: _comparisonType!,
          rangeA: rA,
          rangeB: rB,
          labelA: labelA,
          labelB: labelB,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Compare"),
        actions: [
          if (_comparisonType != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: ActionChip(
                  avatar: Icon(
                    _comparisonType == "Income"
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    _comparisonType!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  backgroundColor: _comparisonType == "Income"
                      ? const Color(0xFF2ECC71)
                      : const Color(0xFFE74C3C),
                  onPressed: _showTypePicker,
                ),
              ),
            ),
        ],
      ),
      body: _comparisonType == null
          ? const SizedBox.shrink()
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: tabColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark
                        ? Colors.white70
                        : Colors.black54,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    onTap: (_) => setState(() {}),
                    tabs: const [
                      Tab(text: "Day"),
                      Tab(text: "Month"),
                      Tab(text: "Year"),
                      Tab(text: "Range"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _dayTab(),
                      _monthTab(),
                      _yearTab(),
                      _rangeTab(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _applyComparison,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tabColor,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Compare",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _periodTabBody({required Widget fieldA, required Widget fieldB}) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          fieldA,
          const SizedBox(height: 14),
          const Center(
            child: Icon(
              Icons.compare_arrows_rounded,
              color: Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(height: 14),
          fieldB,
        ],
      ),
    );
  }

  Widget _dayTab() {
    return _periodTabBody(
      fieldA: _PeriodField(
        title: "Period A",
        icon: Icons.event_rounded,
        value: _dayA == null ? "Select date" : _formatDate(_dayA!),
        accent: _accentA,
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: _dayA ?? now,
            firstDate: DateTime(now.year - 10),
            lastDate: now,
          );
          if (picked != null) setState(() => _dayA = picked);
        },
      ),
      fieldB: _PeriodField(
        title: "Period B",
        icon: Icons.event_rounded,
        value: _dayB == null ? "Select date" : _formatDate(_dayB!),
        accent: _accentB,
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: _dayB ?? now,
            firstDate: DateTime(now.year - 10),
            lastDate: now,
          );
          if (picked != null) setState(() => _dayB = picked);
        },
      ),
    );
  }

  Widget _monthTab() {
    return _periodTabBody(
      fieldA: _PeriodField(
        title: "Period A",
        icon: Icons.calendar_month_rounded,
        value: _monthAYear == null
            ? "Select month"
            : "${_monthNames[_monthAMonth! - 1]} $_monthAYear",
        accent: _accentA,
        onTap: () async {
          final now = DateTime.now();
          final result = await _pickMonthYear(
            context,
            initialYear: _monthAYear ?? now.year,
            initialMonth: _monthAMonth ?? now.month,
          );
          if (result != null) {
            setState(() {
              _monthAYear = result.year;
              _monthAMonth = result.month;
            });
          }
        },
      ),
      fieldB: _PeriodField(
        title: "Period B",
        icon: Icons.calendar_month_rounded,
        value: _monthBYear == null
            ? "Select month"
            : "${_monthNames[_monthBMonth! - 1]} $_monthBYear",
        accent: _accentB,
        onTap: () async {
          final now = DateTime.now();
          final result = await _pickMonthYear(
            context,
            initialYear: _monthBYear ?? now.year,
            initialMonth: _monthBMonth ?? now.month,
          );
          if (result != null) {
            setState(() {
              _monthBYear = result.year;
              _monthBMonth = result.month;
            });
          }
        },
      ),
    );
  }

  Widget _yearTab() {
    return _periodTabBody(
      fieldA: _PeriodField(
        title: "Period A",
        icon: Icons.today_rounded,
        value: _yearA == null ? "Select year" : "$_yearA",
        accent: _accentA,
        onTap: () async {
          final picked = await _pickYear(
            context,
            initialYear: _yearA ?? DateTime.now().year,
          );
          if (picked != null) setState(() => _yearA = picked);
        },
      ),
      fieldB: _PeriodField(
        title: "Period B",
        icon: Icons.today_rounded,
        value: _yearB == null ? "Select year" : "$_yearB",
        accent: _accentB,
        onTap: () async {
          final picked = await _pickYear(
            context,
            initialYear: _yearB ?? DateTime.now().year,
          );
          if (picked != null) setState(() => _yearB = picked);
        },
      ),
    );
  }

  Widget _rangeTab() {
    return _periodTabBody(
      fieldA: _PeriodField(
        title: "Period A",
        icon: Icons.date_range_rounded,
        value: _rangeA == null
            ? "Select range"
            : "${_formatDate(_rangeA!.start)} - ${_formatDate(_rangeA!.end)}",
        accent: _accentA,
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDateRangePicker(
            context: context,
            initialDateRange: _rangeA,
            firstDate: DateTime(now.year - 10),
            lastDate: now,
          );
          if (picked != null) setState(() => _rangeA = picked);
        },
      ),
      fieldB: _PeriodField(
        title: "Period B",
        icon: Icons.date_range_rounded,
        value: _rangeB == null
            ? "Select range"
            : "${_formatDate(_rangeB!.start)} - ${_formatDate(_rangeB!.end)}",
        accent: _accentB,
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDateRangePicker(
            context: context,
            initialDateRange: _rangeB,
            firstDate: DateTime(now.year - 10),
            lastDate: now,
          );
          if (picked != null) setState(() => _rangeB = picked);
        },
      ),
    );
  }
}

class _ComparisonTypeDialog extends StatelessWidget {
  final String? initial;
  const _ComparisonTypeDialog({this.initial});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "What do you want to compare?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              "Choose a comparison type",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _TypeOption(
                    label: "Income",
                    icon: Icons.arrow_downward_rounded,
                    color: const Color(0xFF2ECC71),
                    selected: initial == "Income",
                    onTap: () => Navigator.pop(context, "Income"),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _TypeOption(
                    label: "Expense",
                    icon: Icons.arrow_upward_rounded,
                    color: const Color(0xFFE74C3C),
                    selected: initial == "Expense",
                    onTap: () => Navigator.pop(context, "Expense"),
                  ),
                ),
              ],
            ),
            if (initial != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodField extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final Color accent;
  final VoidCallback onTap;

  const _PeriodField({
    required this.title,
    required this.icon,
    required this.value,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

Future<({int year, int month})?> _pickMonthYear(
  BuildContext context, {
  required int initialYear,
  required int initialMonth,
}) {
  int year = initialYear;
  int month = initialMonth;
  final years = List.generate(10, (i) => DateTime.now().year - i);

  return showDialog<({int year, int month})>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Select Month"),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: month,
                decoration: const InputDecoration(labelText: "Month"),
                items: List.generate(
                  12,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(_monthNames[i]),
                  ),
                ),
                onChanged: (val) => setDialogState(() => month = val!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: year,
                decoration: const InputDecoration(labelText: "Year"),
                items: years
                    .map((y) => DropdownMenuItem(value: y, child: Text("$y")))
                    .toList(),
                onChanged: (val) => setDialogState(() => year = val!),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, (year: year, month: month)),
            child: const Text("OK"),
          ),
        ],
      ),
    ),
  );
}

Future<int?> _pickYear(BuildContext context, {required int initialYear}) {
  int year = initialYear;
  final years = List.generate(10, (i) => DateTime.now().year - i);

  return showDialog<int>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Select Year"),
        content: DropdownButtonFormField<int>(
          initialValue: year,
          decoration: const InputDecoration(labelText: "Year"),
          items: years
              .map((y) => DropdownMenuItem(value: y, child: Text("$y")))
              .toList(),
          onChanged: (val) => setDialogState(() => year = val!),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, year),
            child: const Text("OK"),
          ),
        ],
      ),
    ),
  );
}
