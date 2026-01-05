import 'package:flutter/material.dart';
import 'database.dart';
import 'checkout_page.dart';
import 'sales_history.dart';
import 'login_page.dart'; // Needed for back navigation

class BarHomePage extends StatefulWidget {
  const BarHomePage({super.key});
  @override
  State<BarHomePage> createState() => _BarHomePageState();
}

class _BarHomePageState extends State<BarHomePage> {
  int openTileIndex = -1;
  Map<String, Map<String, dynamic>> cart = {};
  List<Map<String, dynamic>> stock = [];
  bool loading = true;
  static const int lowStockThreshold = 10;

  double get totalPrice => cart.values.fold(
    0,
    (prev, item) => prev + item['price'] * item['quantity'],
  );

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

  int getStock(String name) {
    final item = stock.firstWhere(
      (s) => s["name"] == name,
      orElse: () => {"quantity": 0},
    );
    return item["quantity"] as int;
  }

  void toggleTile(int index) {
    if (!mounted) return;
    setState(() => openTileIndex = (openTileIndex == index) ? -1 : index);
  }

  void addToCart(String name, double price) async {
    bool success = await StockDatabase.instance.reduceStock(name);
    if (!success) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("$name is out of stock")));
      return;
    }
    await loadStock();
    if (!mounted) return;
    setState(() {
      if (cart.containsKey(name)) {
        cart[name]!['quantity'] += 1;
      } else {
        cart[name] = {'price': price, 'quantity': 1};
      }
    });
  }

  void clearCart() async {
    for (var entry in cart.entries) {
      await StockDatabase.instance.increaseStock(
        entry.key,
        entry.value["quantity"],
      );
    }
    await loadStock();
    if (!mounted) return;
    setState(() => cart.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bar"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: "Sales History",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SalesHistoryPage()),
              );
              await loadStock();
            },
            icon: const Icon(Icons.history, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade900,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : buildBody(),
      ),
      bottomNavigationBar: buildBottomBar(),
    );
  }

  Widget buildBody() {
    final categories = <String>{};
    for (var item in stock) {
      categories.add(item['category'] as String);
    }

    return ListView(
      children: categories.map((cat) {
        final drinks = stock
            .where((s) => s['category'] == cat)
            .map((s) => itemWidget(s['name'] as String, s['price'] as double))
            .toList();
        final index = categories.toList().indexOf(cat);
        return buildTile(index, cat, drinks);
      }).toList(),
    );
  }

  Widget buildBottomBar() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Total: R${totalPrice.toStringAsFixed(2)}",
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: clearCart,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Clear"),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);

                  final result = await navigator.push(
                    MaterialPageRoute(
                      builder: (_) => CheckoutPage(cart: Map.from(cart)),
                    ),
                  );

                  if (!mounted) return;

                  if (result == true) {
                    await StockDatabase.instance.recordSale(cart);

                    if (!mounted) return;

                    setState(() => cart.clear());

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Order Confirmed!")),
                    );
                  }
                },

                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Checkout"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildTile(int index, String title, List<Widget> children) {
    bool isOpen = openTileIndex == index;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: ExpansionTile(
        key: PageStorageKey(index),
        initiallyExpanded: isOpen,
        backgroundColor: Colors.black,
        collapsedBackgroundColor: Colors.black,
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        onExpansionChanged: (_) => toggleTile(index),
        children: children,
      ),
    );
  }

  Widget itemWidget(String name, double price) {
    int remaining = getStock(name);
    final lowStock = remaining > 0 && remaining <= lowStockThreshold;
    final outOfStock = remaining <= 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: outOfStock
            ? Colors.red.shade700
            : lowStock
            ? Colors.brown
            : Colors.grey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          "$name (Stock: $remaining)",
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: outOfStock
            ? const Text(
                "Out of stock",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              )
            : lowStock
            ? const Text(
                "Low stock",
                style: TextStyle(color: Colors.yellowAccent),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "R${price.toStringAsFixed(2)}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            if (lowStock) const Icon(Icons.warning, color: Colors.yellow),
            if (outOfStock) const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: outOfStock ? null : () => addToCart(name, price),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              child: const Text("Add", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}
