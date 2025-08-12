import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AppSelectionScreen extends StatelessWidget {
  const AppSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 40,
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Logo Section
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Color(0xFFFFD700),
                    size: 50,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                const Text(
                  'MKPro Business',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  'Choose your business model',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // App Options
                Column(
                  children: [
                    // Rent App Option
                    _buildAppOption(
                      context: context,
                      title: AuthService.isLoggedIn 
                          ? 'Rent App (${AuthService.currentUser?.name ?? 'Signed In'})'
                          : 'Rent App',
                      subtitle: 'Camera & Equipment Rental',
                      description: AuthService.isLoggedIn 
                          ? 'Welcome back! Continue renting equipment'
                          : 'Rent out cameras, lenses, and equipment to customers',
                      icon: Icons.camera_alt,
                      color: const Color(0xFFFFD700),
                      isAvailable: true,
                      onTap: () => _handleRentAppSelection(context),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Buy App Option
                    _buildAppOption(
                      context: context,
                      title: 'Buy App',
                      subtitle: 'Camera & Equipment Store',
                      description: 'Buy cameras, lenses, and equipment directly from store',
                      icon: Icons.shopping_cart,
                      color: const Color(0xFF4CAF50),
                      isAvailable: false,
                      onTap: () => _showComingSoon(context),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Footer
                Text(
                  'You can switch between apps anytime',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    required bool isAvailable,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAvailable 
              ? const Color(0xFF1A1A1A) 
              : const Color(0xFF1A1A1A).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAvailable 
                ? color.withOpacity(0.3) 
                : Colors.grey.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: isAvailable ? [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Column(
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isAvailable ? color : Colors.grey,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 30,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isAvailable ? Colors.white : Colors.grey,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isAvailable ? color : Colors.grey,
              ),
            ),
            
            const SizedBox(height: 6),
            
            // Description
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: isAvailable ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            if (!isAvailable) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleRentAppSelection(BuildContext context) {
    // Show loading indicator while checking authentication
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
        ),
      ),
    );

    // Small delay to show loading (better UX)
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pop(context); // Close loading dialog
      
      // Check if user is already authenticated
      if (AuthService.isLoggedIn) {
        // User is already signed in, go directly to main app
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // User is not signed in, show guest/sign-in options
        _showRentAppOptions(context);
      }
    });
  }

  void _showRentAppOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                'Choose how to access Rent App',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Browse as Guest Option
              _buildAccessOption(
                context: context,
                title: 'Browse as Guest',
                subtitle: 'View products without signing in',
                icon: Icons.visibility,
                color: const Color(0xFF4CAF50),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/guest-home');
                },
              ),
              
              const SizedBox(height: 12),
              
              // Sign In Option
              _buildAccessOption(
                context: context,
                title: 'Sign In to Rent',
                subtitle: 'Access all features and rent products',
                icon: Icons.login,
                color: const Color(0xFFFFD700),
                onTap: () {
                  Navigator.pop(context);
                  _selectApp(context, 'rent');
                },
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccessOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _selectApp(BuildContext context, String appType) {
    // Save the selected app type for future reference
    // You can store this in SharedPreferences or similar
    
    if (appType == 'rent') {
      // Navigate to rent app (existing home screen)
      if (AuthService.isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    }
  }

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Coming Soon',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'The Buy App is currently under development. Soon you\'ll be able to purchase cameras, lenses, and equipment directly from our store!',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFFFFD700)),
            ),
          ),
        ],
      ),
    );
  }
}
