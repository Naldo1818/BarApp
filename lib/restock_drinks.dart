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
    drinks = await StockDatabase.instance.fetchStock();
    if (mounted) setState(() {});
  }

  Future<void> restock(String name) async {
    final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) return;

    await StockDatabase.instance.increaseStock(name, qty);

    qtyCtrl.clear();
    await loadDrinks();
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
              decoration: const InputDecoration(
                labelText: "Restock Quantity",
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: drinks.map((d) {
                  return Card(
                    child: ListTile(
                      title: Text("${d['name']} — Stock: ${d['quantity']}"),
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
