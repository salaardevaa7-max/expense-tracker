import 'package:flutter/material.dart';
import 'repo.dart';
import 'screens/home.dart';
import 'screens/more.dart';
import 'screens/reports.dart';
import 'screens/split.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  paintSystemBars();
  runApp(const HisaabApp());
}

class HisaabApp extends StatefulWidget {
  const HisaabApp({super.key});

  @override
  State<HisaabApp> createState() => _HisaabAppState();
}

class _HisaabAppState extends State<HisaabApp> {
  final _repo = Repo();
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hisaab',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: AnimatedBuilder(
        animation: _repo,
        builder: (context, _) {
          if (_repo.loading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Hue.calm),
              ),
            );
          }

          final screens = [
            HomeScreen(repo: _repo),
            SplitScreen(repo: _repo),
            ReportsScreen(repo: _repo),
            MoreScreen(repo: _repo),
          ];

          return Scaffold(
            body: IndexedStack(
              index: _tab,
              children: screens,
            ),
            bottomNavigationBar: NavigationBarTheme(
              data: NavigationBarThemeData(
                indicatorColor: Hue.calm.withAlpha(40),
                labelTextStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Hue.text2),
                ),
              ),
              child: NavigationBar(
                selectedIndex: _tab,
                backgroundColor: Hue.lift,
                onDestinationSelected: (i) => setState(() => _tab = i),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.account_balance_wallet_outlined, color: Hue.text2),
                    selectedIcon: Icon(Icons.account_balance_wallet, color: Hue.calm),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.call_split, color: Hue.text2),
                    selectedIcon: Icon(Icons.call_split, color: Hue.calm),
                    label: 'Split',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.bar_chart_outlined, color: Hue.text2),
                    selectedIcon: Icon(Icons.bar_chart, color: Hue.calm),
                    label: 'Reports',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.more_horiz, color: Hue.text2),
                    selectedIcon: Icon(Icons.more_horiz, color: Hue.calm),
                    label: 'More',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
