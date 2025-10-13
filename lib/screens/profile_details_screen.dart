// screens/profile_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../providers/profile_provider.dart';
import '../models/family_profile_model.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({Key? key}) : super(key: key);

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Store controllers for measurement types and values separately
  final Map<int, TextEditingController> _measurementTypeControllers = {};
  final Map<int, TextEditingController> _measurementValueControllers = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      _nameController.text = provider.profile.name ?? '';
      _emailController.text = provider.profile.email ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();

    // Dispose all measurement controllers
    for (var controller in _measurementTypeControllers.values) {
      controller.dispose();
    }
    for (var controller in _measurementValueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        Provider.of<ProfileProvider>(context, listen: false)
            .updateProfileImage(image.path);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  void _addMeasurement() {
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final newMeasurement = MeasurementModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '',
      unit: '',
      value: '',
    );

    provider.addMeasurement(newMeasurement);

    final index = provider.profile.measurements.length - 1;

    // Create separate controllers for type and value
    _measurementTypeControllers[index] = TextEditingController();
    _measurementValueControllers[index] = TextEditingController();
  }

  void _removeMeasurement(int index) {
    final provider = Provider.of<ProfileProvider>(context, listen: false);

    if (index >= 0 && index < provider.profile.measurements.length) {
      provider.removeMeasurement(index);

      // Dispose and remove both controllers
      _measurementTypeControllers[index]?.dispose();
      _measurementValueControllers[index]?.dispose();
      _measurementTypeControllers.remove(index);
      _measurementValueControllers.remove(index);
    }
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

  bool _validateAllFields() {
    final provider = Provider.of<ProfileProvider>(context, listen: false);

    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (provider.profile.profileImagePath == null ||
        provider.profile.profileImagePath!.isEmpty) {
      _showErrorSnackBar('Please add a profile image');
      return false;
    }

    if (provider.profile.name == null || provider.profile.name!.trim().isEmpty) {
      _showErrorSnackBar('Please enter your name');
      return false;
    }

    if (provider.profile.gender == null) {
      _showErrorSnackBar('Please select your gender');
      return false;
    }

    if (provider.profile.email == null || provider.profile.email!.trim().isEmpty) {
      _showErrorSnackBar('Please enter your email');
      return false;
    }

    if (!provider.isValidEmail(provider.profile.email!)) {
      _showErrorSnackBar('Please enter a valid email address');
      return false;
    }

    if (provider.profile.measurements.isEmpty) {
      _showErrorSnackBar('Please add at least one measurement');
      return false;
    }

    // Validate all measurements have both type and value
    for (int i = 0; i < provider.profile.measurements.length; i++) {
      final measurement = provider.profile.measurements[i];
      final typeController = _measurementTypeControllers[i];
      final valueController = _measurementValueControllers[i];

      if (typeController == null || typeController.text.trim().isEmpty) {
        _showErrorSnackBar('Please fill all measurement types or remove empty measurements');
        return false;
      }

      if (valueController == null || valueController.text.trim().isEmpty) {
        _showErrorSnackBar('Please fill all measurement values or remove incomplete measurements');
        return false;
      }

      // Also validate the model data
      if (measurement.name.trim().isEmpty) {
        _showErrorSnackBar('Please fill all measurement types or remove empty measurements');
        return false;
      }

      if (measurement.value.trim().isEmpty) {
        _showErrorSnackBar('Please fill all measurement values or remove incomplete measurements');
        return false;
      }
    }

    return true;
  }

  void _updateProfile() {
    FocusScope.of(context).unfocus();

    if (!_validateAllFields()) {
      return;
    }

    final provider = Provider.of<ProfileProvider>(context, listen: false);

    provider.updateName(_nameController.text.trim());
    provider.updateEmail(_emailController.text.trim());

    _showSuccessSnackBar('Profile updated successfully!');

    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pushNamed(context, '/add-address');
    });
  }

  void _skipProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Skip Profile Setup?'),
        content: const Text(
          'You can complete your profile later from settings. However, some features may be limited.',
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
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  const Text(
                    'Profile Details',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Please complete all fields to continue',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 40),

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
                        Center(
                          child: Column(
                            children: [
                              _buildProfileImage(),
                              const SizedBox(height: 8),
                              Consumer<ProfileProvider>(
                                builder: (context, provider, child) {
                                  final hasImage = provider.profile.profileImagePath != null;
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        hasImage ? Icons.check_circle : Icons.warning,
                                        size: 16,
                                        color: hasImage ? Colors.green.shade400 : Colors.orange.shade400,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        hasImage ? 'Image added' : 'Image required',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: hasImage ? Colors.green.shade400 : Colors.orange.shade400,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        Row(
                          children: [
                            const Text(
                              'Your Name',
                              style: TextStyle(
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
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Enter your name',
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
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Name is required';
                            }
                            if (value.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                              return 'Name can only contain letters';
                            }
                            return null;
                          },
                          textCapitalization: TextCapitalization.words,
                          onChanged: (value) {
                            Provider.of<ProfileProvider>(context, listen: false)
                                .updateName(value);
                          },
                        ),

                        const SizedBox(height: 24),

                        Row(
                          children: [
                            const Text(
                              'Gender',
                              style: TextStyle(
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
                        ),
                        const SizedBox(height: 8),
                        Consumer<ProfileProvider>(
                          builder: (context, provider, child) {
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildGenderButton(
                                        'Male',
                                        provider.profile.gender == 'Male',
                                            () => provider.updateGender('Male'),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildGenderButton(
                                        'Female',
                                        provider.profile.gender == 'Female',
                                            () => provider.updateGender('Female'),
                                      ),
                                    ),
                                  ],
                                ),
                                if (provider.profile.gender == null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Please select a gender',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange.shade600,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        Row(
                          children: [
                            const Text(
                              'Email',
                              style: TextStyle(
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
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'michael.mitc@example.com',
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
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }
                            final emailRegex = RegExp(
                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                            );
                            if (!emailRegex.hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            Provider.of<ProfileProvider>(context, listen: false)
                                .updateEmail(value);
                          },
                        ),

                        const SizedBox(height: 24),

                        // Measurements Section
                        Consumer<ProfileProvider>(
                          builder: (context, provider, child) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Measurements',
                                      style: TextStyle(
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
                                ),
                                const SizedBox(height: 16),

                                // Measurements List
                                ...provider.profile.measurements
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final index = entry.key;
                                  final measurement = entry.value;

                                  // Initialize controllers if not exists
                                  if (!_measurementTypeControllers.containsKey(index)) {
                                    _measurementTypeControllers[index] = TextEditingController(
                                      text: measurement.name,
                                    );
                                  }

                                  if (!_measurementValueControllers.containsKey(index)) {
                                    _measurementValueControllers[index] = TextEditingController(
                                      text: measurement.value,
                                    );
                                  }

                                  return _buildMeasurementCard(index, measurement);
                                }).toList(),

                                // Add New Measurement Button
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _addMeasurement,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.add,
                                        color: Colors.red.shade400,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Add New Measurement',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.red.shade400,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade300,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Update Profile',
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
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        final hasImage = provider.profile.profileImagePath != null;

        return Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
                border: Border.all(
                  color: hasImage ? Colors.green.shade300 : Colors.orange.shade300,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: hasImage
                    ? Image.file(
                  File(provider.profile.profileImagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey.shade400,
                    );
                  },
                )
                    : Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    hasImage ? Icons.edit : Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGenderButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.red.shade300 : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.red.shade400 : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementCard(int index, MeasurementModel measurement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Measurement Type Field
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _measurementTypeControllers[index],
                decoration: InputDecoration(
                  labelText: 'Type',
                  hintText: 'e.g., Chest',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.red.shade300, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Update the measurement name in provider
                  Provider.of<ProfileProvider>(context, listen: false)
                      .updateMeasurementName(index, value);
                },
              ),
            ),

            const SizedBox(width: 8),

            // Measurement Value Field (with unit)
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _measurementValueControllers[index],
                decoration: InputDecoration(
                  labelText: 'Value',
                  hintText: '38 inch',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.red.shade300, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Update the measurement value in provider
                  Provider.of<ProfileProvider>(context, listen: false)
                      .updateMeasurementValue(index, value);
                },
              ),
            ),

            const SizedBox(width: 8),

            // Delete button
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
              onPressed: () => _removeMeasurement(index),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}