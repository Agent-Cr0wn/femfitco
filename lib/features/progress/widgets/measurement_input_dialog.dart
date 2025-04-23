import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/progress_measurement.dart';
import '../providers/progress_provider.dart';
import '../../../common/constants/colors.dart';
import '../../auth/providers/auth_provider.dart';

class MeasurementInputDialog extends StatefulWidget {
  final int userId;
  final ProgressMeasurement? existingMeasurement; // Optional, for editing existing measurements
  
  const MeasurementInputDialog({
    super.key, 
    required this.userId,
    this.existingMeasurement,
  });

  @override
  State<MeasurementInputDialog> createState() => _MeasurementInputDialogState();
}

class _MeasurementInputDialogState extends State<MeasurementInputDialog> {
  final _formKey = GlobalKey<FormState>();
  
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipsController = TextEditingController();
  final _thighsController = TextEditingController();
  final _armsController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    
    // If an existing measurement is provided, populate the form
    if (widget.existingMeasurement != null) {
      _isEditing = true;
      final measurement = widget.existingMeasurement!;
      
      _selectedDate = measurement.date;
      _weightController.text = measurement.weight.toString();
      if (measurement.bodyFatPercentage != null) {
        _bodyFatController.text = measurement.bodyFatPercentage.toString();
      }
      if (measurement.chest != null) {
        _chestController.text = measurement.chest.toString();
      }
      if (measurement.waist != null) {
        _waistController.text = measurement.waist.toString();
      }
      if (measurement.hips != null) {
        _hipsController.text = measurement.hips.toString();
      }
      if (measurement.thighs != null) {
        _thighsController.text = measurement.thighs.toString();
      }
      if (measurement.arms != null) {
        _armsController.text = measurement.arms.toString();
      }
      if (measurement.notes != null) {
        _notesController.text = measurement.notes!;
      }
    }
  }
  
  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    _thighsController.dispose();
    _armsController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryWineRed,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication error. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Create or update measurement object
      final measurement = ProgressMeasurement(
        id: _isEditing ? widget.existingMeasurement!.id : '0', // '0' for new measurements
        userId: widget.userId,
        date: _selectedDate,
        weight: double.parse(_weightController.text),
        bodyFatPercentage: _bodyFatController.text.isNotEmpty
            ? double.parse(_bodyFatController.text)
            : null,
        chest: _chestController.text.isNotEmpty
            ? double.parse(_chestController.text)
            : null,
        waist: _waistController.text.isNotEmpty
            ? double.parse(_waistController.text)
            : null,
        hips: _hipsController.text.isNotEmpty
            ? double.parse(_hipsController.text)
            : null,
        thighs: _thighsController.text.isNotEmpty
            ? double.parse(_thighsController.text)
            : null,
        arms: _armsController.text.isNotEmpty
            ? double.parse(_armsController.text)
            : null,
        notes: _notesController.text.isNotEmpty
            ? _notesController.text
            : null,
      );
      
      // Add measurement to provider
      Provider.of<ProgressProvider>(context, listen: false)
          .addMeasurement(measurement: measurement, token: token)
          .then((success) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing ? 'Measurement updated' : 'Measurement added'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final errorMessage = Provider.of<ProgressProvider>(context, listen: false).errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage ?? 'Failed to save measurement'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        _isEditing ? 'Edit Measurement' : 'Add Measurement',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isEditing ? 'Update your body measurements' : 'Track your progress by adding your measurements',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Date selector
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Date: ${_selectedDate.toLocal().toString().split(' ')[0]}'),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Weight
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)*',
                    hintText: 'e.g., 65.5',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your weight';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Body Fat
                TextFormField(
                  controller: _bodyFatController,
                  decoration: const InputDecoration(
                    labelText: 'Body Fat (%)',
                    hintText: 'e.g., 25.0',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final bodyFat = double.tryParse(value);
                      if (bodyFat == null) {
                        return 'Please enter a valid number';
                      }
                      if (bodyFat < 0 || bodyFat > 100) {
                        return 'Body fat must be between 0 and 100%';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Optional measurements
                const Text(
                  'Body Measurements (cm)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _chestController,
                        decoration: const InputDecoration(
                          labelText: 'Chest',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _waistController,
                        decoration: const InputDecoration(
                          labelText: 'Waist',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _hipsController,
                        decoration: const InputDecoration(
                          labelText: 'Hips',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _thighsController,
                        decoration: const InputDecoration(
                          labelText: 'Thighs',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _armsController,
                  decoration: const InputDecoration(
                    labelText: 'Arms',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'How are you feeling? Any changes?',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('CANCEL'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryWineRed,
                      ),
                      child: Text(_isEditing ? 'UPDATE' : 'SAVE'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}