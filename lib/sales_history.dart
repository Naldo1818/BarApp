import 'package:flutter/material.dart';
import 'database.dart';
import 'package:intl/intl.dart';

class SalesHistoryPage extends StatefulWidget {
  const SalesHistoryPage({super.key});

  @override
  State<SalesHistoryPage> createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends State<SalesHistoryPage> {
  List<Map<String, dynamic>> sales = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSales();
  }

  Future<void> loadSales() async {
    sales = await StockDatabase.instance.fetchSalesHistory();
    if (!mounted) return;
    setState(() {
      loading = false;
    });
  }

  Future<void> clearSales() async {
    await StockDatabase.instance.clearSalesHistory();
    await loadSales();
  }

  @override
  Widget build(BuildContext context) {
    // Group sales by date (yyyy-MM-dd)
    Map<String, List<Map<String, dynamic>>> salesByDay = {};
    Map<String, double> dailyTotals = {};

    for (var sale in sales) {
      final dateTime = DateTime.parse(sale['timestamp']);
      final day = DateFormat('yyyy-MM-dd').format(dateTime);

      salesByDay[day] = salesByDay[day] ?? [];
      salesByDay[day]!.add(sale);

      dailyTotals[day] =
          (dailyTotals[day] ?? 0) + (sale['total_price'] as double);
    }

    final sortedDays = salesByDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales History"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Clear History",
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirm"),
                  content: const Text(
                    "Are you sure you want to clear sales history?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        "Clear",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) await clearSales();
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade900,
        padding: const EdgeInsets.all(12),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : sales.isEmpty
            ? const Center(
                child: Text(
                  "No sales yet",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
            : ListView.builder(
                itemCount: sortedDays.length,
                itemBuilder: (context, index) {
                  final day = sortedDays[index];
                  final daySales = salesByDay[day]!;
                  final total = dailyTotals[day]!;

                  return Card(
                    color: Colors.grey.shade800,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ExpansionTile(
                      title: Text(
                        "$day | Total: R${total.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: daySales.map((sale) {
                        final dateTime = DateTime.parse(sale['timestamp']);
                        final timeFormatted = DateFormat(
                          'HH:mm:ss',
                        ).format(dateTime);

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 12,
                          ),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade700,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${sale['item']} x${sale['quantity']}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      "Time: $timeFormatted",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "R${(sale['total_price'] as double).toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
