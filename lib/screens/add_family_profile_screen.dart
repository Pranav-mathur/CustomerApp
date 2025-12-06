// screens/add_family_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/family_profile_model.dart';
import '../providers/family_profile_provider.dart';

class AddFamilyProfileScreen extends StatefulWidget {
  final String? profileId; // For editing existing profile

  const AddFamilyProfileScreen({Key? key, this.profileId}) : super(key: key);

  @override
  State<AddFamilyProfileScreen> createState() => _AddFamilyProfileScreenState();
}

class _AddFamilyProfileScreenState extends State<AddFamilyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _profileImagePath;
  String? _selectedRelationship;
  FamilyAddressModel? _address;
  List<MeasurementModel> _measurements = [];

  final List<String> _relationships = [
    'Father',
    'Mother',
    'Son',
    'Daughter',
    'Spouse',
  ];

  @override
  void initState() {
    super.initState();
    // Load existing profile if editing
    if (widget.profileId != null) {
      _loadExistingProfile();
    }
  }

  void _loadExistingProfile() {
    final provider = Provider.of<FamilyProfileProvider>(context, listen: false);
    final profile = provider.getFamilyProfileById(widget.profileId!);

    if (profile != null) {
      setState(() {
        _nameController.text = profile.name ?? '';
        _mobileController.text = profile.mobile ?? '';
        _selectedRelationship = profile.relationship;
        _profileImagePath = profile.profileImagePath;
        _address = profile.address;
        _measurements = List.from(profile.measurements);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
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
        setState(() {
          _profileImagePath = image.path;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  void _showAddressBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddressBottomSheet(
        initialAddress: _address,
        onSave: (address) {
          setState(() {
            _address = address;
          });
        },
      ),
    );
  }

  void _addMeasurement() {
    setState(() {
      _measurements.add(MeasurementModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '',
        unit: 'inch',
      ));
    });
  }

  void _removeMeasurement(int index) {
    setState(() {
      _measurements.removeAt(index);
    });
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // Relationship is now optional, so we don't need to check for it

      final profile = FamilyProfileModel(
        id: widget.profileId,
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        relationship: _selectedRelationship, // Can be null
        profileImagePath: _profileImagePath,
        address: _address,
        measurements: _measurements,
      );

      final provider = Provider.of<FamilyProfileProvider>(context, listen: false);

      if (widget.profileId != null) {
        provider.updateFamilyProfile(widget.profileId!, profile);
        _showSuccessSnackBar('Profile updated successfully!');
      } else {
        provider.addFamilyProfile(profile);
        _showSuccessSnackBar('Profile added successfully!');
      }

      Navigator.pop(context);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.profileId != null ? 'Edit Profile' : 'Add Profile',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Profile Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                      // Profile Image
                      Center(child: _buildProfileImage()),
                      const SizedBox(height: 24),

                      // Name Field
                      const Text(
                        'Your Name',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration('Enter your name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter name';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),

                      const SizedBox(height: 20),

                      // Mobile Number Field
                      const Text(
                        'Mobile Number',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration('Enter your mobile number'),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter mobile number';
                          }
                          if (value.length != 10) {
                            return 'Mobile number must be 10 digits';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Relationship Field (Optional)
                      const Text(
                        'Relationship',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedRelationship,
                        decoration: _inputDecoration('Select relationship'),
                        items: _relationships.map((relationship) {
                          return DropdownMenuItem(
                            value: relationship,
                            child: Text(relationship),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRelationship = value;
                          });
                        },
                        // No validator - making it optional
                      ),

                      const SizedBox(height: 20),

                      // Address Section
                      const Text(
                        'Address',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _showAddressBottomSheet,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add,
                                color: Colors.red.shade400,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _address != null && _address!.hasData
                                      ? _address!.fullAddress
                                      : 'Add Address',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: _address != null && _address!.hasData
                                        ? Colors.black87
                                        : Colors.grey.shade600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Measurements Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Measurement',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (_measurements.isNotEmpty)
                            TextButton.icon(
                              onPressed: _addMeasurement,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add More'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red.shade400,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Measurements List
                      if (_measurements.isEmpty)
                        InkWell(
                          onTap: _addMeasurement,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add,
                                  color: Colors.red.shade400,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Add Measurement',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._measurements.asMap().entries.map((entry) {
                          final index = entry.key;
                          final measurement = entry.value;
                          return _buildMeasurementRow(index, measurement);
                        }).toList(),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Add Profile Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade300,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.profileId != null ? 'Update Profile' : 'Add Profile',
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
      ),
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: _profileImagePath != null
                ? Image.file(
              File(_profileImagePath!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.grey.shade400,
                );
              },
            )
                : Icon(
              Icons.person,
              size: 50,
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
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementRow(int index, MeasurementModel measurement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: measurement.name,
              decoration: _inputDecoration('Measurement Name').copyWith(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _measurements[index] = _measurements[index].copyWith(name: value);
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: measurement.unit,
              decoration: _inputDecoration('Unit').copyWith(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'inch', child: Text('inch')),
                DropdownMenuItem(value: 'cm', child: Text('cm')),
                DropdownMenuItem(value: 'm', child: Text('m')),
              ],
              onChanged: (value) {
                setState(() {
                  _measurements[index] = _measurements[index].copyWith(unit: value!);
                });
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
            onPressed: () => _removeMeasurement(index),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
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
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

// Address Bottom Sheet Widget
class _AddressBottomSheet extends StatefulWidget {
  final FamilyAddressModel? initialAddress;
  final Function(FamilyAddressModel) onSave;

  const _AddressBottomSheet({
    Key? key,
    this.initialAddress,
    required this.onSave,
  }) : super(key: key);

  @override
  State<_AddressBottomSheet> createState() => __AddressBottomSheetState();
}

class __AddressBottomSheetState extends State<_AddressBottomSheet> {
  late TextEditingController _houseFlatController;
  late TextEditingController _apartmentController;
  late TextEditingController _streetController;

  @override
  void initState() {
    super.initState();
    _houseFlatController = TextEditingController(
      text: widget.initialAddress?.houseFlatBlock ?? '',
    );
    _apartmentController = TextEditingController(
      text: widget.initialAddress?.apartmentRoadArea ?? '',
    );
    _streetController = TextEditingController(
      text: widget.initialAddress?.streetAndCity ?? '',
    );
  }

  @override
  void dispose() {
    _houseFlatController.dispose();
    _apartmentController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Address',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _houseFlatController,
              decoration: InputDecoration(
                labelText: 'House/Flat/Block',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apartmentController,
              decoration: InputDecoration(
                labelText: 'Apartment/Road/Area',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _streetController,
              decoration: InputDecoration(
                labelText: 'Street and City',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final address = FamilyAddressModel(
                    houseFlatBlock: _houseFlatController.text.trim(),
                    apartmentRoadArea: _apartmentController.text.trim(),
                    streetAndCity: _streetController.text.trim(),
                  );
                  widget.onSave(address);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Address',
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
    );
  }
}