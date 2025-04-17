import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // Ensure this import is present and package added
import '../../auth/providers/auth_provider.dart';
import '../../../common/constants/colors.dart';
// Removed unused import: import '../../../models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat.yMMMd().format(date); // Use DateFormat from intl
    } catch (e) {
      return dateString;
    }
  }

  String _formatSubscriptionStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active': return 'Active';
      case 'expired': return 'Expired';
      case 'cancelled': return 'Cancelled';
      case 'none':
      default: return 'Not Subscribed';
    }
  }

  Future<void> _logout(BuildContext context) async {
     final confirm = await showDialog<bool>(
        context: context, // Context passed to showDialog is fine
        builder: (BuildContext dialogContext) => AlertDialog( // Use dialogContext inside builder
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
             TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
             ),
             TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Logout'),
             ),
          ],
        ),
     );

     // Check mounted status *after* the await
     if (confirm == true && context.mounted) {
        await context.read<AuthProvider>().logout();
     }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: RefreshIndicator(
        onRefresh: () async {
          // Use context.read inside the async callback
           await context.read<AuthProvider>().tryAutoLogin();
        },
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
             Column(
                children: [
                   CircleAvatar(
                    radius: 50,
                    // Fix deprecated withOpacity
                    backgroundColor: AppColors.primaryWineRed.withAlpha((255 * 0.8).round()),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
             ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),
            _buildProfileInfoTile(
               context: context, icon: Icons.badge_outlined, title: 'Member ID', value: user.id.toString()),
             _buildProfileInfoTile(
               context: context, icon: Icons.person_outline, title: 'Full Name', value: user.name),
             _buildProfileInfoTile(
               context: context, icon: Icons.email_outlined, title: 'Email Address', value: user.email),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            _buildProfileInfoTile(
              context: context,
              icon: Icons.card_membership_outlined,
              title: 'Subscription',
              value: _formatSubscriptionStatus(user.subscriptionStatus),
              trailing: user.subscriptionStatus != 'active'
                ? ElevatedButton(
                     onPressed: () => context.go('/subscribe'),
                     style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        textStyle: const TextStyle(fontSize: 12),
                         backgroundColor: AppColors.accentWineRed,
                     ),
                     child: const Text('Subscribe'),
                  ) : null,
            ),
            if (user.subscriptionStatus == 'active' && user.subscriptionEndDate != null)
              Padding(
                 padding: const EdgeInsets.only(left: 72.0, bottom: 16.0),
                 child: Text(
                   'Expires on: ${_formatDate(user.subscriptionEndDate)}',
                   style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                 ),
               ),
             const SizedBox(height: 10),
            const Divider(),
             const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Logout'),
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGrey,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)
                ),
              ),
            ),
             const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoTile({ required BuildContext context, required IconData icon, required String title, required String value, Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryWineRed, size: 28),
      title: Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
      subtitle: Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.3)),
      trailing: trailing,
       dense: true,
       contentPadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
    );
  }
}