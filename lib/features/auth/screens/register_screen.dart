import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import '../../../common/constants/api_constants.dart';
import '../../../common/constants/colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus(); // Hide keyboard

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final data = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      };

      final result = await _apiService.post(ApiConstants.registerEndpoint, data);

      if (!mounted) return; // Check if widget is still mounted

      if (result['success'] == true) {
        // Show success message and navigate to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please login.'),
            backgroundColor: AppColors.successGreen,
            duration: Duration(seconds: 3),
          ),
        );
        // GoRouter redirect should handle moving away if already logged in,
        // but explicitly going to login is clearer after registration.
        context.go('/login');
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['message'] ?? 'Registration failed. Please try again.';
        });
      }
    }
  }

   void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }
   void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         title: const Text('Create Account'),
         elevation: 0, // Flat app bar
         backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Match background
         foregroundColor: AppColors.primaryGrey, // Icons/text color
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                     Text(
                      'Join FemFit Collective',
                       style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                     const SizedBox(height: 8),
                      Text(
                      'Start your personalized fitness journey.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.primaryGrey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                        hintText: 'Your Name',
                      ),
                       textInputAction: TextInputAction.next,
                       textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                         if (value.trim().length < 2) {
                          return 'Name seems too short';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                       decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'your.email@example.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                         if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                     // Password Field
                    TextFormField(
                      controller: _passwordController,
                       decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                         suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                      ),
                      obscureText: _obscurePassword,
                       textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        // Enforce minimum length (should match backend)
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        // Optional: Add complexity checks (e.g., number, uppercase)
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                       decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                         suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          ),
                          onPressed: _toggleConfirmPasswordVisibility,
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _isLoading ? null : _register(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                     const SizedBox(height: 8),
                    // Display error message
                    if (_errorMessage != null)
                       Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.errorRed),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Register Button
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _register,
                             style: ElevatedButton.styleFrom(
                               padding: const EdgeInsets.symmetric(vertical: 14)),
                            child: const Text('Register'),
                          ),
                    const SizedBox(height: 20),

                     // Link to Login Screen
                    TextButton(
                      onPressed: _isLoading ? null : () => context.go('/login'),
                      child: const Text('Already have an account? Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}