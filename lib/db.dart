// ===========================================================================
//  The local database. Everything lives on this phone and nowhere else —
//  no account, no server, no sync. That was a deliberate choice: an expense
//  tracker that needs a login is one people stop opening.
//
//  Plain SQL rather than a generated ORM, so there is no build step between
//  this file and a working app.
// ===========================================================================

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class Db {
  Db._();
  static final Db i = Db._();

  Database? _db;

  Future<Database> get _handle async {
    final existing = _db;
    if (existing != null) return existing;
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      p.join(dir, 'hisaab.db'),
      version: 1,
      onConfigure: (d) async {
        // Without this, ON DELETE CASCADE is silently ignored by SQLite.
        await d.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _create,
    );
    _db = db;
    return db;
  }

  Future<void> close() async {
    final d = _db;
    if (d != null) {
      await d.close();
      _db = null;
    }
  }

  Future<void> _create(Database d, int version) async {
    await d.execute('''
      CREATE TABLE expenses(
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        amount    INTEGER NOT NULL,
        category  TEXT    NOT NULL,
        note      TEXT    NOT NULL DEFAULT '',
        at        INTEGER NOT NULL,
        source    TEXT    NOT NULL DEFAULT 'manual',
        photo     TEXT,
        from_cash INTEGER NOT NULL DEFAULT 0
      )''');
    // Every list and every chart is "this month, newest first", so this is
    // the one index that matters.
    await d.execute('CREATE INDEX idx_expenses_at ON expenses(at DESC)');

    await d.execute('''
      CREATE TABLE people(
        id      INTEGER PRIMARY KEY AUTOINCREMENT,
        name    TEXT    NOT NULL,
        phone   TEXT    NOT NULL DEFAULT '',
        vpa     TEXT    NOT NULL DEFAULT '',
        balance INTEGER NOT NULL DEFAULT 0
      )''');

    await d.execute('''
      CREATE TABLE splits(
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        expense_id INTEGER NOT NULL REFERENCES expenses(id) ON DELETE CASCADE,
        person_id  INTEGER NOT NULL REFERENCES people(id)   ON DELETE CASCADE,
        share      INTEGER NOT NULL
      )''');

    await d.execute('''
      CREATE TABLE goals(
        id     INTEGER PRIMARY KEY AUTOINCREMENT,
        name   TEXT    NOT NULL,
        target INTEGER NOT NULL,
        saved  INTEGER NOT NULL DEFAULT 0
      )''');

    await d.execute('''
      CREATE TABLE bills(
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        name      TEXT    NOT NULL,
        amount    INTEGER NOT NULL,
        day       INTEGER NOT NULL,
        category  TEXT    NOT NULL DEFAULT 'Bills',
        active    INTEGER NOT NULL DEFAULT 1,
        last_paid TEXT    NOT NULL DEFAULT ''
      )''');

    await d.execute('''
      CREATE TABLE settings(
        k TEXT PRIMARY KEY,
        v TEXT NOT NULL
      )''');

    await d.execute('''
      CREATE TABLE inbox(
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        amount   INTEGER NOT NULL,
        merchant TEXT    NOT NULL DEFAULT '',
        guess    TEXT    NOT NULL DEFAULT 'Food',
        body     TEXT    NOT NULL DEFAULT '',
        at       INTEGER NOT NULL
      )''');

    // Fingerprints of messages already looked at, so re-scanning the inbox
    // does not offer the same debit twice.
    await d.execute('''
      CREATE TABLE sms_seen(
        fingerprint TEXT PRIMARY KEY,
        at          INTEGER NOT NULL
      )''');

    await d.execute('''
      CREATE TABLE impulse(
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        name     TEXT    NOT NULL,
        amount   INTEGER NOT NULL,
        category TEXT    NOT NULL DEFAULT 'Shopping',
        at       INTEGER NOT NULL,
        resolved INTEGER NOT NULL DEFAULT 0
      )''');

    await _seed(d);
  }

  /// A brand new install with an empty home screen tells you nothing about
  /// whether the app works. These are the same figures the prototype used,
  /// so the first launch looks like the screen that was signed off — and
  /// every one of them can be wiped from More › Start again.
  Future<void> _seed(Database d) async {
    final now = DateTime.now();
    DateTime ago(int days, int hour) =>
        DateTime(now.year, now.month, now.day, hour).subtract(Duration(days: days));

    final rows = <Expense>[
      Expense(amount: 240, category: Cat.food, note: 'Lunch, office canteen', at: ago(0, 13)),
      Expense(amount: 90, category: Cat.travel, note: 'Auto to work', at: ago(0, 9)),
      Expense(amount: 480, category: Cat.food, note: 'Groceries', at: ago(0, 19)),
      Expense(amount: 199, category: Cat.fun, note: 'Netflix', at: ago(1, 8), source: Source.recurring),
      Expense(amount: 1250, category: Cat.shopping, note: 'Shoes', at: ago(2, 17)),
      Expense(amount: 60, category: Cat.food, note: 'Chai and samosa', at: ago(2, 11)),
      Expense(amount: 320, category: Cat.travel, note: 'Petrol', at: ago(3, 18)),
      Expense(amount: 850, category: Cat.fun, note: 'Dinner with Rahul', at: ago(4, 21)),
      Expense(amount: 1200, category: Cat.bills, note: 'Electricity', at: ago(5, 10)),
      Expense(amount: 150, category: Cat.food, note: 'Swiggy', at: ago(6, 22)),
    ];
    for (final e in rows) {
      await d.insert('expenses', e.toMap());
    }

    await d.insert('people', const Person(name: 'Rahul Mehta', vpa: 'rahul.mehta@oksbi', balance: 1240).toMap());
    await d.insert('people', const Person(name: 'Priya Sharma', vpa: 'priya@ybl', balance: -450).toMap());
    await d.insert('people', const Person(name: 'Karthik V', vpa: 'karthikv@okicici').toMap());

    await d.insert('goals', const Goal(name: 'Laptop', target: 60000, saved: 12000).toMap());
    await d.insert('goals', const Goal(name: 'Trip home', target: 8000, saved: 3500).toMap());

    await d.insert('bills', const Bill(name: 'Netflix', amount: 199, day: 5, category: Cat.fun).toMap());
    await d.insert('bills', const Bill(name: 'Gym', amount: 1200, day: 12, category: Cat.fun).toMap());
    await d.insert('bills', const Bill(name: 'Broadband', amount: 799, day: 18).toMap());

    await d.insert('settings', {'k': 'budget', 'v': '45000'});
    await d.insert('settings', {'k': 'cash', 'v': '1450'});
    await d.insert('settings', {'k': 'seeded', 'v': '1'});
  }

  // ---------------------------------------------------------------- expenses

  Future<int> addExpense(Expense e) async {
    final d = await _handle;
    return d.insert('expenses', e.toMap());
  }

  Future<void> updateExpense(Expense e) async {
    if (e.id == null) return;
    final d = await _handle;
    await d.update('expenses', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  Future<void> deleteExpense(int id) async {
    final d = await _handle;
    await d.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  /// Everything in a given calendar month. DateTime(y, 13, 1) rolls into
  /// January of the next year on its own, so December needs no special case.
  Future<List<Expense>> monthExpenses(int year, int month) async {
    final d = await _handle;
    final from = DateTime(year, month, 1).millisecondsSinceEpoch;
    final to = DateTime(year, month + 1, 1).millisecondsSinceEpoch;
    final rows = await d.query('expenses',
        where: 'at >= ? AND at < ?', whereArgs: [from, to], orderBy: 'at DESC');
    return rows.map(Expense.fromMap).toList();
  }

  Future<List<Expense>> recentExpenses({int limit = 200}) async {
    final d = await _handle;
    final rows = await d.query('expenses', orderBy: 'at DESC', limit: limit);
    return rows.map(Expense.fromMap).toList();
  }

  // ------------------------------------------------------------------ people

  Future<List<Person>> people() async {
    final d = await _handle;
    final rows = await d.query('people', orderBy: 'name COLLATE NOCASE');
    return rows.map(Person.fromMap).toList();
  }

  Future<int> addPerson(Person p) async {
    final d = await _handle;
    return d.insert('people', p.toMap());
  }

  Future<void> updatePerson(Person p) async {
    if (p.id == null) return;
    final d = await _handle;
    await d.update('people', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<void> deletePerson(int id) async {
    final d = await _handle;
    await d.delete('people', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addSplit(int expenseId, int personId, int share) async {
    final d = await _handle;
    await d.insert('splits', {
      'expense_id': expenseId,
      'person_id': personId,
      'share': share,
    });
  }

  // ------------------------------------------------------------------- goals

  Future<List<Goal>> goals() async {
    final d = await _handle;
    final rows = await d.query('goals', orderBy: 'id');
    return rows.map(Goal.fromMap).toList();
  }

  Future<int> addGoal(Goal g) async {
    final d = await _handle;
    return d.insert('goals', g.toMap());
  }

  Future<void> updateGoal(Goal g) async {
    if (g.id == null) return;
    final d = await _handle;
    await d.update('goals', g.toMap(), where: 'id = ?', whereArgs: [g.id]);
  }

  Future<void> deleteGoal(int id) async {
    final d = await _handle;
    await d.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------------------------------------------------------- bills

  Future<List<Bill>> bills() async {
    final d = await _handle;
    final rows = await d.query('bills', orderBy: 'day');
    return rows.map(Bill.fromMap).toList();
  }

  Future<int> addBill(Bill b) async {
    final d = await _handle;
    return d.insert('bills', b.toMap());
  }

  Future<void> updateBill(Bill b) async {
    if (b.id == null) return;
    final d = await _handle;
    await d.update('bills', b.toMap(), where: 'id = ?', whereArgs: [b.id]);
  }

  Future<void> deleteBill(int id) async {
    final d = await _handle;
    await d.delete('bills', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------------------------------------------------------ impulse

  Future<List<ImpulseBuy>> impulses() async {
    final d = await _handle;
    final rows = await d.query('impulse', orderBy: 'at DESC');
    return rows.map(ImpulseBuy.fromMap).toList();
  }

  Future<int> addImpulse(ImpulseBuy i) async {
    final d = await _handle;
    return d.insert('impulse', i.toMap());
  }

  Future<void> deleteImpulse(int id) async {
    final d = await _handle;
    await d.delete('impulse', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------- settings

  Future<Map<String, String>> settings() async {
    final d = await _handle;
    final rows = await d.query('settings');
    return {
      for (final r in rows) (r['k'] as String): (r['v'] as String),
    };
  }

  Future<void> put(String key, String value) async {
    final d = await _handle;
    await d.insert('settings', {'k': key, 'v': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ------------------------------------------------------------------- inbox

  Future<List<Inbox>> inbox() async {
    final d = await _handle;
    final rows = await d.query('inbox', orderBy: 'at DESC');
    return rows.map(Inbox.fromMap).toList();
  }

  Future<void> addInbox(Inbox item) async {
    final d = await _handle;
    await d.insert('inbox', item.toMap());
  }

  Future<void> dropInbox(int id) async {
    final d = await _handle;
    await d.delete('inbox', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> seenSms(String fingerprint) async {
    final d = await _handle;
    final rows = await d.query('sms_seen',
        where: 'fingerprint = ?', whereArgs: [fingerprint], limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> markSms(String fingerprint) async {
    final d = await _handle;
    await d.insert(
      'sms_seen',
      {'fingerprint': fingerprint, 'at': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // ------------------------------------------------------------------- reset

  /// Wipes everything and lays the sample data down again.
  Future<void> resetAll() async {
    final d = await _handle;
    for (final t in ['splits', 'expenses', 'people', 'goals', 'bills', 'settings', 'inbox', 'sms_seen']) {
      await d.delete(t);
    }
    await _seed(d);
  }

  /// Wipes everything and leaves it empty, for someone who wants to start
  /// with their own real numbers.
  Future<void> clearAll() async {
    final d = await _handle;
    for (final t in ['splits', 'expenses', 'people', 'goals', 'bills', 'inbox', 'sms_seen']) {
      await d.delete(t);
    }
    await put('budget', '45000');
    await put('cash', '0');
  }
}
