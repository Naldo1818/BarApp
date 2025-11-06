import 'package:flutter/material.dart';
import 'database.dart';

void main() {
  runApp(const BarMenuApp());
}

class BarMenuApp extends StatelessWidget {
  const BarMenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Bar Menu",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 255, 255, 255),
        ),
        useMaterial3: true,
      ),
      home: const BarHomePage(),
    );
  }
}

class BarHomePage extends StatefulWidget {
  const BarHomePage({super.key});

  @override
  State<BarHomePage> createState() => _BarHomePageState();
}

class _BarHomePageState extends State<BarHomePage> {
  int openTileIndex = -1;

  // Cart: item -> {'price': double, 'quantity': int}
  Map<String, Map<String, dynamic>> cart = {};

  double get totalPrice => cart.values.fold(
    0,
    (prev, item) => prev + item['price'] * item['quantity'],
  );

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

  int getStock(String name) {
    final item = stock.firstWhere(
      (s) => s["name"] == name,
      orElse: () => {"quantity": 0},
    );
    return item["quantity"];
  }

  void toggleTile(int index) {
    setState(() {
      openTileIndex = (openTileIndex == index) ? -1 : index;
    });
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

    await loadStock(); // refresh UI

    setState(() {
      if (cart.containsKey(name)) {
        cart[name]!['quantity'] += 1;
      } else {
        cart[name] = {'price': price, 'quantity': 1};
      }
    });
  }

  void clearCart() {
    setState(() {
      cart.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bar"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey.shade900,
        child: ListView(
          children: [
            buildTile(0, "Beers", [
              item("Castle Lager", 29),
              item("Heineken", 35),
              item("Corona", 40),
            ]),
            buildTile(1, "Ciders", [
              item("Savanna Dry", 32),
              item("Hunters Gold", 30),
              item("Brutal Fruit", 28),
            ]),
            buildTile(2, "Vodka", [
              item("Smirnoff Vodka (Single)", 25),
              item("Absolut Vodka (Single)", 35),
              item("Belvedere (Single)", 50),
            ]),
            buildTile(3, "Rums", [
              item("Captain Morgan", 28),
              item("Bacardi White Rum", 30),
            ]),
            buildTile(4, "Whiskies", [
              item("Jameson (Single)", 35),
              item("Jack Daniels (Single)", 38),
              item("Glenfiddich 12 (Single)", 55),
            ]),
            buildTile(5, "Soft Drinks", [
              item("Coke", 15),
              item("Sprite", 15),
              item("Tonic Water", 18),
              item("Ginger Ale", 18),
            ]),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 168, 0, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onPressed: clearCart,
                  child: const Text(
                    "Clear",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 15, 133, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CheckoutPage(cart: Map.from(cart)),
                      ),
                    );
                  },
                  child: const Text(
                    "Checkout",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTile(int index, String title, List<Widget> children) {
    bool isOpen = openTileIndex == index;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey(index),
          initiallyExpanded: isOpen,
          backgroundColor: Colors.black,
          collapsedBackgroundColor: Colors.black,
          collapsedIconColor: Colors.white,
          iconColor: Colors.white,
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          onExpansionChanged: (expanded) => toggleTile(index),
          children: children,
        ),
      ),
    );
  }

  Widget item(String name, double price) {
    int remaining = getStock(name);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: remaining > 0
            ? const Color.fromARGB(255, 99, 99, 99)
            : Colors.grey.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          "$name (Stock: $remaining)",
          style: const TextStyle(color: Colors.white),
        ),
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
            ElevatedButton(
              onPressed: remaining > 0 ? () => addToCart(name, price) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              ),
              child: const Text("Add", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckoutPage extends StatelessWidget {
  final Map<String, Map<String, dynamic>> cart;

  const CheckoutPage({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    double totalPrice = cart.values.fold(
      0,
      (prev, item) => prev + item['price'] * item['quantity'],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey.shade900,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Order",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: cart.entries
                    .map(
                      (e) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${e.key} x${e.value['quantity']}",
                              style: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              "R${(e.value['price'] * e.value['quantity']).toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Total: R${totalPrice.toStringAsFixed(2)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 15, 133, 0),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Order Confirmed!")),
                    );
                  },
                  child: const Text(
                    "Confirm Order",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    cart.clear();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Cancel Order",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
