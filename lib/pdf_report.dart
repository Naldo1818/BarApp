import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

Future<void> generatePdf(
  Map<String, dynamic> report,
  DateTimeRange range,
) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "Sales Report",
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            "${DateFormat.yMMMd().format(range.start)} - ${DateFormat.yMMMd().format(range.end)}",
          ),
          pw.SizedBox(height: 20),
          pw.Text("Total Revenue: R${report['totalRevenue']}"),
          pw.SizedBox(height: 10),
          pw.Text("Breakdown:"),
          pw.ListView.builder(
            itemCount: report['items'].length,
            itemBuilder: (context, index) {
              final item = report['items'][index];
              return pw.Text(
                "${item['item']} - Qty: ${item['qty']} - R${item['revenue']}",
              );
            },
          ),
        ],
      ),
    ),
  );

  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}
