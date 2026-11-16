import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models.dart';
import '../money.dart';
import '../repo.dart';
import '../theme.dart';

class ReportsScreen extends StatefulWidget {
  final Repo repo;

  const ReportsScreen({super.key, required this.repo});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _period = 0; // 0: Month, 1: Week

  @override
  Widget build(BuildContext context) {
    final catData = byCategory(widget.repo.expenses);
    final total = catData.fold<int>(0, (a, b) => a + b.value);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Heading('Insights'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: w(0.05), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      _SegBtn(text: 'Month', on: _period == 0, onTap: () => setState(() => _period = 0)),
                      _SegBtn(text: 'Week', on: _period == 1, onTap: () => setState(() => _period = 1)),
                    ],
                  ),
                ),
              ],
            ),

            // Top Summary Card
            Glass(
              child: Column(
                children: [
                  Text('Total Spending', style: label(12)),
                  const SizedBox(height: 4),
                  Text(money(total), style: figure(28)),
                  const SizedBox(height: 20),
                  const _TrendChart(),
                ],
              ),
            ),

            const Heading('Category Breakdown'),

            if (catData.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('No data for this period', style: TextStyle(color: Hue.text3))),
              )
            else
              ...catData.map((e) {
                final ratio = total <= 0 ? 0.0 : e.value / total;
                final color = Hue.forCategory(e.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Hue.iconFor(e.key), color: color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Hue.text)),
                                Text(money(e.value), style: figure(13)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Stack(
                              children: [
                                Container(height: 4, decoration: BoxDecoration(color: w(0.05), borderRadius: BorderRadius.circular(2))),
                                FractionallySizedBox(
                                  widthFactor: ratio,
                                  child: Container(height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _SegBtn extends StatelessWidget {
  final String text;
  final bool on;
  final VoidCallback onTap;

  const _SegBtn({required this.text, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: on ? w(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: on ? Hue.text : Hue.text3)),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart();

  @override
  Widget build(BuildContext context) {
    // Fake trend line for the prototype, in real app this would be data-driven
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: CustomPaint(
        painter: _TrendPainter(),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Hue.calm
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final points = [0.8, 0.6, 0.9, 0.4, 0.7, 0.3, 0.5, 0.2, 0.6, 0.4];
    final dx = size.width / (points.length - 1);

    path.moveTo(0, size.height * (1 - points[0]));
    for (int i = 1; i < points.length; i++) {
      path.lineTo(i * dx, size.height * (1 - points[i]));
    }

    canvas.drawPath(path, paint);

    // Area under
    final areaPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Hue.calm.withAlpha(40), Hue.calm.withAlpha(0)],
      ).createShader(Offset.zero & size);

    canvas.drawPath(areaPath, areaPaint);
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}
