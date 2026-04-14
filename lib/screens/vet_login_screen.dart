// lib/screens/vet_login_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'vet_dashboard_screen.dart';

class VetLoginPage extends StatefulWidget {
  @override
  _VetLoginPageState createState() => _VetLoginPageState();
}

class _VetLoginPageState extends State<VetLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();

  void _handleVetLogin() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    final result = await _apiService.loginVet(email, password);
    if (!mounted) return;

    if (result['statusCode'] == 200) {
      final String vetId = result['body']['vetId'];
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => VetDashboardPage(vetId: vetId)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${result['body']['msg']}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // This is a simplified version of your user login screen's UI
    return Scaffold(
      appBar: AppBar(title: Text("Vet Portal Login")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _handleVetLogin,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}