import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool _isValidMobileNumber(String phone) {
    // Remove any spaces or special characters except +
    String cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it starts with +91 (with country code)
    if (cleanPhone.startsWith('+91')) {
      // Should have exactly 13 characters (+91 + 10 digits)
      return RegExp(r'^\+91[6-9]\d{9}$').hasMatch(cleanPhone);
    } else {
      // Without country code, should have exactly 10 digits starting with 6-9
      return RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone);
    }
  }

  String _formatPhoneNumber(String phone) {
    // Remove any spaces or special characters except +
    String cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // If already has +91, return as is
    if (cleanPhone.startsWith('+91')) {
      return cleanPhone;
    }

    // Add +91 prefix
    return '+91$cleanPhone';
  }

  Future<void> _handleContinue() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      _showErrorSnackBar('Please enter a phone number');
      return;
    }

    // Validate mobile number
    if (!_isValidMobileNumber(phone)) {
      _showErrorSnackBar('Please enter a valid 10-digit mobile number');
      return;
    }

    // Format the phone number with +91 if not present
    final formattedPhone = _formatPhoneNumber(phone);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(formattedPhone); // This now sends OTP

    if (!mounted) return;

    if (success) {
      // Navigate to OTP screen instead of KYC
      Navigator.pushNamed(
        context,
        '/otp',
        arguments: formattedPhone, // Pass formatted phone number to OTP screen
      );
    } else {
      _showErrorSnackBar(authProvider.error ?? "Failed to send OTP");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: Stack(
        children: [
          /// Background tailor image
          Positioned.fill(
            child: Image.asset(
              "assets/images/tailor.png",
              fit: BoxFit.cover,
            ),
          ),

          /// Dark gradient overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xFF1A0F08),
                  ],
                ),
              ),
            ),
          ),

          /// Main content
          Column(
            children: [
              const Spacer(),

              /// App name + tagline
              Column(
                children: [
                  Text(
                    "CASA DARZI",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "WHERE STYLE COMES HOME",
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// Login form section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Text(
                        'Login/Sign Up',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Phone Number',
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _phoneController,
                        style: GoogleFonts.lato(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter phone number',
                          hintStyle: GoogleFonts.lato(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// Continue button
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF5252),
                            Color(0xFFFF1744),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF1744).withOpacity(0.3),
                            blurRadius: 15,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          'Continue',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleIcon() => _buildFallbackGoogleIcon();
  Widget _buildAppleIcon() => _buildFallbackAppleIcon();

  Widget _buildFallbackGoogleIcon() {
    return Container(
      width: 24,
      height: 24,
      color: Colors.white,
      child: Center(
        child: Text(
          "G",
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAppleIcon() =>
      const Icon(Icons.apple, color: Colors.white, size: 24);

  Widget _buildSocialButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}