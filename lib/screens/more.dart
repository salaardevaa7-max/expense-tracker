import 'package:flutter/material.dart';
import '../repo.dart';
import '../theme.dart';
import '../money.dart';

class MoreScreen extends StatelessWidget {
  final Repo repo;

  const MoreScreen({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Heading('Goals'),
            ...repo.goals.map((g) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Glass(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(g.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        Text('${money(g.saved)} / ${money(g.target)}', style: figure(14)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Stack(
                      children: [
                        Container(height: 6, decoration: BoxDecoration(color: w(0.05), borderRadius: BorderRadius.circular(3))),
                        FractionallySizedBox(
                          widthFactor: g.progress,
                          child: Container(height: 6, decoration: BoxDecoration(color: Hue.calm, borderRadius: BorderRadius.circular(3))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),

            const Heading('Bills'),
            ...repo.bills.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Glass(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(b.active ? Icons.check_circle : Icons.circle_outlined, color: b.active ? Hue.good : Hue.text3, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(b.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                    Text(money(b.amount), style: figure(14)),
                  ],
                ),
              ),
            )),

            const Heading('Settings'),
            Glass(
              child: Column(
                children: [
                  _SettingItem('Monthly Budget', money(repo.budget)),
                  const Divider(height: 20, color: Colors.white10),
                  _SettingItem('Bank Alerts', 'On (Read SMS)'),
                  const Divider(height: 20, color: Colors.white10),
                  _SettingItem('Data', 'Local only'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Solid(text: 'Start again', color: Hue.bad, icon: Icons.refresh, onTap: () => _reset(context)),
          ],
        ),
      ),
    );
  }

  void _reset(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Hue.lift,
        title: const Text('Start again?'),
        content: const Text('This deletes everything and resets the app.'),
        actions: [
          Ghost(text: 'Cancel', onTap: () => Navigator.pop(c)),
          Solid(text: 'Wipe', color: Hue.bad, onTap: () {
            repo.resetAll();
            Navigator.pop(c);
          }),
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final String label;
  final String value;
  const _SettingItem(this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: Hue.text2)),
      Text(value, style: const TextStyle(color: Hue.text, fontWeight: FontWeight.w500)),
    ],
  );
}
