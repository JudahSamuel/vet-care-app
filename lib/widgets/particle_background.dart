import 'dart:math';
import 'package:flutter/material.dart';

class Particle {
  double x, y, vx, vy, radius, initialX, initialY;
  Color color;
  Particle(this.x, this.y, this.vx, this.vy, this.radius, this.color)
      : initialX = x,
        initialY = y;
}

class ParticleBackground extends StatefulWidget {
  @override
  _ParticleBackgroundState createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> particles = [];
  final Random random = Random();
  Offset pointerPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (particles.isEmpty) {
      final size = MediaQuery.of(context).size;
      const particleCount = 70;
      for (int i = 0; i < particleCount; i++) {
        particles.add(_createParticle(size));
      }
    }
  }

  Particle _createParticle(Size size) {
    final x = random.nextDouble() * size.width;
    final y = random.nextDouble() * size.height;
    final vx = (random.nextDouble() - 0.5) * 0.5;
    final vy = (random.nextDouble() - 0.5) * 0.5;
    final radius = random.nextDouble() * 2 + 1;
    final color = Colors.white.withOpacity(random.nextDouble() * 0.5 + 0.2);
    return Particle(x, y, vx, vy, radius, color);
  }

  void _updateParticles(Size size) {
    for (var p in particles) {
      // Basic movement
      p.x += p.vx;
      p.y += p.vy;

      // Wall collision
      if (p.x < 0 || p.x > size.width) p.vx *= -1;
      if (p.y < 0 || p.y > size.height) p.vy *= -1;

      // Interaction with pointer
      if (pointerPosition != Offset.zero) {
        final dx = p.x - pointerPosition.dx;
        final dy = p.y - pointerPosition.dy;
        final distance = sqrt(dx * dx + dy * dy);
        const interactionRadius = 100.0;
        if (distance < interactionRadius) {
          final force = (1 - (distance / interactionRadius)) * 2;
          p.x += (dx / distance) * force;
          p.y += (dy / distance) * force;
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) => setState(() => pointerPosition = details.globalPosition),
      onPanEnd: (_) => setState(() => pointerPosition = Offset.zero),
      child: MouseRegion(
        onHover: (event) => setState(() => pointerPosition = event.position),
        onExit: (_) => setState(() => pointerPosition = Offset.zero),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final size = MediaQuery.of(context).size;
            _updateParticles(size);
            return CustomPaint(
              size: size,
              painter: ParticlePainter(particles: particles),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1a237e), Color(0xFF000000)], // Dark blue to black
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var p in particles) {
      paint.color = p.color;
      canvas.drawCircle(Offset(p.x, p.y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}