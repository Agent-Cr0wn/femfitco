import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Ensure this import is present
import '../../../services/api_service.dart';
import '../../../common/constants/api_constants.dart';
import '../../../common/constants/colors.dart';
import '../../auth/providers/auth_provider.dart';


class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _loadingPlan;
  String? _errorMessage;

  Future<void> _processSubscription(String planType) async {
    setState(() { _isLoading = true; _loadingPlan = planType; _errorMessage = null; });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    final token = authProvider.token;

    if (userId == null || token == null) {
      setState(() { _errorMessage = "Authentication error."; _isLoading = false; _loadingPlan = null; });
       ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text("Authentication error."), backgroundColor: AppColors.errorRed), );
      return;
    }

    final data = { 'user_id': userId, 'plan_type': planType, 'transaction_id': 'simulated_${DateTime.now().millisecondsSinceEpoch}', };
    final result = await _apiService.post( ApiConstants.processSubscriptionEndpoint, data, token: token, );

    if (!mounted) return;

    if (result['success'] == true) {
      DateTime endDate = DateTime.now();
       switch (planType) {
         case '1m': endDate = DateTime(endDate.year, endDate.month + 1, endDate.day); break;
         case '3m': endDate = DateTime(endDate.year, endDate.month + 3, endDate.day); break;
         case '6m': endDate = DateTime(endDate.year, endDate.month + 6, endDate.day); break;
       }
       // Use DateFormat correctly
       final formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

      authProvider.updateSubscriptionStatus('active', formattedEndDate);
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text('Subscription Successful!'), backgroundColor: AppColors.successGreen,), );
      context.go('/workout');
    } else {
      setState(() { _errorMessage = result['message'] ?? 'Error activating subscription.'; _isLoading = false; _loadingPlan = null; });
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(_errorMessage!), backgroundColor: AppColors.errorRed), );
    }
     // Ensure loading state reset
     if (mounted) {
       setState(() { _isLoading = false; _loadingPlan = null; });
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
         leading: IconButton( icon: const Icon(Icons.arrow_back), onPressed: () { if (context.canPop()) { context.pop(); } else { context.go('/profile'); } }, ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.workspace_premium_outlined, size: 60, color: AppColors.accentWineRed),
               const SizedBox(height: 16),
              Text( 'Unlock Personalized Plans', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primaryWineRed, fontWeight: FontWeight.bold), textAlign: TextAlign.center, ),
               const SizedBox(height: 8),
               Text( 'Get AI-powered workout and nutrition plans tailored just for you.', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center, ),
              const SizedBox(height: 30),
              _buildPlanOption(context, '1 Month', '\$19.99', 'Access for one month', '1m'),
              const SizedBox(height: 16),
              _buildPlanOption(context, '3 Months', '\$49.99', 'Save 15% - Billed quarterly', '3m'),
              const SizedBox(height: 16),
              _buildPlanOption(context, '6 Months', '\$89.99', 'Best Value! Save 25%', '6m'),
              const SizedBox(height: 30),
              if (_errorMessage != null) Padding( padding: const EdgeInsets.only(bottom: 16.0), child: Text( _errorMessage!, style: const TextStyle(color: AppColors.errorRed), textAlign: TextAlign.center, ), ),
              Text( 'Payment simulation only. In a real app, you would be charged via a secure payment gateway. Manage subscriptions in your profile.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]), textAlign: TextAlign.center, ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanOption(BuildContext context, String title, String price, String description, String planType) {
    final bool isProcessing = _isLoading && _loadingPlan == planType;
    return Card(
      elevation: isProcessing ? 1 : 4,
      shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(12), side: BorderSide( color: isProcessing ? AppColors.primaryWineRed : Colors.transparent, width: 1.5 ) ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isLoading ? null : () => _processSubscription(planType),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded( child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text( title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primaryWineRed, fontWeight: FontWeight.bold) ),
              const SizedBox(height: 4), Text(price, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4), Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])), ], ), ),
            const SizedBox(width: 16),
            isProcessing ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)) : const Icon(Icons.arrow_forward_ios, color: AppColors.primaryGrey, size: 18),
          ],),
        ),
      ),
    );
  }
}