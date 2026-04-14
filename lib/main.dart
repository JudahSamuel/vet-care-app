import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts for theming
import 'screens/splash_screen.dart'; // Import the splash screen you created

void main() => runApp(VetApp()); // Main function to run the app

class VetApp extends StatelessWidget {
  // Use const constructor for stateless widgets
  const VetApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define the application's theme data
    final theme = ThemeData(
      useMaterial3: true, // Enable Material Design 3 features
      // Define the color scheme based on a seed color
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal, // Your primary branding color
        brightness: Brightness.dark, // Use a dark theme
        // You can customize other colors like background if needed
        background: const Color(0xFF121212), // Slightly darker background
      ),
      // Apply the Poppins font to the text theme
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme, // Start with the default dark text theme
      ),
      // Optional: Customize other theme elements like AppBar, buttons etc.
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // Make AppBar blend in
        elevation: 0, // No shadow
      ),
    );

    // Build the main application widget
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Hide the debug banner
      title: 'VetCare App', // The title shown in the OS task switcher
      theme: theme, // Apply the custom theme
      home: SplashScreen(), // Start the app with the SplashScreen
    );
  }
}