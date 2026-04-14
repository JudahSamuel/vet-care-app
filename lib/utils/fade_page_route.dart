import 'package:flutter/material.dart';

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  FadePageRoute({required this.child})
      : super(
          // Set the transition duration
          transitionDuration: const Duration(milliseconds: 600),
          
          pageBuilder: (context, animation, secondaryAnimation) => child,
          
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Use a simple FadeTransition
            // This will fade in the new screen (HomeScreen)
            // while the old one (SplashScreen) fades out.
            return FadeTransition(opacity: animation, child: child);
          },
        );
}