import 'package:flutter/material.dart';

class AnimatedGradientBackground extends StatefulWidget {
  @override
  _AnimatedGradientBackgroundState createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _topColor;
  late Animation<Color?> _bottomColor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8), // A little faster for more dynamism
    )..repeat(reverse: true);

    // --- NEW BRIGHTER COLORS ---
    _topColor = ColorTween(
      begin: Colors.blue.shade200, // Light blue
      end: Colors.teal.shade200,    // Light teal
    ).animate(_controller);

    _bottomColor = ColorTween(
      begin: Colors.teal.shade200,      // Light teal
      end: Colors.purple.shade200, // Light purple
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_topColor.value!, _bottomColor.value!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      },
    );
  }
}