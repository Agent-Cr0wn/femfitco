// lib/features/questionnaire/widgets/workout_generation_steps.dart

import 'package:flutter/material.dart';
import '../../../common/constants/colors.dart';

class WorkoutGenerationSteps extends StatefulWidget {
  const WorkoutGenerationSteps({super.key});

  @override
  State<WorkoutGenerationSteps> createState() => _WorkoutGenerationStepsState();
}

class _WorkoutGenerationStepsState extends State<WorkoutGenerationSteps> {
  final List<Map<String, dynamic>> _steps = [
    {'text': 'Analyzing your fitness profile...', 'done': false},
    {'text': 'Designing your personalized plan...', 'done': false},
    {'text': 'Optimizing for your goals...', 'done': false},
    {'text': 'Finalizing your workout schedule...', 'done': false},
  ];
  
  int _currentStep = 0;
  
  @override
  void initState() {
    super.initState();
    _startStepAnimation();
  }
  
  void _startStepAnimation() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _steps[_currentStep]['done'] = true;
        _currentStep++;
      });
      
      if (_currentStep < _steps.length) {
        _startStepAnimation();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: _steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: step['done'] 
                      ? Colors.green
                      : index == _currentStep
                          ? AppColors.primaryWineRed.withOpacity(0.7)
                          : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: step['done']
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : index == _currentStep
                          ? const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step['text'],
                  style: TextStyle(
                    color: step['done'] || index == _currentStep
                        ? Colors.black87
                        : Colors.grey[500],
                    fontWeight: index == _currentStep
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}