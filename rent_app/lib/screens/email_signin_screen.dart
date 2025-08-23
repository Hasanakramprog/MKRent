import 'package:flutter/material.dart';
import '../services/email_auth_service.dart';
import '../services/google_auth_service.dart';
import '../models/user.dart';
import 'app_selection_screen.dart';
import 'phone_number_collection_screen.dart';

class EmailSignInScreen extends StatefulWidget {
  const EmailSignInScreen({super.key});

  @override
  State<EmailSignInScreen> createState() => _EmailSignInScreenState();
}

class _EmailSignInScreenState extends State<EmailSignInScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isSignUp = false; // false for Sign In, true for Sign Up
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Animation controllers
  late AnimationController _formAnimationController;
  late AnimationController _titleAnimationController;
  late Animation<double> _formAnimation;
  late Animation<double> _titleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _titleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _formAnimation = CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeInOut,
    );
    
    _titleAnimation = CurvedAnimation(
      parent: _titleAnimationController,
      curve: Curves.easeInOut,
    );

    // Start animations
    _titleAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _formAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    _formAnimationController.dispose();
    _titleAnimationController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _formKey.currentState?.reset();
    });
    
    // Reset form animation
    _formAnimationController.reset();
    _formAnimationController.forward();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      AppUser? user;
      
      if (_isSignUp) {
        // Sign Up
        user = await EmailAuthService.signUpWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
        );
        
        if (user != null && mounted) {
          _showSnackBar('Account created successfully!', Colors.green);
          
          // Send email verification (optional, but don't require it)
          try {
            await EmailAuthService.sendEmailVerification();
          } catch (e) {
            print('Email verification failed but continuing: $e');
          }
          
          // Continue to app without requiring verification
        }
      } else {
        // Sign In
        user = await EmailAuthService.signInWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (user != null && mounted) {
        // Update GoogleAuthService with the user (no email verification check)
        await GoogleAuthService.reloadCurrentUser();
        
        if (GoogleAuthService.needsPhoneNumber && GoogleAuthService.currentUser != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PhoneNumberCollectionScreen(googleUser: GoogleAuthService.currentUser!),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AppSelectionScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString(), Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      _showSnackBar('Please enter your email address first', Colors.orange);
      return;
    }

    try {
      setState(() => _isLoading = true);
      await EmailAuthService.resetPassword(_emailController.text.trim());
      _showSnackBar('Password reset email sent!', Colors.green);
    } catch (e) {
      _showSnackBar(e.toString(), Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Title Section
              AnimatedBuilder(
                animation: _titleAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _titleAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, 50 * (1 - _titleAnimation.value)),
                      child: Column(
                        children: [
                          // Back Button
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Color(0xFFFFD700),
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Logo/Title
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFFD700).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _isSignUp ? Icons.person_add : Icons.email,
                                  color: const Color(0xFFFFD700),
                                  size: 40,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _isSignUp ? 'Create Account' : 'Welcome Back',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isSignUp 
                                    ? 'Join MKPro today' 
                                    : 'Sign in to your account',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              // Form Section
              AnimatedBuilder(
                animation: _formAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _formAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - _formAnimation.value)),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Name Field (only for sign up)
                            if (_isSignUp) ...[
                              _buildTextField(
                                controller: _nameController,
                                label: 'Full Name',
                                icon: Icons.person,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Name is required';
                                  }
                                  if (value.trim().length < 2) {
                                    return 'Name must be at least 2 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Email Field
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Email is required';
                                }
                                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                if (!emailRegex.hasMatch(value)) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Password Field
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required';
                                }
                                if (_isSignUp && value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Confirm Password Field (only for sign up)
                            if (_isSignUp) ...[
                              _buildTextField(
                                controller: _confirmPasswordController,
                                label: 'Confirm Password',
                                icon: Icons.lock_outline,
                                obscureText: _obscureConfirmPassword,
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                ),
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
                              const SizedBox(height: 24),
                            ],
                            
                            // Forgot Password (only for sign in)
                            if (!_isSignUp) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: _isLoading ? null : _resetPassword,
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: Color(0xFFFFD700),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            
                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD700),
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                      ),
                                    )
                                  : Text(
                                      _isSignUp ? 'Create Account' : 'Sign In',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Toggle Mode
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isSignUp 
                                    ? 'Already have an account? '
                                    : 'Don\'t have an account? ',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _isLoading ? null : _toggleMode,
                                  child: Text(
                                    _isSignUp ? 'Sign In' : 'Sign Up',
                                    style: const TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: const Color(0xFFFFD700)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFFFD700),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
      ),
    );
  }
}
