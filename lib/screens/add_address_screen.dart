// screens/add_address_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({Key? key}) : super(key: key);

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _houseController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _streetController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      if (provider.profile.address != null) {
        _houseController.text = provider.profile.address!.houseFlatBlock ?? '';
        _apartmentController.text = provider.profile.address!.apartmentRoadArea ?? '';
        _streetController.text = provider.profile.address!.streetAndCity ?? '';
      }
    });
  }

  @override
  void dispose() {
    _houseController.dispose();
    _apartmentController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveAddress() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = Provider.of<ProfileProvider>(context, listen: false);

    // Update all address fields
    provider.updateHouseFlatBlock(_houseController.text.trim());
    provider.updateApartmentRoadArea(_apartmentController.text.trim());
    provider.updateStreetAndCity(_streetController.text.trim());

    // Check if address type is selected
    if (provider.profile.address?.addressType == null) {
      _showErrorSnackBar('Please select address type');
      return;
    }

    // Validate address completion
    if (!provider.validateAddress()) {
      _showErrorSnackBar('Please fill all address fields');
      return;
    }

    // Show loading state
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🚀 Starting profile creation process...');

      // This will now:
      // 1. Upload the image first
      // 2. Get the image URL
      // 3. Create the profile with all data including the image URL
      final success = await provider.createProfile();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        _showSuccessSnackBar('Profile created successfully!');

        provider.clearProfileData();
        debugPrint('✅ Profile state cleared after successful creation');
        // Navigate to home page
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        });
      } else {
        _showErrorSnackBar(provider.error ?? 'Failed to create profile');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Address',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Address Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location Icon
                          Center(
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.location_on,
                                size: 35,
                                color: Colors.black87,
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // House/Flat/Block Field
                          const Text(
                            'House/Flat/Block',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _houseController,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              hintText: 'Enter House/Flat/Block',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.red.shade300,
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
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter house/flat/block';
                              }
                              if (value.trim().length < 1) {
                                return 'This field cannot be empty';
                              }
                              return null;
                            },
                            textCapitalization: TextCapitalization.words,
                            onChanged: (value) {
                              Provider.of<ProfileProvider>(context, listen: false)
                                  .updateHouseFlatBlock(value);
                            },
                          ),

                          const SizedBox(height: 24),

                          // Apartment/Road/Area Field
                          const Text(
                            'Apartment/Road/Area',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _apartmentController,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              hintText: 'Enter Apartment/Road/Area',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.red.shade300,
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
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter apartment/road/area';
                              }
                              if (value.trim().length < 2) {
                                return 'Must be at least 2 characters';
                              }
                              return null;
                            },
                            textCapitalization: TextCapitalization.words,
                            onChanged: (value) {
                              Provider.of<ProfileProvider>(context, listen: false)
                                  .updateApartmentRoadArea(value);
                            },
                          ),

                          const SizedBox(height: 24),

                          // Street and City Field
                          const Text(
                            'Street and City',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _streetController,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              hintText: 'Enter Street and City',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.red.shade300,
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
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter street and city';
                              }
                              if (value.trim().length < 3) {
                                return 'Must be at least 3 characters';
                              }
                              return null;
                            },
                            textCapitalization: TextCapitalization.words,
                            onChanged: (value) {
                              Provider.of<ProfileProvider>(context, listen: false)
                                  .updateStreetAndCity(value);
                            },
                          ),

                          const SizedBox(height: 24),

                          // Save Address As
                          const Text(
                            'Save address as',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Consumer<ProfileProvider>(
                            builder: (context, provider, child) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: _buildAddressTypeButton(
                                      'Home',
                                      provider.profile.address?.addressType == 'Home',
                                          () => provider.updateAddressType('Home'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildAddressTypeButton(
                                      'Office',
                                      provider.profile.address?.addressType == 'Office',
                                          () => provider.updateAddressType('Office'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildAddressTypeButton(
                                      'Other',
                                      provider.profile.address?.addressType == 'Other',
                                          () => provider.updateAddressType('Other'),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Save Address Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade300,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Save Address',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressTypeButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade100 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.grey.shade400 : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.black87 : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }
}