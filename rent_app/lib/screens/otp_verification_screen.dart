import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'user_registration_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final bool isExistingUser;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    required this.isExistingUser,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String _otpCode = '';

  @override
  void initState() {
    super.initState();
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Back button
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                ],
              ),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text(
                          'MK\nPRO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    const Text(
                      'Verification Code',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the 6-digit code sent to',
                      style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.phoneNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // OTP Input Fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        6,
                        (index) => _buildOTPField(index),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _otpCode.length == 6 && !_isLoading
                            ? _verifyOTP
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _otpCode.length == 6
                              ? const Color(0xFFFFD700)
                              : Colors.grey[600],
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.isExistingUser
                                    ? 'Sign In'
                                    : 'Verify & Continue',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Resend Code
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Didn\'t receive the code? ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                        GestureDetector(
                          onTap: _resendCode,
                          child: const Text(
                            'Resend',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOTPField(int index) {
    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _controllers[index].text.isNotEmpty
              ? const Color(0xFFFFD700)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
            }
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }

          _updateOTPCode();
          setState(() {});
        },
      ),
    );
  }

  void _updateOTPCode() {
    _otpCode = _controllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOTP() async {
    if (_otpCode.length != 6) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isExistingUser) {
        // Sign in existing user
        final success = await AuthService.signInWithPhone(
          verificationId: widget.verificationId,
          smsCode: _otpCode,
        );

        if (success) {
          _navigateToHome();
        } else {
          _showErrorDialog('Failed to sign in. Please try again.');
        }
      } else {
        // New user - go to registration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserRegistrationScreen(
              phoneNumber: widget.phoneNumber,
              verificationId: widget.verificationId,
              smsCode: _otpCode,
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Invalid verification code. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendCode() async {
    try {
      final newVerificationId = await AuthService.sendSMSVerification(
        widget.phoneNumber,
      );
      if (newVerificationId != null) {
        // Clear current input
        for (var controller in _controllers) {
          controller.clear();
        }
        _otpCode = '';
        _focusNodes[0].requestFocus();
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent successfully'),
            backgroundColor: Color(0xFF1A1A1A),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to resend code. Please try again.');
    }
  }

  void _navigateToHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => false,
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Error', style: TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
