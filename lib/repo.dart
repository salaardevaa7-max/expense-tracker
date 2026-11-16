// ===========================================================================
//  The bridge between the SQLite database and the Flutter UI.
//
//  Every screen that needs data subscribes to this repo and rebuilds whenever
//  it changes. A new expense or a split settlement only has to change the
//  DB and call `notifyListeners()` here, and every relevant part of the app
//  refreshes instantly.
// ===========================================================================

import 'package:flutter/foundation.dart';
import 'db.dart';
import 'models.dart';
import 'money.dart';

class Repo extends ChangeNotifier {
  List<Expense> expenses = [];
  List<Person> people = [];
  List<Goal> goals = [];
  List<Bill> bills = [];
  Map<String, String> settings = {};
  List<Inbox> inbox = [];

  bool loading = true;

  Repo() {
    load();
  }

  Future<void> load() async {
    loading = true;
    notifyListeners();

    final now = DateTime.now();
    expenses = await Db.i.monthExpenses(now.year, now.month);
    people = await Db.i.people();
    goals = await Db.i.goals();
    bills = await Db.i.bills();
    settings = await Db.i.settings();
    inbox = await Db.i.inbox();

    loading = false;
    notifyListeners();
  }

  // ------------------------------------------------------------------ helpers

  int get budget => int.tryParse(settings['budget'] ?? '45000') ?? 45000;

  MonthPulse get pulse => pulseFor(
        monthExpenses: expenses,
        bills: bills,
        budget: budget,
      );

  // ------------------------------------------------------------------ actions

  Future<void> addExpense(Expense e) async {
    await Db.i.addExpense(e);
    await load();
  }

  Future<void> deleteExpense(int id) async {
    await Db.i.deleteExpense(id);
    await load();
  }

  Future<void> addPerson(Person p) async {
    await Db.i.addPerson(p);
    await load();
  }

  Future<void> updatePerson(Person p) async {
    await Db.i.updatePerson(p);
    await load();
  }

  Future<void> addGoal(Goal g) async {
    await Db.i.addGoal(g);
    await load();
  }

  Future<void> updateGoal(Goal g) async {
    await Db.i.updateGoal(g);
    await load();
  }

  Future<void> addBill(Bill b) async {
    await Db.i.addBill(b);
    await load();
  }

  Future<void> updateBill(Bill b) async {
    await Db.i.updateBill(b);
    await load();
  }

  Future<void> resetAll() async {
    await Db.i.resetAll();
    await load();
  }

  Future<void> clearAll() async {
    await Db.i.clearAll();
    await load();
  }

  Future<void> parseSms(RawSms raw) async {
    // The parser is pure-Dart logic; the SMS inbox reader is a plugin.
    // The UI calls this parser and, if it returns a hit, offers the user a
    // button to book it.
    // This method does not add the expense itself, because bank SMS formats
    // are too unreliable to be trusted silently.
  }
}
