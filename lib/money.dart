// ===========================================================================
//  Money arithmetic and the sentences built from it.
//
//  Everything here is a pure function of its arguments — no database, no
//  widgets, no plugins. That is deliberate: it is the part of the app most
//  worth getting exactly right, and the part that can be checked by reading.
// ===========================================================================

import 'models.dart';

const rupee = '₹'; // ₹

/// Indian digit grouping: the last three digits, then twos.
/// 4500000 becomes 45,00,000 rather than 4,500,000.
String groupIndian(int n) {
  final s = n.abs().toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '${parts.join(',')},$last3';
}

/// ₹26,760. Always unsigned — a minus sign in front of a rupee symbol reads
/// like a mistake, so callers place the sign themselves where they want it.
String money(int n) => '$rupee${groupIndian(n)}';

/// ₹1.2L / ₹45k for axis labels and other tight spaces.
String moneyShort(int n) {
  final a = n.abs();
  if (a >= 10000000) return '$rupee${(a / 10000000).toStringAsFixed(a % 10000000 == 0 ? 0 : 1)}Cr';
  if (a >= 100000) return '$rupee${(a / 100000).toStringAsFixed(a % 100000 == 0 ? 0 : 1)}L';
  if (a >= 1000) return '$rupee${(a / 1000).toStringAsFixed(a % 1000 == 0 ? 0 : 1)}k';
  return '$rupee$a';
}

/// 'YYYY-MM', used to stamp which month a bill was last booked in.
String monthKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

String monthName(DateTime d) => _months[d.month - 1];

int daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;

/// A short human stamp for a row: 'Today, 1:40 pm', 'Yesterday', '3 Sep'.
String whenLabel(DateTime at, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final that = DateTime(at.year, at.month, at.day);
  final diff = today.difference(that).inDays;
  final h = at.hour == 0 ? 12 : (at.hour > 12 ? at.hour - 12 : at.hour);
  final ampm = at.hour < 12 ? 'am' : 'pm';
  final time = '$h:${at.minute.toString().padLeft(2, '0')} $ampm';
  if (diff == 0) return 'Today, $time';
  if (diff == 1) return 'Yesterday, $time';
  if (diff < 7 && diff > 0) return '$diff days ago';
  return '${at.day} ${_months[at.month - 1].substring(0, 3)}';
}

// ---------------------------------------------------------------------------
//  Splitting a bill without losing a rupee
// ---------------------------------------------------------------------------

/// Divides [total] across [weights] in whole rupees.
///
/// Floor each share, then hand the remainder out one rupee at a time starting
/// from the first person — who is always you. The shares therefore always add
/// up to exactly [total], and when it does not divide evenly you absorb the
/// odd rupee rather than quietly under-charging the group.
List<int> shareOut(int total, List<int> weights) {
  if (weights.isEmpty) return const [];
  final totalWeight = weights.fold<int>(0, (a, b) => a + b);
  if (totalWeight <= 0) return List<int>.filled(weights.length, 0);

  final out = weights.map((w) => (total * w) ~/ totalWeight).toList();
  var remainder = total - out.fold<int>(0, (a, b) => a + b);
  var i = 0;
  while (remainder > 0) {
    out[i % out.length] += 1;
    remainder -= 1;
    i += 1;
  }
  return out;
}

// ---------------------------------------------------------------------------
//  The month, as a set of numbers the home screen can speak from
// ---------------------------------------------------------------------------

class MonthPulse {
  final int budget;
  final int spent;
  final int today;
  final int held; // bills still to fall due before the month ends
  final int daysGone;
  final int daysLeft;

  const MonthPulse({
    required this.budget,
    required this.spent,
    required this.today,
    required this.held,
    required this.daysGone,
    required this.daysLeft,
  });

  int get left => budget - spent;

  /// What is genuinely yours to spend: what is left, less the money already
  /// promised to bills that have not gone out yet.
  int get safe => left - held;

  /// How full the vessel is. Allowed past 1.0 so the painter can show an
  /// overflow rather than silently clamping and pretending you are fine.
  double get fill => budget <= 0 ? 0 : spent / budget;

  /// Average daily spend so far this month.
  int get pace => daysGone <= 0 ? spent : (spent / daysGone).round();

  /// What you can afford per day for the rest of the month.
  int get allowance {
    if (daysLeft <= 0) return safe;
    return (safe / daysLeft).round();
  }

  bool get overspending => allowance <= 0 || pace > allowance;

  /// The one sentence on the home screen that tells you whether to change
  /// anything today. A budget figure nobody can act on is decoration.
  String get sentence {
    if (left < 0) {
      return 'You are ${money(-left)} past the budget with $daysLeft '
          '${daysLeft == 1 ? 'day' : 'days'} still to run, so everything from '
          'here is next month’s money.';
    }
    if (allowance <= 0) {
      return 'Everything left is already promised to bills, so anything more '
          'today comes out of next month.';
    }
    final gap = (pace - allowance).abs();
    final tail = 'a day for the $daysLeft ${daysLeft == 1 ? 'day' : 'days'} '
        'left, against your average so far. ';
    if (pace > allowance) {
      return '$tail'
          'Trim about ${money(gap)} a day and you land exactly on budget.';
    }
    return '$tail'
        'You have about ${money(gap)} a day of room over your own habit.';
  }
}

/// Builds the month's numbers from the raw rows. Kept separate from the
/// database so it can be reasoned about — and corrected — on its own.
MonthPulse pulseFor({
  required List<Expense> monthExpenses,
  required List<Bill> bills,
  required int budget,
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  final startOfToday = DateTime(n.year, n.month, n.day);

  var spent = 0;
  var today = 0;
  for (final e in monthExpenses) {
    spent += e.amount;
    if (!e.at.isBefore(startOfToday)) today += e.amount;
  }

  // Money promised to bills that fall later this month and have not been
  // booked yet. A bill already paid is in `spent`, so counting it here too
  // would fence off the same rupees twice.
  final key = monthKey(n);
  var held = 0;
  for (final b in bills) {
    if (!b.active) continue;
    if (b.lastPaid == key) continue;
    if (b.day >= n.day) held += b.amount;
  }

  final total = daysInMonth(n);
  return MonthPulse(
    budget: budget,
    spent: spent,
    today: today,
    held: held,
    daysGone: n.day,
    daysLeft: total - n.day,
  );
}

/// Totals per category for the month, largest first. Categories with nothing
/// in them are dropped rather than drawn as zero-height bars.
List<MapEntry<String, int>> byCategory(List<Expense> rows) {
  final sums = <String, int>{};
  for (final e in rows) {
    sums[e.category] = (sums[e.category] ?? 0) + e.amount;
  }
  final out = sums.entries.where((e) => e.value > 0).toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return out;
}

/// Daily totals across the month, index 0 being the 1st. Used by the trend
/// chart, which needs the empty days present so the shape is honest.
List<int> byDay(List<Expense> rows, DateTime month) {
  final out = List<int>.filled(daysInMonth(month), 0);
  for (final e in rows) {
    final i = e.at.day - 1;
    if (i >= 0 && i < out.length) out[i] += e.amount;
  }
  return out;
}
