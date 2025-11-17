import 'package:flutter/material.dart';
import 'login_page.dart';
//import 'database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // DELETE old database (for development only)
  //await StockDatabase.instance.deleteDB();

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
          seedColor: const Color.fromARGB(255, 0, 0, 0),
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
