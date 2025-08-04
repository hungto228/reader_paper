import 'package:flutter/material.dart';
import 'dart:math' as math;

class CoinAnimation extends StatefulWidget {
  final VoidCallback onComplete;
  final int coinCount;
  final Offset startPosition;
  final Offset endPosition;

  const CoinAnimation({
    Key? key,
    required this.onComplete,
    required this.coinCount,
    required this.startPosition,
    required this.endPosition,
  }) : super(key: key);

  @override
  State<CoinAnimation> createState() => _CoinAnimationState();
}

class _CoinAnimationState extends State<CoinAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  List<CoinParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    print('CoinAnimation created with start: ${widget.startPosition}, end: ${widget.endPosition}');
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        print('CoinAnimation completed');
        widget.onComplete();
      }
    });

    _createParticles();
    _controller.forward();
  }

  void _createParticles() {
    _particles.clear();
    for (int i = 0; i < widget.coinCount; i++) {
      // Add some randomness to the start position
      final randomOffset = Offset(
        (math.Random().nextDouble() - 0.5) * 20,
        (math.Random().nextDouble() - 0.5) * 20,
      );
      
      _particles.add(CoinParticle(
        id: i,
        startOffset: widget.startPosition + randomOffset,
        endOffset: widget.endPosition,
        delay: i * 100.0,
        arcHeight: 50 + math.Random().nextDouble() * 100,
        rotationSpeed: (math.Random().nextDouble() - 0.5) * 4,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: _particles.map((particle) {
            final progress = _animation.value;
            final particleProgress = math.max(0, (progress - particle.delay / 1200) / (1 - particle.delay / 1200));
            
            if (particleProgress <= 0) return const SizedBox.shrink();

            // Calculate position with arc trajectory
            final currentOffset = _calculateArcPosition(
              particle.startOffset,
              particle.endOffset,
              particle.arcHeight,
              particleProgress.toDouble(),
            );

            // Calculate rotation
            final rotation = particle.rotationSpeed * particleProgress * 2 * math.pi;

            return Positioned(
              left: currentOffset.dx - 10, // Center the coin
              top: currentOffset.dy - 10,
              child: Transform.rotate(
                angle: rotation,
                child: Transform.scale(
                  scale: 0.8 + (1 - particleProgress) * 0.4, // Start larger, shrink as it moves
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.8),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.monetization_on,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Offset _calculateArcPosition(Offset start, Offset end, double arcHeight, double progress) {
    // Create a parabolic arc trajectory
    final dx = start.dx + (end.dx - start.dx) * progress;
    final dy = start.dy + (end.dy - start.dy) * progress - arcHeight * math.sin(progress * math.pi);
    
    // Add a small offset to adjust the final position
    final adjustedEnd = Offset(end.dx, end.dy - 20); // Move up by 20 pixels
    
    final finalDx = start.dx + (adjustedEnd.dx - start.dx) * progress;
    final finalDy = start.dy + (adjustedEnd.dy - start.dy) * progress - arcHeight * math.sin(progress * math.pi);
    
    return Offset(finalDx, finalDy);
  }
}

class CoinParticle {
  final int id;
  final Offset startOffset;
  final Offset endOffset;
  final double delay;
  final double arcHeight;
  final double rotationSpeed;

  CoinParticle({
    required this.id,
    required this.startOffset,
    required this.endOffset,
    required this.delay,
    required this.arcHeight,
    required this.rotationSpeed,
  });
} 