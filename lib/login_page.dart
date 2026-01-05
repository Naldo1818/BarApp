import 'package:flutter/material.dart';
import 'database.dart';
import 'admin_page.dart' as admin;
import 'bar_home_page.dart' as bar;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController userCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    if (loading) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final username = userCtrl.text.trim();
    final password = passCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Please enter username and password"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => loading = true);

    final role = await StockDatabase.instance.validateUser(username, password);

    if (!mounted) return;

    setState(() => loading = false);

    if (role == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Invalid username or password"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ Navigate based on role
    if (role == "admin") {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const admin.AdminPage()),
      );
    } else if (role == "bartender") {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const bar.BarHomePage()),
      );
    }
  }

  @override
  void dispose() {
    userCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 350,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Login",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: userCtrl,
                decoration: const InputDecoration(
                  labelText: "Username",
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passCtrl,
                decoration: const InputDecoration(
                  labelText: "Password",
                  fillColor: Colors.white,
                  filled: true,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        "Login",
                        style: TextStyle(color: Colors.black),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
