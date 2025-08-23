import 'package:flutter/material.dart';
import 'google_signin_screen.dart';
import 'email_signin_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Black background to match app theme
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Spacer to center content
              const Spacer(flex: 2),
              
              // Logo Section - Exactly like GoogleSignInScreen
              Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.only(bottom: 48.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/logos/MKPro.jpg',
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700), // Yellow accent
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.business,
                          size: 60,
                          color: Colors.black,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Welcome Text - Exactly like GoogleSignInScreen structure
              Text(
                'Welcome to MKPro Platform',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // White text on black background
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              Text(
                'Choose your preferred sign-in method to continue',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[300], // Light grey text
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Google Sign-In Button - Primary like in GoogleSignInScreen
              Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD700)), // Yellow border
                  color: const Color(0xFFFFD700), // Yellow background
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GoogleSignInScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.login,
                            size: 24,
                            color: Colors.black,
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black, // Black text on yellow
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Divider - Exactly like GoogleSignInScreen style
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[600])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[600])),
                ],
              ),

              const SizedBox(height: 16),

              // Email Sign-In Button - Secondary option with outlined style
              Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD700)), // Yellow border
                  color: Colors.transparent, // Transparent background for outlined style
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmailSignInScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.email,
                            size: 24,
                            color: Color(0xFFFFD700),
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Continue with Email',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFFFD700), // Yellow text on transparent
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Spacer to maintain center alignment
              const Spacer(flex: 1),

              // Terms and Privacy - Exactly like GoogleSignInScreen
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
