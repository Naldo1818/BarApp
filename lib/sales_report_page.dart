import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'database.dart';

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  DateTimeRange? dateRange;
  Map<String, dynamic>? report;
  bool loading = false;
  String selectedCategory = 'All'; // For filtering

  final DateFormat df = DateFormat('yyyy-MM-dd');

  /// ---------------- PICK DATE RANGE ----------------
  Future<void> pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange:
          dateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      builder: (context, child) {
        return Theme(data: ThemeData.dark(), child: child!);
      },
    );

    if (picked != null) {
      setState(() => dateRange = picked);
      await generateReport();
    }
  }

  /// ---------------- GENERATE REPORT ----------------
  Future<void> generateReport() async {
    if (dateRange == null) return;
    setState(() => loading = true);

    final result = await StockDatabase.instance.generateSalesReportByDate(
      dateRange!.start,
      dateRange!.end,
    );

    setState(() {
      report = result;
      loading = false;
      selectedCategory = 'All'; // reset filter
    });
  }

  /// ---------------- EXPORT PDF ----------------
  Future<void> exportPDF() async {
    if (report == null) return;

    final pdf = pw.Document();
    final allItems = (report!['items'] as List).cast<Map<String, dynamic>>();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Sales Report', style: pw.TextStyle(fontSize: 24)),
            pw.Text(
              'Date: ${df.format(dateRange!.start)} - ${df.format(dateRange!.end)}',
            ),
            pw.SizedBox(height: 20),
            pw.Text('Total Revenue: R${report!['totalRevenue']}'),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Item', 'Quantity', 'Revenue', 'Category'],
              data: allItems
                  .map(
                    (e) => [
                      e['item'],
                      e['qty'],
                      e['revenue'],
                      e['category'] ?? '',
                    ],
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  /// ---------------- BUTTON STYLE ----------------
  Widget buildButton(String text, VoidCallback onPressed) {
    return Center(
      child: SizedBox(
        width: 250,
        height: 60,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(text),
        ),
      ),
    );
  }

  /// ---------------- PIE CHART ----------------
  Widget buildPieChart() {
    if (report == null) return const SizedBox();

    // Filter items by selected category
    final items = (report!['items'] as List)
        .cast<Map<String, dynamic>>()
        .where(
          (e) => selectedCategory == 'All' || e['category'] == selectedCategory,
        )
        .toList();

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No data for this category',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final totalRevenueFiltered = items.fold<double>(
      0,
      (sum, e) => sum + (e['revenue'] as double),
    );

    return Column(
      children: [
        // Show total revenue for selected category
        Text(
          'Total Revenue: R${totalRevenueFiltered.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: PieChart(
            PieChartData(
              sections: items.map((e) {
                final revenue = e['revenue'] as double;
                final percent = totalRevenueFiltered == 0
                    ? 0.0
                    : revenue / totalRevenueFiltered * 100;
                return PieChartSectionData(
                  color: Colors
                      .primaries[items.indexOf(e) % Colors.primaries.length],
                  value: revenue,
                  title: '${e['item']}\n${percent.toStringAsFixed(1)}%',
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = <String>[
      'All',
      'Beers',
      'Ciders',
      'Vodka',
      'Rums',
      'Whiskies',
      'Soft Drinks',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Report'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        color: Colors.grey.shade900,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            buildButton('📅 Pick Date Range', pickDateRange),
            const SizedBox(height: 20),
            if (report != null)
              DropdownButton<String>(
                value: selectedCategory,
                dropdownColor: Colors.grey.shade800,
                style: const TextStyle(color: Colors.white),
                items: categories
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedCategory = val);
                },
              ),
            const SizedBox(height: 20),
            if (loading) const CircularProgressIndicator(color: Colors.white),
            if (!loading && report != null) Expanded(child: buildPieChart()),
            const SizedBox(height: 20),
            if (!loading && report != null)
              buildButton('📄 Export to PDF', exportPDF),
          ],
        ),
      ),
    );
  }
}
