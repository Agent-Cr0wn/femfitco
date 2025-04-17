import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../common/constants/api_constants.dart';
import '../../../common/constants/colors.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final data = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      };

      final result = await _apiService.post(ApiConstants.loginEndpoint, data);

      // Check if the widget is still mounted before updating state
      if (!mounted) return;

      if (result['success'] == true && result['data'] != null) {
        // Attempt to log in using AuthProvider
        final loginSuccess = await Provider.of<AuthProvider>(context, listen: false)
            .login(result['data']);

        if (!loginSuccess) {
           setState(() {
              _isLoading = false;
              _errorMessage = 'Failed to update login state. Please try again.';
           });
        }
        // Navigation is handled by go_router redirect based on AuthProvider state change
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['message'] ?? 'Login failed. Please check your credentials.';
        });
      }
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Login')), // Optional AppBar
      body: SafeArea( // Ensure content isn't under status bar/notches
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
                    // Logo Placeholder
                    const Icon(Icons.fitness_center, size: 60, color: AppColors.primaryWineRed),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome Back to FemFit!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

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
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _isLoading ? null : _login(), // Login on Done/Enter
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        // Optional: Add length check if desired (backend should enforce)
                        // if (value.length < 6) {
                        //   return 'Password must be at least 6 characters';
                        // }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8), // Space for error message
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

                    // Login Button
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                               padding: const EdgeInsets.symmetric(vertical: 14)),
                            child: const Text('Login'),
                          ),
                    const SizedBox(height: 20),

                    // Link to Register Screen
                    TextButton(
                      onPressed: _isLoading ? null : () => context.go('/register'),
                      child: const Text('Don\'t have an account? Register Now'),
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