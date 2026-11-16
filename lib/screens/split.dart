import 'package:flutter/material.dart';
import '../models.dart';
import '../money.dart';
import '../repo.dart';
import '../theme.dart';

class SplitScreen extends StatelessWidget {
  final Repo repo;

  const SplitScreen({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    int totalYouOwe = 0;
    int totalOwedToYou = 0;
    for (final p in repo.people) {
      if (p.balance > 0) totalOwedToYou += p.balance;
      if (p.balance < 0) totalYouOwe += p.balance.abs();
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Heading('Split Ledger'),

            // Net Balance Card
            Glass(
              glow: (totalOwedToYou >= totalYouOwe ? Hue.good : Hue.bad).withAlpha(40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Owed to you', style: label(11)),
                          const SizedBox(height: 2),
                          Text(money(totalOwedToYou), style: figure(20, color: Hue.good)),
                        ],
                      ),
                      Container(width: 1, height: 34, color: w(0.1)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('You owe', style: label(11)),
                          const SizedBox(height: 2),
                          Text(money(totalYouOwe), style: figure(20, color: Hue.bad)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Colors.white10),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Net Balance', style: label(13, color: Hue.text2)),
                      Text(
                        '${totalOwedToYou >= totalYouOwe ? '+' : '−'}${money((totalOwedToYou - totalYouOwe).abs())}',
                        style: figure(16, color: totalOwedToYou >= totalYouOwe ? Hue.good : Hue.bad),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Heading('People'),

            if (repo.people.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      const Text('Nobody to split with yet', style: TextStyle(color: Hue.text3)),
                      const SizedBox(height: 16),
                      Ghost(
                        text: 'Add your first person',
                        icon: Icons.person_add_outlined,
                        onTap: () => _addPerson(context),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...repo.people.map((p) => _PersonRow(person: p, onTap: () => _openPerson(context, p))),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Ghost(
                    text: 'Add Person',
                    icon: Icons.person_add_outlined,
                    onTap: () => _addPerson(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Solid(
                    text: 'Split a Bill',
                    icon: Icons.call_split,
                    onTap: () => _openNewSplit(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addPerson(BuildContext context) {
    say(context, 'Contact picker would open here');
  }

  void _openPerson(BuildContext context, Person p) {
    say(context, 'Settlement flow for ${p.name}');
  }

  void _openNewSplit(BuildContext context) {
    say(context, 'Split bill sheet');
  }
}

class _PersonRow extends StatelessWidget {
  final Person person;
  final VoidCallback onTap;

  const _PersonRow({required this.person, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = person.balance == 0 ? Hue.text3 : (person.balance > 0 ? Hue.good : Hue.bad);
    final statusText = person.balance == 0 ? 'All square' : (person.balance > 0 ? 'Owes you' : 'You owe');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Glass(
        blur: 0,
        padding: const EdgeInsets.all(12),
        onTap: onTap,
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: w(0.1),
              radius: 19,
              child: Text(person.initials, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Hue.text2)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(person.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Hue.text)),
                  const SizedBox(height: 2),
                  Text(statusText, style: label(11, color: statusColor)),
                ],
              ),
            ),
            if (person.balance != 0)
              Text(
                money(person.balance.abs()),
                style: figure(15, color: statusColor),
              )
            else
              const Icon(Icons.check_circle_outline, color: Hue.text3, size: 18),
          ],
        ),
      ),
    );
  }
}
