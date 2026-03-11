import 'package:flutter/material.dart';
import '../data/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {

  final _email = TextEditingController();
  final _password = TextEditingController();

  bool login = true;
  bool loading = false;

  final AuthService auth = AuthService();

  Future<void> submit() async {
    setState(() {
      loading = true;
    });

    try {
      if (login) {
        await auth.signIn(_email.text, _password.text);
      } else {
        await auth.register(_email.text, _password.text);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Account")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : submit,
              child: Text(login ? "Login" : "Register"),
            ),

            TextButton(
              onPressed: () {
                setState(() {
                  login = !login;
                });
              },
              child: Text(
                login
                    ? "Create account"
                    : "Already have account? Login",
              ),
            )
          ],
        ),
      ),
    );
  }
}