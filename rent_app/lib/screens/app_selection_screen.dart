import 'package:flutter/material.dart';
import '../services/google_auth_service.dart';
import 'marketplace_home_screen.dart';

class AppSelectionScreen extends StatelessWidget {
  const AppSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: 5),
                  
                  // Logo and Title Section - Horizontal Layout
                  Row(
                    children: [
                      // Logo Section
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFD700).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/logos/MKPro.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.business,
                                color: Color(0xFFFFD700),
                                size: 30,
                              );
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Title and Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MKPro Apps',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Select Your Service',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // App Options
              Column(
                children: [
                  // Buy App Option (First)
                  _buildAppOption(
                    context: context,
                    title: 'Buy Equipment',
                    subtitle: 'Professional Camera Store',
                    description: 'Purchase new & certified cameras, lenses, and equipment with warranty',
                    icon: Icons.shopping_cart,
                    color: const Color(0xFF4CAF50),
                    isAvailable: true,
                    onTap: () => _handleBuyAppSelection(context),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Rent App Option (Second)
                  _buildAppOption(
                    context: context,
                    title: GoogleAuthService.isLoggedIn
                        ? 'Rent Equipment (${GoogleAuthService.currentUser?.name ?? 'Signed In'})'
                        : 'Rent Equipment',
                    subtitle: 'Professional Rental Service',
                    description: GoogleAuthService.isLoggedIn 
                        ? 'Welcome back! Continue renting professional equipment'
                        : 'Rent cameras, lenses, and equipment for your projects and events',
                    icon: Icons.camera_alt,
                    color: const Color(0xFFFFD700),
                    isAvailable: true,
                    onTap: () => _handleRentAppSelection(context),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Marketplace Option (Third - OLX Style)
                  _buildAppOption(
                    context: context,
                    title: 'Camera Marketplace',
                    subtitle: 'Buy & Sell Community',
                    description: 'Connect with photographers to buy and sell used equipment safely',
                    icon: Icons.storefront,
                    color: const Color(0xFF9C27B0),
                    isAvailable: true,
                    onTap: () => _handleMarketplaceSelection(context),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Training App Option (Fourth)
                  _buildAppOption(
                    context: context,
                    title: 'Photography Training',
                    subtitle: 'Learn & Master Skills',
                    description: 'Professional courses for cameras, drones, and photography techniques',
                    icon: Icons.school,
                    color: const Color(0xFF2196F3),
                    isAvailable: false,
                    onTap: () => _showComingSoon(
                      context,
                      'Photography Training Hub',
                      'Learn & Master Skills',
                      'Coming soon! Comprehensive training courses covering camera techniques, drone operations, photography fundamentals, and advanced skills from industry professionals!'
                    ),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Maintenance App Option (Fifth)
                  _buildAppOption(
                    context: context,
                    title: 'Equipment Maintenance',
                    subtitle: 'Care & Service Center',
                    description: 'Professional maintenance, repair, and care services for your equipment',
                    icon: Icons.build,
                    color: const Color(0xFFFF9800),
                    isAvailable: false,
                    onTap: () => _showComingSoon(
                      context,
                      'Equipment Maintenance Hub',
                      'Care & Service Center',
                      'Coming soon! Professional maintenance services including camera servicing, lens calibration, drone repairs, sensor cleaning, and equipment care guidance!'
                    ),
                  ),
                ],
              ),
              
              // Footer
              Column(
                children: [
                  Text(
                    'You can switch between services anytime',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified,
                        color: const Color(0xFFFFD700),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'All services are secure and verified',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isAvailable 
              ? const Color(0xFF1A1A1A) 
              : const Color(0xFF1A1A1A).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAvailable 
                ? color.withOpacity(0.3) 
                : Colors.grey.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: isAvailable ? [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ] : null,
        ),
        child: Column(
          children: [
            // Icon
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: isAvailable ? color : Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
            ),
            
            const SizedBox(height: 6),
            
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isAvailable ? Colors.white : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 1),
            
            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isAvailable ? color : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 2),
            
            // Description
            Text(
              description,
              style: TextStyle(
                fontSize: 9,
                color: isAvailable ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            if (!isAvailable) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 8,
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
      if (GoogleAuthService.isLoggedIn) {
        // User is already signed in, go directly to main app
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // User is not signed in, show guest/sign-in options
        _showRentAppOptions(context);
      }
    });
  }

  void _handleBuyAppSelection(BuildContext context) {
    // Show loading indicator while checking authentication
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
        ),
      ),
    );

    // Small delay to show loading (better UX)
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pop(context); // Close loading dialog
      
      // Check if user is already authenticated
      if (GoogleAuthService.isLoggedIn) {
        // User is already signed in, go directly to buy app
        Navigator.pushReplacementNamed(context, '/buy-app-home');
      } else {
        // User is not signed in, show guest/sign-in options
        _showBuyAppOptions(context);
      }
    });
  }

  void _handleMarketplaceSelection(BuildContext context) {
    // Show loading indicator while checking authentication
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
        ),
      ),
    );

    // Small delay to show loading (better UX)
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pop(context); // Close loading dialog
      
      // Navigate to marketplace (authentication handled within marketplace)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MarketplaceHomeScreen(),
        ),
      );
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

  void _showBuyAppOptions(BuildContext context) {
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
                'Choose how to access Buy App',
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
                subtitle: 'View cameras without signing in',
                icon: Icons.visibility,
                color: const Color(0xFF4CAF50),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/buy-app-guest');
                },
              ),
              
              const SizedBox(height: 12),
              
              // Sign In Option
              _buildAccessOption(
                context: context,
                title: 'Sign In to Buy',
                subtitle: 'Access all features and purchase cameras',
                icon: Icons.login,
                color: const Color(0xFF4CAF50),
                onTap: () {
                  Navigator.pop(context);
                  _selectApp(context, 'buy');
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
      if (GoogleAuthService.isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    } else if (appType == 'buy') {
      // Navigate to buy app
      if (GoogleAuthService.isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/buy-app-home');
      } else {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    }
  }

  void _showComingSoon(BuildContext context, [String? title, String? subtitle, String? message]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Row(
          children: [
            Icon(
              Icons.access_time,
              color: Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title ?? 'Coming Soon',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null) ...[
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              message ?? 'This feature is currently under development. Stay tuned for updates!',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'We\'ll notify you when this feature launches!',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it!',
              style: TextStyle(color: Color(0xFFFFD700)),
            ),
          ),
        ],
      ),
    );
  }
}
