import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'home_screen.dart'; 
import '../utils/fade_page_route.dart'; // Import our fade route

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/videos/splash_animation1.mp4', 
    )..initialize().then((_) {
        if (!mounted) return;

        _controller.play();
        _controller.addListener(_checkVideoEnd);
        setState(() {
          _isVideoVisible = true;
        });
      });
  }

  void _checkVideoEnd() {
    if (_controller.value.isInitialized &&
        !_controller.value.isPlaying &&
        _controller.value.position >= _controller.value.duration) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    _controller.removeListener(_checkVideoEnd);
    
    Navigator.of(context).pushReplacement(
      FadePageRoute(child: HomeScreen()),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_checkVideoEnd);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        // ✅ --- THIS IS THE FIX ---
        // You were missing the 'child:' parameter.
        child: AnimatedOpacity(
          opacity: _isVideoVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500), 
          child: _controller.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                )
              : Container(),
        ),
      ),
    );
  }
}