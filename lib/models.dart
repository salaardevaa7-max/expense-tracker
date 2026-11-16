// ===========================================================================
//  The shapes of the things Hisaab keeps.
//
//  Money is stored as whole rupees in an int, never a double. Doubles cannot
//  represent 0.1 exactly, so a column of them drifts, and a split that is one
//  paisa short is a bug you find six months later. Paise are rounded away at
//  the point of entry instead — which also matches how people actually talk
//  about their own spending.
// ===========================================================================

/// Where an expense came from. Kept as a string in the database so adding a
/// new source later does not need a migration.
class Source {
  static const manual = 'manual';
  static const sms = 'sms';
  static const recurring = 'recurring';
  static const cash = 'cash';
}

/// The six categories, fixed for v1. The key is what goes in the database;
/// changing a label later must not orphan old rows, so never rename a key.
class Cat {
  static const food = 'Food';
  static const travel = 'Travel';
  static const shopping = 'Shopping';
  static const bills = 'Bills';
  static const rent = 'Rent';
  static const fun = 'Fun';

  static const all = <String>[food, travel, shopping, bills, rent, fun];

  /// Anything unrecognised lands in Food rather than being dropped, because
  /// a miscategorised expense is recoverable and a lost one is not.
  static String safe(String? s) => all.contains(s) ? s! : food;
}

class Expense {
  final int? id;
  final int amount; // whole rupees, always positive
  final String category;
  final String note;
  final DateTime at;
  final String source;
  final String? photo; // absolute path to a receipt image on this device
  final bool fromCash; // paid from the cash wallet rather than a bank account

  const Expense({
    this.id,
    required this.amount,
    required this.category,
    required this.note,
    required this.at,
    this.source = Source.manual,
    this.photo,
    this.fromCash = false,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'amount': amount,
        'category': category,
        'note': note,
        'at': at.millisecondsSinceEpoch,
        'source': source,
        'photo': photo,
        'from_cash': fromCash ? 1 : 0,
      };

  factory Expense.fromMap(Map<String, Object?> m) => Expense(
        id: m['id'] as int?,
        amount: (m['amount'] as int?) ?? 0,
        category: Cat.safe(m['category'] as String?),
        note: (m['note'] as String?) ?? '',
        at: DateTime.fromMillisecondsSinceEpoch((m['at'] as int?) ?? 0),
        source: (m['source'] as String?) ?? Source.manual,
        photo: m['photo'] as String?,
        fromCash: ((m['from_cash'] as int?) ?? 0) == 1,
      );

  Expense copyWith({int? amount, String? category, String? note, String? photo}) =>
      Expense(
        id: id,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        note: note ?? this.note,
        at: at,
        source: source,
        photo: photo ?? this.photo,
        fromCash: fromCash,
      );
}

/// Someone you split with. [balance] is a single signed number: positive means
/// they owe you, negative means you owe them. One number rather than two
/// columns means the two can never disagree.
class Person {
  final int? id;
  final String name;
  final String phone;
  final String vpa; // UPI id, if we know one
  final int balance;

  const Person({
    this.id,
    required this.name,
    this.phone = '',
    this.vpa = '',
    this.balance = 0,
  });

  /// Up to two letters for the avatar. Falls back to '?' so an empty name
  /// cannot throw on an empty-string index.
  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final w = parts.first;
      return (w.length == 1 ? w : w.substring(0, 2)).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'vpa': vpa,
        'balance': balance,
      };

  factory Person.fromMap(Map<String, Object?> m) => Person(
        id: m['id'] as int?,
        name: (m['name'] as String?) ?? '',
        phone: (m['phone'] as String?) ?? '',
        vpa: (m['vpa'] as String?) ?? '',
        balance: (m['balance'] as int?) ?? 0,
      );

  Person copyWith({int? balance, String? vpa}) => Person(
        id: id,
        name: name,
        phone: phone,
        vpa: vpa ?? this.vpa,
        balance: balance ?? this.balance,
      );
}

/// A sinking fund. Money moved in here is fenced off from safe-to-spend, so
/// saving costs you something today rather than only at the end of the month.
class Goal {
  final int? id;
  final String name;
  final int target;
  final int saved;

  const Goal({this.id, required this.name, required this.target, this.saved = 0});

  double get progress => target <= 0 ? 0 : (saved / target).clamp(0.0, 1.0);

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'target': target,
        'saved': saved,
      };

  factory Goal.fromMap(Map<String, Object?> m) => Goal(
        id: m['id'] as int?,
        name: (m['name'] as String?) ?? '',
        target: (m['target'] as int?) ?? 0,
        saved: (m['saved'] as int?) ?? 0,
      );
}

/// A recurring bill or subscription. [day] is the day of the month it falls
/// due; [lastPaid] is a 'YYYY-MM' stamp so a bill can only be booked once
/// per month however many times the app is opened.
class Bill {
  final int? id;
  final String name;
  final int amount;
  final int day;
  final String category;
  final bool active;
  final String lastPaid;

  const Bill({
    this.id,
    required this.name,
    required this.amount,
    required this.day,
    this.category = Cat.bills,
    this.active = true,
    this.lastPaid = '',
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'amount': amount,
        'day': day,
        'category': category,
        'active': active ? 1 : 0,
        'last_paid': lastPaid,
      };

  factory Bill.fromMap(Map<String, Object?> m) => Bill(
        id: m['id'] as int?,
        name: (m['name'] as String?) ?? '',
        amount: (m['amount'] as int?) ?? 0,
        day: (m['day'] as int?) ?? 1,
        category: Cat.safe(m['category'] as String?),
        active: ((m['active'] as int?) ?? 1) == 1,
        lastPaid: (m['last_paid'] as String?) ?? '',
      );

  Bill copyWith({bool? active, String? lastPaid, int? amount}) => Bill(
        id: id,
        name: name,
        amount: amount ?? this.amount,
        day: day,
        category: category,
        active: active ?? this.active,
        lastPaid: lastPaid ?? this.lastPaid,
      );
}

/// A non-essential purchase on hold. Helps curb emotional spending.
class ImpulseBuy {
  final int? id;
  final String name;
  final int amount;
  final String category;
  final DateTime at;
  final bool resolved; // true if decided (to buy or not to buy)

  const ImpulseBuy({
    this.id,
    required this.name,
    required this.amount,
    this.category = Cat.shopping,
    required this.at,
    this.resolved = false,
  });

  bool get isCool => DateTime.now().difference(at).inHours >= 24;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'amount': amount,
        'category': category,
        'at': at.millisecondsSinceEpoch,
        'resolved': resolved ? 1 : 0,
      };

  factory ImpulseBuy.fromMap(Map<String, Object?> m) => ImpulseBuy(
        id: m['id'] as int?,
        name: (m['name'] as String?) ?? '',
        amount: (m['amount'] as int?) ?? 0,
        category: Cat.safe(m['category'] as String?),
        at: DateTime.fromMillisecondsSinceEpoch((m['at'] as int?) ?? 0),
        resolved: ((m['resolved'] as int?) ?? 0) == 1,
      );
}

/// Custom categorization rule for SMS/Manual entry.
class Rule {
  final int? id;
  final String pattern; // keyword to look for
  final String category;

  const Rule({this.id, required this.pattern, required this.category});

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'pattern': pattern,
        'category': category,
      };

  factory Rule.fromMap(Map<String, Object?> m) => Rule(
        id: m['id'] as int?,
        pattern: (m['pattern'] as String?) ?? '',
        category: Cat.safe(m['category'] as String?),
      );
}

/// A debit spotted in the SMS inbox that has not been confirmed yet. Nothing
/// is written to the ledger from a text message without the person saying so —
/// bank SMS formats vary too much to be trusted silently.
class Inbox {
  final int? id;
  final int amount;
  final String merchant;
  final String guessCategory;
  final String body;
  final DateTime at;

  const Inbox({
    this.id,
    required this.amount,
    required this.merchant,
    required this.guessCategory,
    required this.body,
    required this.at,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'amount': amount,
        'merchant': merchant,
        'guess': guessCategory,
        'body': body,
        'at': at.millisecondsSinceEpoch,
      };

  factory Inbox.fromMap(Map<String, Object?> m) => Inbox(
        id: m['id'] as int?,
        amount: (m['amount'] as int?) ?? 0,
        merchant: (m['merchant'] as String?) ?? '',
        guessCategory: Cat.safe(m['guess'] as String?),
        body: (m['body'] as String?) ?? '',
        at: DateTime.fromMillisecondsSinceEpoch((m['at'] as int?) ?? 0),
      );
}
