import 'package:flutter/material.dart';
// Note: We are NOT importing 'google_sign_in.dart'
import '../services/api_service.dart';
import '../utils/custom_page_route.dart';
import 'create_profile_screen.dart';
import 'dashboard_screen.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false; // To show loading indicator on Login button

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Email/Password Login Logic ---
  void _handleLogin() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both email and password.")),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final result = await _apiService.loginUser(email, password);
    if (!mounted) return;

    setState(() { _isLoading = false; });

    if (result['statusCode'] == 200) {
      final String userId = result['body']['userId'];
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => DashboardPage(gender: 'male', userId: userId)),
      );
    } else {
      // Show error from server (e.g., "Invalid credentials")
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${result['body']['msg']}")),
      );
    }
  }
  
  // --- Navigation for New Users ---
  void navigateToCreateProfile() {
    Navigator.of(context).push(
      FadePageRoute(
        child: CreateProfilePage(), // Navigates to the full sign-up screen
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.background),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.pets, size: 80, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome to PawTech',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 40),
                  
                  // --- Email/Password Fields ---
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.2),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.2),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- Email/Password Button ---
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                      ? CircularProgressIndicator(color: Colors.white) 
                      : const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: navigateToCreateProfile,
                    child: const Text("Don't have an account? Sign Up"),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}