// screens/add_address_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../services/address_service.dart';
import '../services/auth_service.dart';
import '../models/address_model.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({Key? key}) : super(key: key);

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _mobileController = TextEditingController();
  final AddressService _addressService = AddressService();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _profileId;
  String? _selectedAddressType;
  bool _isDefaultAddress = false;
  bool _isFromAddressList = false;
  bool _isEditMode = false;
  AddressModel? _editingAddress;
  bool _hasChanges = false;

  // Store original values to detect changes
  String? _originalStreet;
  String? _originalCity;
  String? _originalState;
  String? _originalPincode;
  String? _originalMobile;
  String? _originalAddressType;
  bool? _originalIsDefault;

  @override
  void initState() {
    super.initState();

    // Add listeners to detect changes
    _streetController.addListener(_checkForChanges);
    _cityController.addListener(_checkForChanges);
    _stateController.addListener(_checkForChanges);
    _pincodeController.addListener(_checkForChanges);
    _mobileController.addListener(_checkForChanges);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args != null && args is Map) {
        if (args['mode'] == 'edit' && args['address'] != null) {
          // Edit mode
          final address = args['address'] as AddressModel;
          setState(() {
            _isEditMode = true;
            _editingAddress = address;
            _isFromAddressList = true;

            // Populate fields
            _streetController.text = address.street;
            _cityController.text = address.city;
            _stateController.text = address.state;
            _pincodeController.text = address.pincode;
            _mobileController.text = address.mobile;
            _selectedAddressType = _formatAddressTypeForDisplay(address.addressType);
            _isDefaultAddress = address.isDefault;

            // Store original values
            _originalStreet = address.street;
            _originalCity = address.city;
            _originalState = address.state;
            _originalPincode = address.pincode;
            _originalMobile = address.mobile;
            _originalAddressType = _formatAddressTypeForDisplay(address.addressType);
            _originalIsDefault = address.isDefault;
          });
          debugPrint('✏️ Editing address: ${address.id}');
        } else if (args['fromAddressList'] == true) {
          // Add new from address list
          setState(() {
            _isFromAddressList = true;
          });
          debugPrint('🔄 Opening add address from address list - fresh state');
        }
      } else if (args is String) {
        // Original onboarding flow with profile ID
        setState(() {
          _profileId = args;
        });
        debugPrint('📋 Received profile ID: $_profileId');
      }
    });
  }

  void _checkForChanges() {
    if (!_isEditMode) return;

    final hasChanges = _streetController.text != _originalStreet ||
        _cityController.text != _originalCity ||
        _stateController.text != _originalState ||
        _pincodeController.text != _originalPincode ||
        _mobileController.text != _originalMobile ||
        _selectedAddressType != _originalAddressType ||
        _isDefaultAddress != _originalIsDefault;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  String _formatAddressTypeForDisplay(String type) {
    return type[0].toUpperCase() + type.substring(1).toLowerCase();
  }

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _handleUnauthorizedError() async {
    await _authService.clearSession();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session expired. Please login again.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
          (Route<dynamic> route) => false,
    );
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

    if (_selectedAddressType == null) {
      _showErrorSnackBar('Please select address type');
      return;
    }

    // Validate all fields are filled
    if (_streetController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _stateController.text.trim().isEmpty ||
        _pincodeController.text.trim().isEmpty ||
        _mobileController.text.trim().isEmpty) {
      _showErrorSnackBar('Please fill all address fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🚀 ${_isEditMode ? "Updating" : "Saving"} address...');

      dynamic response;

      if (_isEditMode && _editingAddress != null) {
        // Validate that we have an address ID
        final addressId = _editingAddress!.id;
        if (addressId == null || addressId.isEmpty) {
          throw Exception('Invalid address ID');
        }

        // Update existing address
        response = await _addressService.updateAddress(
          addressId: addressId,
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          pincode: _pincodeController.text.trim(),
          mobile: _mobileController.text.trim(),
          addressType: _selectedAddressType!.toLowerCase(),
          label: '',
          isDefault: _isDefaultAddress,
        );
      } else {
        // Add new address
        response = await _addressService.addAddress(
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          pincode: _pincodeController.text.trim(),
          mobile: _mobileController.text.trim(),
          addressType: _selectedAddressType!.toLowerCase(),
          label: '',
          isDefault: _isDefaultAddress,
        );
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (response != null) {
        _showSuccessSnackBar(
            _isEditMode
                ? 'Address updated successfully!'
                : 'Address saved successfully!'
        );

        debugPrint('✅ Address ${_isEditMode ? "updated" : "saved"} successfully');

        // Navigate based on which flow we're in
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            if (_isFromAddressList) {
              // Coming from address list - go back with success flag
              Navigator.pop(context, true);
            } else {
              // Original onboarding flow - navigate to home
              final provider = Provider.of<ProfileProvider>(context, listen: false);
              provider.clearProfileData();

              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                    (Route<dynamic> route) => false,
              );
            }
          }
        });
      } else {
        _showErrorSnackBar('Failed to ${_isEditMode ? "update" : "save"} address');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (e.toString().contains('Session expired') ||
          e.toString().contains('Authentication token not found') ||
          e.toString().contains('Unauthorized')) {
        await _handleUnauthorizedError();
        return;
      }

      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  void _skipAddress() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Skip Address?'),
        content: const Text(
          'You can add your address later from settings. Continue without saving address?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final provider = Provider.of<ProfileProvider>(context, listen: false);
              provider.clearProfileData();

              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                    (Route<dynamic> route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.black87),
        //   onPressed: _isLoading ? null : () => Navigator.pop(context),
        // ),
        title: Text(
          _isEditMode
              ? 'Edit Address'
              : (_isFromAddressList ? 'Add New Address' : 'Add Address'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        actions: [
          // Only show skip button in onboarding flow (not in edit or add from list
        ],
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

                          // Street Field
                          _buildFieldLabel('Street Address'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _streetController,
                            enabled: !_isLoading,
                            decoration: _buildInputDecoration('Enter street address'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter street address';
                              }
                              if (value.trim().length < 3) {
                                return 'Must be at least 3 characters';
                              }
                              return null;
                            },
                            textCapitalization: TextCapitalization.words,
                          ),

                          const SizedBox(height: 24),

                          // City Field
                          _buildFieldLabel('City'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _cityController,
                            enabled: !_isLoading,
                            decoration: _buildInputDecoration('Enter city'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter city';
                              }
                              if (value.trim().length < 2) {
                                return 'Must be at least 2 characters';
                              }
                              return null;
                            },
                            textCapitalization: TextCapitalization.words,
                          ),

                          const SizedBox(height: 24),

                          // State Field
                          _buildFieldLabel('State'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _stateController,
                            enabled: !_isLoading,
                            decoration: _buildInputDecoration('Enter state'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter state';
                              }
                              if (value.trim().length < 2) {
                                return 'Must be at least 2 characters';
                              }
                              return null;
                            },
                            textCapitalization: TextCapitalization.words,
                          ),

                          const SizedBox(height: 24),

                          // Pincode Field
                          _buildFieldLabel('Pincode'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _pincodeController,
                            enabled: !_isLoading,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            decoration: _buildInputDecoration('Enter 6-digit pincode'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter pincode';
                              }
                              if (value.trim().length != 6) {
                                return 'Pincode must be 6 digits';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Mobile Field
                          _buildFieldLabel('Mobile Number'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _mobileController,
                            enabled: !_isLoading,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: _buildInputDecoration('Enter 10-digit mobile number'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter mobile number';
                              }
                              if (value.trim().length != 10) {
                                return 'Mobile number must be 10 digits';
                              }
                              if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                                return 'Please enter a valid mobile number';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Save Address As
                          _buildFieldLabel('Save address as'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildAddressTypeButton('Home'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildAddressTypeButton('Office'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildAddressTypeButton('Other'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Default Address Checkbox
                          InkWell(
                            onTap: _isLoading
                                ? null
                                : () {
                              setState(() {
                                _isDefaultAddress = !_isDefaultAddress;
                              });
                              _checkForChanges();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isDefaultAddress
                                      ? Colors.red.shade300
                                      : Colors.grey.shade300,
                                  width: _isDefaultAddress ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: _isDefaultAddress
                                          ? Colors.red.shade400
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _isDefaultAddress
                                            ? Colors.red.shade400
                                            : Colors.grey.shade400,
                                        width: 2,
                                      ),
                                    ),
                                    child: _isDefaultAddress
                                        ? Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Set as default address',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: _isDefaultAddress
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: _isDefaultAddress
                                          ? Colors.black87
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Save/Update Address Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_isLoading || (_isEditMode && !_hasChanges))
                            ? null
                            : _saveAddress,
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
                            : Text(
                          _isEditMode ? 'Update Address' : 'Save Address',
                          style: const TextStyle(
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

  Widget _buildFieldLabel(String label) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '*',
          style: TextStyle(
            fontSize: 16,
            color: Colors.red.shade400,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  Widget _buildAddressTypeButton(String label) {
    final isSelected = _selectedAddressType == label;

    return GestureDetector(
      onTap: _isLoading
          ? null
          : () {
        setState(() {
          _selectedAddressType = label;
        });
        _checkForChanges();
      },
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