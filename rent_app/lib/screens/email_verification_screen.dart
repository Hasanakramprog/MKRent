import 'package:flutter/material.dart';
import 'dart:async';
import '../services/email_auth_service.dart';
import '../services/google_auth_service.dart';
import 'app_selection_screen.dart';
import 'phone_number_collection_screen.dart';
import 'welcome_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  
  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _verificationTimer;
  bool _isLoading = false;
  bool _canResendEmail = true;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  
  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startVerificationCheck() {
    _verificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkEmailVerification();
    });
  }

  Future<void> _checkEmailVerification() async {
    try {
      await EmailAuthService.reloadUser();
      
      if (mounted && EmailAuthService.isEmailVerified) {
        _verificationTimer?.cancel();
        
        // Update GoogleAuthService with the verified user
        await GoogleAuthService.reloadCurrentUser();
        
        _showSuccessMessage();
        
        // Navigate to appropriate screen
        if (mounted) {
          if (GoogleAuthService.needsPhoneNumber && GoogleAuthService.currentUser != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PhoneNumberCollectionScreen(
                  googleUser: GoogleAuthService.currentUser!,
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AppSelectionScreen(),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error checking email verification: $e');
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail) return;
    
    setState(() => _isLoading = true);
    
    try {
      await EmailAuthService.sendEmailVerification();
      
      if (mounted) {
        _showSnackBar('Verification email sent successfully!', Colors.green);
        
        // Start cooldown
        setState(() {
          _canResendEmail = false;
          _resendCooldown = 60;
        });
        
        _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _resendCooldown--;
              if (_resendCooldown <= 0) {
                _canResendEmail = true;
                timer.cancel();
              }
            });
          } else {
            timer.cancel();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to send verification email: ${e.toString()}', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessMessage() {
    _showSnackBar('Email verified successfully!', Colors.green);
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await GoogleAuthService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error signing out: ${e.toString()}', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Email verification icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(
                    color: const Color(0xFFFFD700),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.mark_email_unread,
                  size: 60,
                  color: Color(0xFFFFD700),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                'We\'ve sent a verification email to:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Email address
              Text(
                widget.email,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFD700),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Instructions
              Text(
                'Please check your email and click the verification link to continue.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Auto-check note
              Text(
                'We\'ll automatically detect when you\'ve verified your email.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Resend email button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _canResendEmail && !_isLoading ? _resendVerificationEmail : null,
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Icon(Icons.refresh, size: 20),
                  label: Text(
                    _canResendEmail 
                      ? (_isLoading ? 'Sending...' : 'Resend Verification Email')
                      : 'Resend in ${_resendCooldown}s',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canResendEmail ? const Color(0xFFFFD700) : Colors.grey[700],
                    foregroundColor: _canResendEmail ? Colors.black : Colors.grey[500],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Check verification manually button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _checkEmailVerification,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text(
                    'Check Verification Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFD700),
                    side: const BorderSide(color: Color(0xFFFFD700)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Sign out button
              TextButton(
                onPressed: _signOut,
                child: Text(
                  'Sign out and try different account',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Status indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Checking verification status...',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
