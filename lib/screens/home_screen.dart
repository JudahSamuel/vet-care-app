import 'package:flutter/material.dart';
import '../widgets/particle_background.dart'; // <-- 1. Import new background
import '../widgets/variable_proximity_text.dart';
import 'login_screen.dart';
import 'vet_login_screen.dart';

// 2. Convert to a StatefulWidget to manage animations
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 3. Variables to control the staggered fade-in animation
  bool _showTitle = false;
  bool _showSubtitle = false;
  bool _showButtons = false;

  @override
  void initState() {
    super.initState();
    // Trigger animations with delays
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showTitle = true);
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showSubtitle = true);
    });
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _showButtons = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 4. Use the new ParticleBackground
          ParticleBackground(),

          // 5. Use AnimatedOpacity for a smooth fade-in effect
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                AnimatedOpacity(
                  opacity: _showTitle ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: VariableProximityText(
                    text: 'PawTech',
                    fontSize: 75.0,
                    radius: 150.0,
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedOpacity(
                  opacity: _showSubtitle ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: VariableProximityText(
                    text: 'Connecting Paws',
                    fontSize: 24.0,
                    radius: 100.0,
                  ),
                ),
                const Spacer(flex: 3),
                AnimatedOpacity(
                  opacity: _showButtons ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => LoginPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Get Started as a Pet Owner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => VetLoginPage()),
                          );
                        },
                         style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white54),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Login as a Veterinarian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}