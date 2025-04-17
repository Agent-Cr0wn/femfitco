// lib/features/questionnaire/screens/workout_generation_complete_screen.dart

import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../common/constants/colors.dart';

class WorkoutGenerationCompletePage extends StatefulWidget {
  const WorkoutGenerationCompletePage({super.key});

  @override
  State<WorkoutGenerationCompletePage> createState() => _WorkoutGenerationCompletePageState();
}

class _WorkoutGenerationCompletePageState extends State<WorkoutGenerationCompletePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  final ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );
    
    _controller.forward();
    _confettiController.play();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryWineRed.withOpacity(0.95),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Checkmark animation
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppColors.primaryWineRed,
                          size: 80,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                // Success text
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _opacityAnimation.value,
                      child: child,
                    );
                  },
                  child: const Column(
                    children: [
                      Text(
                        "Your Workout Plan is Ready!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 50.0),
                        child: Text(
                          "Let's start your fitness journey with your personalized plan",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Confetti animation at the top
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 1,
              emissionFrequency: 0.05,
              numberOfParticles: 25,
              gravity: 0.2,
              colors: const [
                Colors.white,
                Colors.pink,
                Colors.purple,
                Colors.blue,
                Colors.amber,
              ],
            ),
          ),
        ],
      ),
    );
  }
}