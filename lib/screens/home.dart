import 'package:flutter/material.dart';
import '../repo.dart';
import '../money.dart';
import '../theme.dart';
import '../vessel.dart';
import 'add_sheet.dart';

class HomeScreen extends StatelessWidget {
  final Repo repo;

  const HomeScreen({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    final pulse = repo.pulse;
    final reserveRatio = pulse.budget <= 0 ? 0.0 : (pulse.held / pulse.budget);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            // Top bar
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('September 2026', style: label(11)),
                    const SizedBox(height: 2),
                    Text('Hisaab', style: figure(20, weight: FontWeight.w700)),
                  ],
                ),
                const Spacer(),
                Ghost(
                  text: 'Cash: ${money(int.tryParse(repo.settings['cash'] ?? '0') ?? 0)}',
                  icon: Icons.wallet_outlined,
                  onTap: () {
                    // Quick cash adjustment or view
                    say(context, 'Cash wallet');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // The Vessel
            Center(
              child: Glass(
                radius: 140,
                blur: 24,
                tint: 0.07,
                padding: const EdgeInsets.all(28),
                glow: Hue.liquidAt(pulse.fill).withAlpha(40),
                onTap: () => showAddSheet(context, repo),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Vessel(
                      fill: pulse.fill,
                      reserve: reserveRatio,
                      size: const Size(140, 140),
                    ),
                    const SizedBox(height: 12),
                    Text('Spent so far', style: label(11)),
                    const SizedBox(height: 2),
                    Text(money(pulse.spent), style: figure(22)),
                    const SizedBox(height: 4),
                    Text('of ${money(pulse.budget)} budget', style: label(11)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Daily Pace Strip
            Glass(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('You can spend', style: label(11)),
                            const SizedBox(height: 2),
                            Text(
                              money(pulse.allowance),
                              style: figure(21,
                                  color: pulse.overspending ? Hue.bad : Hue.good),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 34, color: w(0.1)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('You have been spending',
                                style: label(11), textAlign: TextAlign.right),
                            const SizedBox(height: 2),
                            Text(money(pulse.pace),
                                style: figure(21, color: Hue.text)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Colors.white10),
                  const SizedBox(height: 10),
                  Text(
                    pulse.sentence,
                    style: const TextStyle(fontSize: 12, color: Hue.text2, height: 1.4),
                  ),
                ],
              ),
            ),

            Heading('Recent Expenses',
                trailing: Ghost(
                  text: 'Add',
                  icon: Icons.add,
                  onTap: () => showAddSheet(context, repo),
                )),

            // Expenses list
            if (repo.expenses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text('No expenses yet this month', style: TextStyle(color: Hue.text3)),
                ),
              )
            else
              ...repo.expenses.map((e) {
                final catColor = Hue.forCategory(e.category);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Glass(
                    blur: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: catColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Hue.iconFor(e.category), color: catColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.note.isEmpty ? e.category : e.note,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Hue.text),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${e.category} · ${whenLabel(e.at)}',
                                style: label(11),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          money(e.amount),
                          style: figure(15, color: Hue.text),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
