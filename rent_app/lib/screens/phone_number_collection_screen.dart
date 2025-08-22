import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../models/user.dart';
import '../services/google_auth_service.dart';
import 'app_selection_screen.dart';

class PhoneNumberCollectionScreen extends StatefulWidget {
  final AppUser googleUser;

  const PhoneNumberCollectionScreen({
    super.key,
    required this.googleUser,
  });

  @override
  State<PhoneNumberCollectionScreen> createState() => _PhoneNumberCollectionScreenState();
}

class _PhoneNumberCollectionScreenState extends State<PhoneNumberCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String _completePhoneNumber = '';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Black background like app theme
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: const Color(0xFF000000), // Black background
        foregroundColor: Colors.white, // White text
        elevation: 0,
        automaticallyImplyLeading: false, // Prevent going back
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A), // Dark grey like app theme
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD700)), // Yellow border
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: widget.googleUser.photoUrl != null
                          ? NetworkImage(widget.googleUser.photoUrl!)
                          : null,
                      backgroundColor: const Color(0xFFFFD700), // Yellow background
                      child: widget.googleUser.photoUrl == null
                          ? Text(
                              widget.googleUser.name.isNotEmpty
                                  ? widget.googleUser.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black, // Black text on yellow
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.googleUser.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // White text
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.googleUser.email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFFFD700), // Yellow text
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Instructions
              const Text(
                'Add Your Phone Number',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // White text
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please provide your phone number to complete your profile and enable all features.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey, // Grey text
                ),
              ),
              const SizedBox(height: 32),

              // Phone input form
              Form(
                key: _formKey,
                child: IntlPhoneField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFFD700)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFFD700)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A), // Dark grey fill
                  ),
                  style: const TextStyle(color: Colors.white), // White text
                  dropdownTextStyle: const TextStyle(color: Colors.white), // White dropdown text
                  initialCountryCode: 'LB', // Lebanon country code
                  onChanged: (phone) {
                    _completePhoneNumber = phone.completeNumber;
                  },
                  validator: (phone) {
                    if (phone == null || phone.number.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (phone.number.length < 7) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Continue button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Saving...'),
                          ],
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update user profile with phone number
      final success = await GoogleAuthService.updateUserProfile(
        phone: _completePhoneNumber,
      );

      if (success) {
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to app selection screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const AppSelectionScreen(),
            ),
          );
        }
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      print('Error completing registration: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete registration: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
