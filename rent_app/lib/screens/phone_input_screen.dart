import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../services/auth_service.dart';
import 'otp_verification_screen.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _fullPhoneNumber = '';
  bool _isLoading = false;
  bool _isValidPhone = false;

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
                      'Enter Your Phone Number',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We\'ll send you a verification code',
                      style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 40),

                    // Phone Number Field
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isValidPhone
                              ? const Color(0xFFFFD700)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: IntlPhoneField(
                        controller: _phoneController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        dropdownTextStyle: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.transparent,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        initialCountryCode: 'US',
                        onChanged: (phone) {
                          setState(() {
                            _fullPhoneNumber = phone.completeNumber;
                            // More lenient validation - just check if we have a reasonable length
                            _isValidPhone =
                                phone.number.length >= 7 &&
                                _fullPhoneNumber.isNotEmpty;
                          });
                          print(
                            'Phone: ${phone.completeNumber}, Number: ${phone.number}, Length: ${phone.number.length}',
                          ); // Debug print
                        },
                        dropdownIcon: const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFFFFD700),
                        ),
                        flagsButtonPadding: const EdgeInsets.all(8),
                        showDropdownIcon: true,
                        dropdownDecoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        searchText: 'Search Country',
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            (_isValidPhone || _fullPhoneNumber.length > 8) &&
                                !_isLoading
                            ? _sendVerificationCode
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              (_isValidPhone || _fullPhoneNumber.length > 8)
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
                            : const Text(
                                'Send Verification Code',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Terms and conditions
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        children: const [
                          TextSpan(text: 'By continuing, you agree to our '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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

  Future<void> _sendVerificationCode() async {
    if (_fullPhoneNumber.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('Attempting to send verification code to: $_fullPhoneNumber');

      // Check if phone is already registered (simplified for testing)
      final isRegistered = await AuthService.isPhoneRegistered(
        _fullPhoneNumber,
      );
      print('Phone registration check completed. Is registered: $isRegistered');

      // Send verification code
      print('Sending SMS verification...');
      final verificationId = await AuthService.sendSMSVerification(
        _fullPhoneNumber,
      );
      print('SMS verification result: $verificationId');

      if (verificationId != null && verificationId.isNotEmpty) {
        print('Navigating to OTP screen with verificationId: $verificationId');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(
              phoneNumber: _fullPhoneNumber,
              verificationId: verificationId,
              isExistingUser: isRegistered,
            ),
          ),
        );
      } else {
        print('No verification ID received');
        _showErrorDialog(
          'Failed to send verification code. Please check your phone number and try again.',
        );
      }
    } catch (e) {
      print('Error in _sendVerificationCode: $e');
      String errorMessage = 'An error occurred. Please try again.';

      if (e.toString().contains('invalid-phone-number')) {
        errorMessage = 'Please enter a valid phone number.';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Too many attempts. Please try again later.';
      } else if (e.toString().contains('quota-exceeded')) {
        errorMessage = 'SMS quota exceeded. Please try again later.';
      }

      _showErrorDialog(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    _phoneController.dispose();
    super.dispose();
  }
}
