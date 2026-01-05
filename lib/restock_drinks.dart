import 'package:flutter/material.dart';
import 'database.dart';

class RestockDrinksPage extends StatefulWidget {
  const RestockDrinksPage({super.key});

  @override
  State<RestockDrinksPage> createState() => _RestockDrinksPageState();
}

class _RestockDrinksPageState extends State<RestockDrinksPage> {
  List<Map<String, dynamic>> drinks = [];
  final TextEditingController qtyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadDrinks();
  }

  Future<void> loadDrinks() async {
    final fetchedDrinks = await StockDatabase.instance.fetchStock();
    if (mounted) {
      setState(() {
        drinks = fetchedDrinks;
      });
    }
  }

  Future<void> restock(String name) async {
    final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid quantity")),
      );
      return;
    }

    await StockDatabase.instance.increaseStock(name, qty);

    qtyCtrl.clear();
    await loadDrinks(); // Refresh list
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("$name restocked by $qty")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Restock Drinks"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey.shade900,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                labelText: "Restock Quantity",
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: drinks.isEmpty
                  ? const Center(
                      child: Text(
                        "No drinks found",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : ListView(
                      children: drinks.map((d) {
                        return Card(
                          color: Colors.grey.shade800,
                          child: ListTile(
                            title: Text(
                              "${d['name']} — Stock: ${d['quantity']}",
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => restock(d['name']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text("Restock"),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
