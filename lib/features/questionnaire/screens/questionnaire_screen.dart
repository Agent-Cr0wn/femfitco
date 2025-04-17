import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../common/constants/api_constants.dart';
//import '../../../common/constants/colors.dart';
import '../../auth/providers/auth_provider.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;

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

  // Options 
  final List<String> _ageRanges = ['18-24', '25-34', '35-44', '45-54', '55+'];
  final List<String> _frequencies = ['1-2 days/week', '3 days/week', '4 days/week', '5+ days/week'];
  final List<String> _times = ['< 30min', '30-45min', '45-60min', '60+min'];
  final List<String> _goals = ['Lose Weight', 'Build Muscle', 'Improve Tone/Definition', 'Increase Strength', 'Improve Endurance', 'General Fitness', 'Wellness/Flexibility', 'Postpartum Recovery'];
  final List<String> _builds = ['Slim', 'Average', 'Curvy', 'Athletic', 'Other'];
  final List<String> _shapes = ['Rectangle', 'Triangle (Pear)', 'Inverted Triangle', 'Hourglass', 'Round (Apple)', 'Unsure'];
  final List<String> _dreamBodies = ['Lean & Toned', 'Strong & Athletic', 'Defined Muscles', 'Curvy & Fit', 'Improved Wellness', 'Other'];
  final List<String> _allEquipment = ['Bodyweight Only', 'Dumbbells', 'Barbell', 'Resistance Bands', 'Kettlebells', 'Gym Machines', 'Cardio Machines', 'Yoga Mat', 'None Available'];
  final List<String> _allMuscles = ['Full Body', 'Legs & Glutes', 'Upper Body', 'Arms', 'Shoulders', 'Back', 'Chest', 'Core', 'Flexibility/Mobility'];

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _bodyFatController.dispose();
    _goalDetailsController.dispose();
    super.dispose();
  }

  // Helper method for dropdown fields
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
      ),
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

  // Helper method for text fields
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
        prefixIcon: icon != null ? Icon(icon) : null,
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

  // Helper method for chip selection fields
  Widget _buildChipSelectionField({
    required String label,
    required List<String> allOptions,
    required List<String> selectedOptions,
    required ValueChanged<String> onChipSelected,
    bool allowMultiple = true,
    String? exclusiveOption,
  }) {
    return FormField<List<String>>(
      initialValue: selectedOptions,
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Please select at least one $label option' : null,
      builder: (FormFieldState<List<String>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
              child: Text(
                '$label*',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: allOptions.map((option) {
                final bool isSelected = selectedOptions.contains(option);
                return ChoiceChip(
                  label: Text(option),
                  selected: isSelected,
                  labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87),
                  selectedColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: Colors.grey[200],
                  shape: StadiumBorder(
                      side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[400]!)),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        if (!allowMultiple) {
                          selectedOptions.clear();
                          selectedOptions.add(option);
                        } else {
                          if (exclusiveOption != null && option == exclusiveOption) {
                            selectedOptions.clear();
                            selectedOptions.add(option);
                          } else {
                            if (exclusiveOption != null) {
                              selectedOptions.remove(exclusiveOption);
                            }
                            if (!selectedOptions.contains(option)) {
                              selectedOptions.add(option);
                            }
                          }
                        }
                      } else {
                        selectedOptions.remove(option);
                      }
                      onChipSelected(option);
                      state.didChange(selectedOptions);
                    });
                  },
                );
              }).toList(),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  // Form submission method
  Future<void> _submitQuestionnaire() async {
  FocusScope.of(context).unfocus();
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
    final responseData = {
      'age': _selectedAgeRange,
      'goal': _selectedGoal,
      'current_shape': _selectedShape,
      'dream_body': _selectedDreamBody,
      'frequency': _selectedFrequency,
      'time_per_session': _selectedTime,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Questionnaire submitted! Generating plan...'),
          backgroundColor: Colors.green,
        ),
      );
      final isSubscribed = authProvider.user?.subscriptionStatus == 'active';
      if (isSubscribed) {
        context.go('/workout');
      } else {
        context.go('/subscribe');
      }
    } else {
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
        content: Text('Please fix the errors above.'),
        backgroundColor: Colors.orange,
      ),
    );
    setState(() {
      _errorMessage = 'Please review the highlighted fields.';
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<AuthProvider>(context, listen: false).user?.name ?? 'User';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Profile'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hi $userName! Let's Personalize Your Plan",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Your answers help create the perfect fitness journey. Fields marked * are required.",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              
              // Form Fields
              _buildDropdownField(
                label: 'Age Range',
                currentValue: _selectedAgeRange,
                items: _ageRanges,
                onChanged: (value) => setState(() => _selectedAgeRange = value),
                validator: (value) => value == null ? 'Please select age range' : null,
              ),
              const SizedBox(height: 16),
              
              _buildDropdownField(
                label: 'Primary Fitness Goal',
                currentValue: _selectedGoal,
                items: _goals,
                onChanged: (value) => setState(() => _selectedGoal = value),
                validator: (value) => value == null ? 'Please select fitness goal' : null,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _goalDetailsController,
                label: 'Specific Goal Details (Optional)',
                hint: 'e.g., Run a 5k, lose 10kg',
                icon: Icons.track_changes,
                isOptional: true,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              _buildDropdownField(
                label: 'How often can you work out?',
                currentValue: _selectedFrequency,
                items: _frequencies,
                onChanged: (value) => setState(() => _selectedFrequency = value),
                validator: (value) => value == null ? 'Please select frequency' : null,
              ),
              const SizedBox(height: 16),
              
              _buildDropdownField(
                label: 'Time per session?',
                currentValue: _selectedTime,
                items: _times,
                onChanged: (value) => setState(() => _selectedTime = value),
                validator: (value) => value == null ? 'Please select time' : null,
              ),
              const SizedBox(height: 16),
              
              _buildChipSelectionField(
                label: 'Available Equipment',
                allOptions: _allEquipment,
                selectedOptions: _selectedEquipment,
                onChipSelected: (_) {},
                exclusiveOption: 'None Available',
              ),
              const SizedBox(height: 16),
              
              _buildChipSelectionField(
                label: 'Muscle Groups to Focus On',
                allOptions: _allMuscles,
                selectedOptions: _selectedMuscles,
                onChipSelected: (_) {},
                exclusiveOption: 'Full Body',
              ),
              const SizedBox(height: 16),
              
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
              const SizedBox(height: 16),
              
              _buildDropdownField(
                label: 'Dream Body/Feeling',
                currentValue: _selectedDreamBody,
                items: _dreamBodies,
                onChanged: (value) => setState(() => _selectedDreamBody = value),
                validator: (value) => value == null ? 'Please select dream body' : null,
              ),
              const SizedBox(height: 16),
              
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
              
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              
              Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Generate My Plan'),
                        onPressed: _submitQuestionnaire,
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 14)),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}