import 'dart:convert';
//import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../../services/api_service.dart';
import '../../../common/constants/api_constants.dart';
import '../../../common/constants/colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/workout_generation_steps.dart';
import '../screens/workout_generation_complete_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final PageController _pageController = PageController();
  late final TabController _tabController;
  final ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  final List<String> _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final Set<String> _selectedDays = {};
  bool _isLoading = false;
  String? _errorMessage;
  int _currentStep = 0;
  final int _totalSteps = 5; // We'll group the form fields into 5 steps
  
  // Animated quote to motivate users
  final List<String> _motivationalQuotes = [
    "The body achieves what the mind believes.",
    "Fitness is not about being better than someone else. It's about being better than you used to be.",
    "The only bad workout is the one that didn't happen.",
    "Your body can stand almost anything. It's your mind that you have to convince.",
    "Strength does not come from physical capacity. It comes from an indomitable will.",
  ];
  late int _quoteIndex;

  // Form Data
  String? _selectedAgeRange;
  String? _selectedFrequency;
  String? _selectedTime;
  String? _selectedGoal;
  String? _selectedBuild;
  String? _selectedShape;
  String? _selectedDreamBody;
  final List<String> _selectedEquipment = [];
  final List<String> _selectedMuscles = [];
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _goalDetailsController = TextEditingController();

  // Options with emoji icons to make selection more visual
  final List<Map<String, dynamic>> _ageRanges = [
    {'value': '18-24', 'icon': '🌱'},
    {'value': '25-34', 'icon': '🌿'},
    {'value': '35-44', 'icon': '🪴'},
    {'value': '45-54', 'icon': '🌳'},
    {'value': '55+', 'icon': '🌲'},
  ];
  
  final List<Map<String, dynamic>> _frequencies = [
    {'value': '1-2 days/week', 'icon': '🗓️', 'description': 'Getting started'},
    {'value': '3 days/week', 'icon': '📅', 'description': 'Balanced approach'},
    {'value': '4 days/week', 'icon': '📆', 'description': 'Committed'},
    {'value': '5+ days/week', 'icon': '🔄', 'description': 'Dedicated'},
  ];
  
  final List<Map<String, dynamic>> _times = [
    {'value': '< 30min', 'icon': '⏱️', 'description': 'Quick sessions'},
    {'value': '30-45min', 'icon': '⏲️', 'description': 'Standard workouts'},
    {'value': '45-60min', 'icon': '⏰', 'description': 'Extended training'},
    {'value': '60+min', 'icon': '⌛', 'description': 'Comprehensive sessions'},
  ];
  
  final List<Map<String, dynamic>> _goals = [
    {'value': 'Lose Weight', 'icon': '⚖️', 'description': 'Reduce body fat'},
    {'value': 'Build Muscle', 'icon': '💪', 'description': 'Increase muscle mass'},
    {'value': 'Improve Tone/Definition', 'icon': '✨', 'description': 'Sculpt your body'},
    {'value': 'Increase Strength', 'icon': '🏋️‍♀️', 'description': 'Get stronger'},
    {'value': 'Improve Endurance', 'icon': '🏃‍♀️', 'description': 'Build stamina'},
    {'value': 'General Fitness', 'icon': '🧘‍♀️', 'description': 'Overall wellbeing'},
    {'value': 'Wellness/Flexibility', 'icon': '🤸‍♀️', 'description': 'Improve mobility'},
    {'value': 'Postpartum Recovery', 'icon': '👶', 'description': 'Post-pregnancy journey'},
  ];
  
  final List<String> _builds = ['Slim', 'Average', 'Curvy', 'Athletic', 'Other'];
  final List<String> _shapes = ['Rectangle', 'Triangle (Pear)', 'Inverted Triangle', 'Hourglass', 'Round (Apple)', 'Unsure'];
  final List<String> _dreamBodies = ['Lean & Toned', 'Strong & Athletic', 'Defined Muscles', 'Curvy & Fit', 'Improved Wellness', 'Other'];
  
  // Equipment with icons for visual appeal
  final List<Map<String, dynamic>> _allEquipment = [
    {'value': 'Bodyweight Only', 'icon': Icons.accessibility_new},
    {'value': 'Dumbbells', 'icon': Icons.fitness_center},
    {'value': 'Barbell', 'icon': Icons.linear_scale},
    {'value': 'Resistance Bands', 'icon': Icons.line_style},
    {'value': 'Kettlebells', 'icon': Icons.fiber_manual_record},
    {'value': 'Gym Machines', 'icon': Icons.settings},
    {'value': 'Cardio Machines', 'icon': Icons.directions_run},
    {'value': 'Yoga Mat', 'icon': Icons.rectangle_outlined},
    {'value': 'None Available', 'icon': Icons.do_not_disturb},
  ];
  
  // Muscle groups with body part icons
  final List<Map<String, dynamic>> _allMuscles = [
    {'value': 'Full Body', 'icon': Icons.person},
    {'value': 'Legs & Glutes', 'icon': Icons.airline_seat_legroom_extra},
    {'value': 'Upper Body', 'icon': Icons.accessibility},
    {'value': 'Arms', 'icon': Icons.front_hand},
    {'value': 'Shoulders', 'icon': Icons.architecture},
    {'value': 'Back', 'icon': Icons.airline_seat_flat},
    {'value': 'Chest', 'icon': Icons.favorite},
    {'value': 'Core', 'icon': Icons.crop_square},
    {'value': 'Flexibility/Mobility', 'icon': Icons.accessibility_new},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _totalSteps, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentStep = _tabController.index;
        });
      }
    });
    
    // Initialize with a random quote
    _quoteIndex = DateTime.now().millisecondsSinceEpoch % _motivationalQuotes.length;
    
    // Populate default values for better UX
    _selectedEquipment.add('Bodyweight Only');
    _selectedMuscles.add('Full Body');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    _confettiController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _bodyFatController.dispose();
    _goalDetailsController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Validate current step before proceeding
    bool isCurrentStepValid = true;
    
    // Specific validation for each step
    if (_currentStep == 0) { // Basic Information
      isCurrentStepValid = _selectedAgeRange != null && 
                          _selectedBuild != null && 
                          _selectedShape != null;
      
      if (!isCurrentStepValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all required fields before proceeding'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } 
    else if (_currentStep == 1) { // Goals
      isCurrentStepValid = _selectedGoal != null && 
                          _selectedDreamBody != null;
      
      if (!isCurrentStepValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your fitness goals before proceeding'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } 
    else if (_currentStep == 2) { // Schedule
      isCurrentStepValid = _selectedFrequency != null && 
                          _selectedTime != null && 
                          _selectedDays.isNotEmpty;
      
      if (_selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one day you can exercise'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      if (!isCurrentStepValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete your schedule details before proceeding'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } 
    else if (_currentStep == 3) { // Equipment & Focus
      isCurrentStepValid = _selectedEquipment.isNotEmpty && 
                          _selectedMuscles.isNotEmpty;
      
      if (!isCurrentStepValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your equipment and focus areas'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }
    
    // Navigate to next step if validation passes
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
        _tabController.animateTo(_currentStep);
        
        // Change the motivational quote
        _quoteIndex = (_quoteIndex + 1) % _motivationalQuotes.length;
      });
    } else {
      // On final step, validate final fields before submission
      if (_weightController.text.trim().isEmpty || _heightController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your weight and height'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // Submit questionnaire if all validations pass
      _submitQuestionnaire();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
        _tabController.animateTo(_currentStep);
      });
    }
  }

  // Enhanced card selection for better visual choices
  Widget _buildSelectionCard({
    required String title,
    required String? currentValue,
    required List<Map<String, dynamic>> options,
    required ValueChanged<String?> onChanged,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title*',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final option = options[index];
            final bool isSelected = currentValue == option['value'];
            
            return InkWell(
              onTap: () => onChanged(option['value']),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.primaryWineRed.withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? AppColors.primaryWineRed
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (option['icon'] is String)
                          Text(
                            option['icon'],
                            style: const TextStyle(fontSize: 18),
                          )
                        else if (option['icon'] is IconData)
                          Icon(
                            option['icon'] as IconData,
                            color: isSelected 
                                ? AppColors.primaryWineRed
                                : Colors.grey[700],
                            size: 20,
                          ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            option['value'],
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected 
                                  ? AppColors.primaryWineRed
                                  : Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (option.containsKey('description') && option['description'] != null)
                      Flexible(
                        child: Text(
                          option['description'],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDaySelectionGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Days*',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select specific days you can exercise',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _weekdays.length,
          itemBuilder: (context, index) {
            final day = _weekdays[index];
            final isSelected = _selectedDays.contains(day);
            
            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedDays.remove(day);
                  } else {
                    _selectedDays.add(day);
                  }
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.primaryWineRed.withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? AppColors.primaryWineRed
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primaryWineRed : Colors.black,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        if (_selectedDays.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Please select at least one day',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  // Enhanced dropdown with animations
  Widget _buildDropdownField({
    required String label,
    required String? currentValue,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required FormFieldValidator<String> validator,
    String? hint,
  }) {
    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: InputDecoration(
        labelText: '$label*',
        hintText: hint ?? 'Select an option',
        prefixIcon: const Icon(Icons.arrow_drop_down),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryWineRed),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      icon: const Icon(Icons.expand_more, color: AppColors.primaryWineRed),
      elevation: 2,
      style: TextStyle(color: Colors.grey[800], fontSize: 16),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      items: items
          .map((String value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              ))
          .toList(),
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
    );
  }

  // Enhanced text fields with animated focus effects
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    FormFieldValidator<String>? validator,
    bool isOptional = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isOptional ? label : '$label*',
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: AppColors.primaryGrey) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryWineRed),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      validator: validator ?? 
          (value) {
            if (!isOptional && (value == null || value.trim().isEmpty)) {
              return 'Please enter your $label';
            }
            if (label == 'Current Weight' && value != null && value.trim().isNotEmpty) {
              if (!RegExp(r'^[0-9]+(\.[0-9]+)?\s?(kg|lbs)?$', caseSensitive: false).hasMatch(value.trim())) {
                return 'Enter weight (e.g., 65kg or 143.5lbs)';
              }
            }
            if (label == 'Height' && value != null && value.trim().isNotEmpty) {
              if (!RegExp(r"^\d+(\.\d+)?\s?cm$", caseSensitive: false).hasMatch(value.trim())) {
                return 'Enter height in cm (e.g., 165cm)';
              }
            }
            if (label == 'Body Fat % (Optional)' && value != null && value.trim().isNotEmpty) {
              final percent = double.tryParse(value.trim().replaceAll('%', ''));
              if (percent == null || percent < 0 || percent > 100) {
                return 'Enter a valid percentage (0-100)';
              }
            }
            return null;
          },
    );
  }

  // Enhanced chip selection with animations and icons
  Widget _buildChipSelectionField({
    required String label,
    required List<Map<String, dynamic>> allOptions,
    required List<String> selectedOptions,
    required ValueChanged<String> onChipSelected,
    bool allowMultiple = true,
    String? exclusiveOption,
    String? subtitle,
  }) {
    return FormField<List<String>>(
      initialValue: selectedOptions,
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Please select at least one $label option' : null,
      builder: (FormFieldState<List<String>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label*',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: allOptions.map((option) {
                final bool isSelected = selectedOptions.contains(option['value']);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          option['icon'] as IconData,
                          size: 18,
                          color: isSelected ? Colors.white : AppColors.primaryGrey,
                        ),
                        const SizedBox(width: 6),
                        Text(option['value']),
                      ],
                    ),
                    selected: isSelected,
                    checkmarkColor: Colors.white,
                    selectedColor: AppColors.primaryWineRed,
                    backgroundColor: Colors.grey[100],
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(
                        color: isSelected ? AppColors.primaryWineRed : Colors.grey[400]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          if (!allowMultiple) {
                            selectedOptions.clear();
                            selectedOptions.add(option['value']);
                          } else {
                            if (exclusiveOption != null && option['value'] == exclusiveOption) {
                              selectedOptions.clear();
                              selectedOptions.add(option['value']);
                            } else {
                              if (exclusiveOption != null) {
                                selectedOptions.remove(exclusiveOption);
                              }
                              if (!selectedOptions.contains(option['value'])) {
                                selectedOptions.add(option['value']);
                              }
                            }
                          }
                        } else {
                          selectedOptions.remove(option['value']);
                        }
                        onChipSelected(option['value']);
                        state.didChange(selectedOptions);
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
  
  // Enhanced form with stepper UI
  Widget _buildFormStepper() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  _totalSteps,
                  (index) => _buildStepIndicator(index),
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentStep + 1) / _totalSteps,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryWineRed),
                borderRadius: BorderRadius.circular(10),
                minHeight: 6,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryWineRed.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryWineRed.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: AppColors.accentWineRed,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _motivationalQuotes[_quoteIndex],
                  style: const TextStyle(
                    color: AppColors.primaryGrey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStepIndicator(int step) {
    bool isCompleted = _currentStep > step;
    bool isCurrent = _currentStep == step;
    
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            // Allow jumping to previous steps but not ahead
            if (step <= _currentStep) {
              setState(() {
                _currentStep = step;
                _tabController.animateTo(step);
                _pageController.animateToPage(
                  step,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              });
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.primaryWineRed
                  : isCurrent
                      ? AppColors.primaryWineRed.withOpacity(0.8)
                      : Colors.grey[300],
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrent
                    ? AppColors.primaryWineRed
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: AppColors.primaryWineRed.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isCurrent ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getStepTitle(step),
          style: TextStyle(
            fontSize: 10,
            color: isCurrent ? AppColors.primaryWineRed : Colors.grey[600],
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Basics';
      case 1:
        return 'Goals';
      case 2:
        return 'Schedule';
      case 3:
        return 'Equipment';
      case 4:
        return 'Body';
      default:
        return 'Step ${step + 1}';
    }
  }

  // Form submission method
  // Form submission method with enhanced flow
  Future<void> _submitQuestionnaire() async {
    FocusScope.of(context).unfocus();
    
    // Check for validation errors on the current page
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      final token = authProvider.token;
      
      if (userId == null || token == null) {
        setState(() {
          _errorMessage = "Authentication error.";
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Authentication error."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // Show the workout generation dialog
      showGeneratingWorkoutDialog(context);
      
      final responseData = {
        'age': _selectedAgeRange,
        'goal': _selectedGoal,
        'current_shape': _selectedShape,
        'dream_body': _selectedDreamBody,
        'frequency': _selectedFrequency,
        'time_per_session': _selectedTime,
        'available_days': _selectedDays.toList(), // Add this line
        'equipment': _selectedEquipment,
        'focus_muscles': _selectedMuscles,
        'current_weight': _weightController.text.trim(),
        'height': _heightController.text.trim(),
        if (_bodyFatController.text.trim().isNotEmpty)
          'body_fat_percentage': _bodyFatController.text.trim(),
        if (_goalDetailsController.text.trim().isNotEmpty)
          'specific_goal_details': _goalDetailsController.text.trim(),
        if (_selectedBuild != null) 'current_build': _selectedBuild,
      };
      
      final apiData = {
        'user_id': userId,
        'questionnaire_type': 'fitness',
        'response_data': responseData,
      };
      
      debugPrint("Submitting Questionnaire Data: ${jsonEncode(apiData)}");
      final result = await _apiService.post(
        ApiConstants.submitQuestionnaireEndpoint,
        apiData,
        token: token,
      );
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      if (result['success'] == true) {
        // Start confetti animation
        _confettiController.play();
        
        // Close the generating dialog if it's still showing
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        final isSubscribed = authProvider.user?.subscriptionStatus == 'active';
        
        if (isSubscribed) {
          // Navigate to profile dashboard with transition
          navigateToProfileDashboard(context);
        } else {
          context.go('/subscribe');
        }
      } else {
        // Close the generating dialog if it's still showing
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to submit questionnaire.';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors above before proceeding.'),
          backgroundColor: Colors.orange,
        ),
      );
      
      setState(() {
        _errorMessage = 'Please review the highlighted fields.';
      });
    }
  }

  // Show an engaging "Generating Workout" dialog
  // Show an engaging "Generating Workout" dialog
void showGeneratingWorkoutDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView( // Add this to make content scrollable if needed
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Make sure this is set to min
                children: [
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: LoadingAnimationWidget.staggeredDotsWave(
                      color: AppColors.primaryWineRed,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Getting Your Workout Ready",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryWineRed,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryWineRed),
                    backgroundColor: Color(0xFFE6E6E6),
                  ),
                  const SizedBox(height: 20),
                  const WorkoutGenerationSteps(),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

  // Navigate to profile dashboard with transition animation
  void navigateToProfileDashboard(BuildContext context) {
    // Navigate to the custom transition page first
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 1500),
        pageBuilder: (BuildContext context, _, __) {
          return const WorkoutGenerationCompletePage();
        },
      ),
    );
    
    // After the transition, navigate to the actual dashboard
    Future.delayed(const Duration(milliseconds: 2000), () {
      context.go('/workout');
    });
  }

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<AuthProvider>(context, listen: false).user?.name.split(' ').first ?? 'User';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Profile'),
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
        ],
      ),
      body: Stack(
        children: [
          // Confetti animation overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              shouldLoop: false,
              colors: const [
                AppColors.primaryWineRed,
                AppColors.accentWineRed,
                Colors.pink,
                Colors.deepPurple,
              ],
            ),
          ),
          
          // Main content
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Header section with user greeting
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hi $userName! Let's Create Your Plan",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryWineRed,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Your answers help us create a personalized fitness journey just for you.",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Stepper UI
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildFormStepper(),
                ),
                
                // Page view for form steps
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentStep = index;
                        _tabController.animateTo(index);
                      });
                    },
                    children: [
                      // STEP 1: Basic Information
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSelectionCard(
                              title: 'Age Range',
                              currentValue: _selectedAgeRange,
                              options: _ageRanges,
                              onChanged: (value) => setState(() => _selectedAgeRange = value),
                              subtitle: 'Select your current age group',
                            ),
                            const SizedBox(height: 24),
                            
                            _buildDropdownField(
                              label: 'Current Body Build',
                              currentValue: _selectedBuild,
                              items: _builds,
                              onChanged: (value) => setState(() => _selectedBuild = value),
                              validator: (value) => value == null ? 'Please select body build' : null,
                            ),
                            const SizedBox(height: 16),
                            
                            _buildDropdownField(
                              label: 'Current Body Shape',
                              currentValue: _selectedShape,
                              items: _shapes,
                              onChanged: (value) => setState(() => _selectedShape = value),
                              validator: (value) => value == null ? 'Please select body shape' : null,
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                      
                      // STEP 2: Goals
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSelectionCard(
                              title: 'Primary Fitness Goal',
                              currentValue: _selectedGoal,
                              options: _goals,
                              onChanged: (value) => setState(() => _selectedGoal = value),
                              subtitle: 'What are you aiming to achieve?',
                            ),
                            const SizedBox(height: 20),
                            
                            _buildTextField(
                              controller: _goalDetailsController,
                              label: 'Specific Goal Details (Optional)',
                              hint: 'e.g., Run a 5k, lose 10kg, fit into a size 8',
                              icon: Icons.track_changes,
                              isOptional: true,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            
                            _buildDropdownField(
                              label: 'Dream Body/Feeling',
                              currentValue: _selectedDreamBody,
                              items: _dreamBodies,
                              onChanged: (value) => setState(() => _selectedDreamBody = value),
                              validator: (value) => value == null ? 'Please select dream body' : null,
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                      
                      // STEP 3: Schedule
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSelectionCard(
                              title: 'Workout Frequency',
                              currentValue: _selectedFrequency,
                              options: _frequencies,
                              onChanged: (value) => setState(() => _selectedFrequency = value),
                              subtitle: 'How many days can you commit to exercising?',
                            ),
                            const SizedBox(height: 24),
                            
                            // Add this line to include the day selection grid
                            _buildDaySelectionGrid(),
                            const SizedBox(height: 24),
                            
                            _buildSelectionCard(
                              title: 'Time Per Session',
                              currentValue: _selectedTime,
                              options: _times,
                              onChanged: (value) => setState(() => _selectedTime = value),
                              subtitle: 'How long can you work out each day?',
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                      
                      // STEP 4: Equipment & Focus
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildChipSelectionField(
                              label: 'Available Equipment',
                              allOptions: _allEquipment,
                              selectedOptions: _selectedEquipment,
                              onChipSelected: (_) {},
                              exclusiveOption: 'None Available',
                              subtitle: 'Select all equipment you have access to',
                            ),
                            const SizedBox(height: 24),
                            
                            _buildChipSelectionField(
                              label: 'Muscle Groups to Focus On',
                              allOptions: _allMuscles,
                              selectedOptions: _selectedMuscles,
                              onChipSelected: (_) {},
                              exclusiveOption: 'Full Body',
                              subtitle: 'Select areas you want to prioritize',
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                      
                      // STEP 5: Body Measurements
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Measurements',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryWineRed,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'These help us calculate the right intensity for your workouts',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            _buildTextField(
                              controller: _weightController,
                              label: 'Current Weight',
                              hint: 'e.g., 65kg or 143lbs',
                              icon: Icons.monitor_weight_outlined,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _heightController,
                              label: 'Height',
                              hint: 'e.g., 165cm',
                              icon: Icons.height_outlined,
                              keyboardType: TextInputType.text,
                            ),
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _bodyFatController,
                              label: 'Body Fat % (Optional)',
                              hint: 'Enter % if known',
                              icon: Icons.assessment_outlined,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              isOptional: true,
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Navigation buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        ElevatedButton.icon(
                          onPressed: _previousStep,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: AppColors.primaryGrey,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 85),
                        
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton.icon(
                              onPressed: _nextStep,
                              icon: Icon(
                                _currentStep < _totalSteps - 1
                                    ? Icons.arrow_forward
                                    : Icons.check,
                              ),
                              label: Text(
                                _currentStep < _totalSteps - 1
                                    ? 'Next'
                                    : 'Generate My Plan',
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}