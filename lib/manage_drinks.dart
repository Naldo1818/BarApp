import 'package:flutter/material.dart';
import 'database.dart';

class ManageDrinksPage extends StatefulWidget {
  const ManageDrinksPage({super.key});

  @override
  State<ManageDrinksPage> createState() => _ManageDrinksPageState();
}

class _ManageDrinksPageState extends State<ManageDrinksPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  List<Map<String, dynamic>> stock = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadStock();
  }

  Future<void> loadStock() async {
    stock = await StockDatabase.instance.fetchStock();
    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> deleteDrink(int id) async {
    await StockDatabase.instance.removeDrink(id);
    await loadStock();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Drinks"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // INPUT FIELDS
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Drink Name"),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: "Stock Quantity"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: "Category"),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                final price =
                    double.tryParse(_priceController.text.trim()) ?? 0;
                final quantity =
                    int.tryParse(_quantityController.text.trim()) ?? 0;
                final category = _categoryController.text.trim();

                if (name.isEmpty ||
                    price <= 0 ||
                    quantity <= 0 ||
                    category.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please fill all fields correctly"),
                    ),
                  );
                  return;
                }

                await StockDatabase.instance.addNewDrink(
                  name,
                  price,
                  quantity,
                  category,
                );

                // Clear input fields
                _nameController.clear();
                _priceController.clear();
                _quantityController.clear();
                _categoryController.clear();

                await loadStock();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Drink added successfully!")),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text("Add Drink"),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: stock.length,
                      itemBuilder: (context, index) {
                        final item = stock[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text("${item['name']} (R${item['price']})"),
                            subtitle: Text(
                              "Stock: ${item['quantity']} | Category: ${item['category']}",
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await deleteDrink(item['id'] as int);
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
