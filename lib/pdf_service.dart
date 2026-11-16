// ===========================================================================
//  Trip Receipt PDF Report Service.
//
//  Generates a professional PDF report for a trip, including a table of
//  expenses and all attached receipt images.
// ===========================================================================

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'models.dart';
import 'money.dart';

class PdfService {
  static Future<void> generateTripReport(Trip trip, List<Expense> expenses) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Hisaab Trip Report', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                  pw.Text(trip.name, style: pw.TextStyle(fontSize: 16)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Expenses:'),
                pw.Text(money(expenses.fold(0, (sum, e) => sum + e.amount)), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Category', 'Note', 'Amount'],
              data: expenses.map((e) => [
                '${e.at.day}/${e.at.month}/${e.at.year}',
                e.category,
                e.note,
                money(e.amount),
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    // Add Receipt Images Page
    final photoExpenses = expenses.where((e) => e.photo != null).toList();
    if (photoExpenses.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => pw.Text('Attached Receipts', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          build: (context) {
            return [
              pw.Wrap(
                spacing: 20,
                runSpacing: 20,
                children: photoExpenses.map((e) {
                  final file = File(e.photo!);
                  if (!file.existsSync()) return pw.SizedBox();
                  final image = pw.MemoryImage(file.readAsBytesSync());
                  return pw.Column(
                    children: [
                      pw.Container(
                        width: 150,
                        height: 200,
                        child: pw.Image(image, fit: pw.BoxFit.contain),
                      ),
                      pw.Text('${e.note} (${money(e.amount)})', style: pw.TextStyle(fontSize: 10)),
                    ],
                  );
                }).toList(),
              ),
            ];
          },
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
