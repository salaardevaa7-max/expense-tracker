import 'package:flutter/material.dart';
import '../models.dart';
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
            // --- Cloud Backup Section ---
            const Heading('Google Drive Sync'),
            Glass(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Hue.calm.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.cloud_sync, color: Hue.calm),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              repo.isSignedIn
                                  ? 'Connected'
                                  : 'Not Connected',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              repo.isSignedIn
                                  ? (repo.userEmail ?? 'Google Account')
                                  : 'Backup your data safely to Google Drive',
                              style: label(11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (!repo.isSignedIn)
                        Expanded(
                          child: Solid(
                            text: 'Connect Drive',
                            icon: Icons.login,
                            onTap: () async {
                              final ok = await repo.signIn();
                              if (ok) {
                                say(context, 'Connected to Google Drive');
                              } else {
                                say(context, 'Sign-In Failed');
                              }
                            },
                          ),
                        )
                      else ...[
                        Expanded(
                          child: Ghost(
                            text: 'Backup Now',
                            icon: Icons.upload,
                            onTap: () async {
                              await repo.backup();
                              say(context, 'Database backed up to Drive');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Ghost(
                            text: 'Restore',
                            icon: Icons.download,
                            color: Hue.hot,
                            onTap: () async {
                              await repo.restore();
                              say(context, 'Database restored from Drive');
                            },
                          ),
                        ),
                      ]
                    ],
                  )
                ],
              ),
            ),

            // --- Subscription Drain Analyzer ---
            const Heading('Subscription Drain'),
            Glass(
              glow: Hue.bad.withAlpha(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Yearly Subscription Cost', style: label(11)),
                          const SizedBox(height: 2),
                          Text(money(repo.yearlyDrain),
                              style: figure(20, color: Hue.bad)),
                        ],
                      ),
                      const Icon(Icons.warning_amber_rounded, color: Hue.bad),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You are spending ${money(repo.yearlyDrain)} every year on auto-recurring bills. Review active subscriptions below.',
                    style: const TextStyle(fontSize: 11.5, color: Hue.text2),
                  ),
                ],
              ),
            ),

            // --- Impulse Control / Cooling Off List ---
            const Heading('Impulse Control (24h Wait)'),
            if (repo.impulses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Glass(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.ac_unit, color: Hue.calm, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No items in cooling off. Add non-essential wants here first to curb emotional spending!',
                          style: label(11),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...repo.impulses.map((imp) {
                final cool = imp.isCool;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Glass(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          cool ? Icons.local_fire_department : Icons.ac_unit,
                          color: cool ? Hue.hot : Hue.calm,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(imp.name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                cool
                                    ? 'Cooling period complete. Still want it?'
                                    : 'Locked for 24h. Wait and decide later.',
                                style: label(10.5,
                                    color: cool ? Hue.good : Hue.text3),
                              ),
                            ],
                          ),
                        ),
                        Text(money(imp.amount), style: figure(14)),
                        const SizedBox(width: 8),
                        if (cool)
                          IconButton(
                            icon: const Icon(Icons.check_circle,
                                color: Hue.good),
                            onPressed: () => repo.resolveImpulse(imp.id!,
                                buy: true, note: 'Bought after cooling off'),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Hue.bad),
                            onPressed: () =>
                                repo.resolveImpulse(imp.id!, buy: false),
                          ),
                      ],
                    ),
                  ),
                );
              }),

            // --- Goals Section ---
            const Heading('Sinking Funds / Goals'),
            ...repo.goals.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Glass(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(g.name,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('${money(g.saved)} / ${money(g.target)}',
                                style: figure(14)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Stack(
                          children: [
                            Container(
                                height: 6,
                                decoration: BoxDecoration(
                                    color: w(0.05),
                                    borderRadius: BorderRadius.circular(3))),
                            FractionallySizedBox(
                              widthFactor: g.progress,
                              child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                      color: Hue.calm,
                                      borderRadius: BorderRadius.circular(3))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),

            // --- Bills Section ---
            const Heading('Recurring Bills'),
            ...repo.bills.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Glass(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                            b.active
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: b.active ? Hue.good : Hue.text3,
                            size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(b.name,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500))),
                        Text(money(b.amount), style: figure(14)),
                      ],
                    ),
                  ),
                )),

            // --- Settings Section ---
            const Heading('Settings'),
            Glass(
              child: Column(
                children: [
                  _SettingItem('Monthly Budget', money(repo.budget)),
                  const Divider(height: 20, color: Colors.white10),
                  _SettingItem('Bank Alerts', 'On (Read SMS)'),
                  const Divider(height: 20, color: Colors.white10),
                  _SettingItem('Storage', 'Local SQLite + Drive'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Solid(
                text: 'Start again',
                color: Hue.bad,
                icon: Icons.refresh,
                onTap: () => _reset(context)),
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
          Solid(
              text: 'Wipe',
              color: Hue.bad,
              onTap: () {
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
          Text(value,
              style: const TextStyle(
                  color: Hue.text, fontWeight: FontWeight.w500)),
        ],
      );
}
