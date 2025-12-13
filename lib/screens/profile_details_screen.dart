// screens/profile_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../providers/profile_provider.dart';
import '../models/family_profile_model.dart';
import '../models/user_profile_model.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';

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
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();

  bool _isUploadingImage = false;
  bool _isCreatingProfile = false;
  String? _uploadedImageUrl;
  bool _isFromProfilesList = false;
  bool _isEditMode = false;
  String? _editingProfileId;
  UserProfileModel? _existingProfile;
  bool _hasChanges = false;
  String? _selectedRelationship;
  bool _isMainProfile = false;
  bool _isFirstProfile = false; // NEW: Flag for first profile

  final List<String> _relationships = [
    'Father',
    'Mother',
    'Son',
    'Daughter',
    'Spouse',
  ];

  final List<String> _allMeasurementTypes = [
    'chest',
    'waist',
    'hips',
    'shoulder',
    'sleeve',
    'neck',
    'length',
    'bust',
    'inseam',
    'outseam',
    'thigh',
    'calf',
    'ankle',
    'wrist',
    'other'
  ];

  final Map<int, TextEditingController> _measurementValueControllers = {};

  String? _originalName;
  String? _originalEmail;
  String? _originalGender;
  String? _originalImageUrl;
  String? _originalRelationship;
  List<ProfileMeasurement>? _originalMeasurements;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args != null && args is Map) {
        if (args['editProfile'] != null && args['editProfile'] is UserProfileModel) {
          setState(() {
            _isEditMode = true;
            _existingProfile = args['editProfile'] as UserProfileModel;
            _editingProfileId = _existingProfile!.profileId;
            _isMainProfile = args['isMainProfile'] ?? false;
          });

          await _loadExistingProfile();
        } else if (args['fromProfilesList'] == true) {
          setState(() {
            _isFromProfilesList = true;
            _isFirstProfile = args['isFirstProfile'] ?? false; // NEW: Capture first profile flag
          });

          final provider = Provider.of<ProfileProvider>(context, listen: false);
          provider.clearProfileData();
          debugPrint('🔄 Cleared profile data - coming from profiles list');
          debugPrint('📝 Is first profile: $_isFirstProfile'); // NEW: Debug log
        }
      } else {
        final provider = Provider.of<ProfileProvider>(context, listen: false);
        _nameController.text = provider.profile.name ?? '';
        _emailController.text = provider.profile.email ?? '';
      }
    });
  }

  Future<void> _loadExistingProfile() async {
    if (_existingProfile == null) return;

    final provider = Provider.of<ProfileProvider>(context, listen: false);

    provider.clearProfileData();

    _nameController.text = _existingProfile!.profileName;
    _emailController.text = '';
    _uploadedImageUrl = _existingProfile!.imageUrl;

    _selectedRelationship = null;

    _originalName = _existingProfile!.profileName;
    _originalEmail = '';
    _originalGender = _existingProfile!.gender;
    _originalImageUrl = _existingProfile!.imageUrl;
    _originalRelationship = _selectedRelationship;
    _originalMeasurements = List.from(_existingProfile!.measurements);

    provider.updateName(_existingProfile!.profileName);
    provider.updateEmail('');
    provider.updateGender(_existingProfile!.gender);

    if (_existingProfile!.imageUrl != null && _existingProfile!.imageUrl!.isNotEmpty) {
      provider.updateProfileImage(_existingProfile!.imageUrl!);
    }

    for (var measurement in _existingProfile!.measurements) {
      final newMeasurement = MeasurementModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: measurement.type,
        unit: '',
        value: measurement.value,
      );
      provider.addMeasurement(newMeasurement);
    }

    setState(() {});

    debugPrint('✅ Loaded existing profile for editing: ${_existingProfile!.profileId}');
  }

  void _checkForChanges() {
    final provider = Provider.of<ProfileProvider>(context, listen: false);

    bool changed = false;

    if (_nameController.text.trim() != _originalName) changed = true;
    if (provider.profile.gender != _originalGender) changed = true;
    if (_uploadedImageUrl != _originalImageUrl) changed = true;
    if (_selectedRelationship != _originalRelationship) changed = true;

    if (_originalMeasurements != null) {
      if (provider.profile.measurements.length != _originalMeasurements!.length) {
        changed = true;
      } else {
        for (int i = 0; i < provider.profile.measurements.length; i++) {
          final current = provider.profile.measurements[i];
          if (i < _originalMeasurements!.length) {
            final originalType = _originalMeasurements![i].type;
            final originalValue = _originalMeasurements![i].value;

            if (current.name != originalType || current.value != originalValue) {
              changed = true;
              break;
            }
          }
        }
      }
    }

    if (_hasChanges != changed) {
      setState(() {
        _hasChanges = changed;
      });
    }
  }

  List<String> _getAvailableMeasurementTypes(int currentIndex) {
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final selectedTypes = provider.profile.measurements
        .asMap()
        .entries
        .where((entry) => entry.key != currentIndex && entry.value.name.isNotEmpty)
        .map((entry) => entry.value.name.toLowerCase())
        .toSet();

    return _allMeasurementTypes
        .where((type) => !selectedTypes.contains(type.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();

    for (var controller in _measurementValueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _isUploadingImage = true;
        });

        Provider.of<ProfileProvider>(context, listen: false)
            .updateProfileImage(image.path);

        try {
          final imageUrl = await _profileService.uploadProfileImage(File(image.path));

          setState(() {
            _uploadedImageUrl = imageUrl;
            _isUploadingImage = false;
          });

          _showSuccessSnackBar('Image uploaded successfully!');
          debugPrint('✅ Image uploaded: $imageUrl');

          if (_isEditMode) {
            _checkForChanges();
          }
        } catch (e) {
          setState(() {
            _isUploadingImage = false;
          });

          if (e.toString().contains('Unauthorized') ||
              e.toString().contains('Invalid token') ||
              e.toString().contains('Authentication token not found')) {
            await _handleUnauthorizedError();
            return;
          }

          _showErrorSnackBar('Failed to upload image: ${e.toString()}');
          Provider.of<ProfileProvider>(context, listen: false)
              .updateProfileImage('');
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      _showErrorSnackBar('Failed to pick image: $e');
    }
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

    _measurementValueControllers[index] = TextEditingController();

    if (_isEditMode) {
      _checkForChanges();
    }
  }

  void _removeMeasurement(int index) {
    final provider = Provider.of<ProfileProvider>(context, listen: false);

    if (index >= 0 && index < provider.profile.measurements.length) {
      provider.removeMeasurement(index);

      _measurementValueControllers[index]?.dispose();
      _measurementValueControllers.remove(index);

      if (_isEditMode) {
        _checkForChanges();
      }
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

    if (_uploadedImageUrl == null || _uploadedImageUrl!.isEmpty) {
      _showErrorSnackBar('Please add and upload a profile image');
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

    for (int i = 0; i < provider.profile.measurements.length; i++) {
      final measurement = provider.profile.measurements[i];
      final valueController = _measurementValueControllers[i];

      if (measurement.name.trim().isEmpty) {
        _showErrorSnackBar('Please select all measurement types or remove empty measurements');
        return false;
      }

      if (valueController == null || valueController.text.trim().isEmpty) {
        _showErrorSnackBar('Please fill all measurement values or remove incomplete measurements');
        return false;
      }

      if (measurement.value.trim().isEmpty) {
        _showErrorSnackBar('Please fill all measurement values or remove incomplete measurements');
        return false;
      }
    }

    return true;
  }

  Future<void> _updateProfile() async {
    FocusScope.of(context).unfocus();

    if (!_validateAllFields()) {
      return;
    }

    final provider = Provider.of<ProfileProvider>(context, listen: false);

    provider.updateName(_nameController.text.trim());
    provider.updateEmail(_emailController.text.trim());

    setState(() {
      _isCreatingProfile = true;
    });

    try {
      debugPrint('🚀 Updating profile: $_editingProfileId');

      final measurements = provider.profile.measurements.map((m) {
        return MeasurementModel(
          id: m.id,
          name: m.name,
          unit: m.unit,
          value: m.value,
        );
      }).toList();

      final response = await _profileService.updateProfile(
        profileId: _editingProfileId!,
        profileName: provider.profile.name!,
        gender: provider.profile.gender!,
        email: provider.profile.email!,
        imageUrl: _uploadedImageUrl,
        measurements: measurements,
        address: null,
        relationship: _isMainProfile ? null : _selectedRelationship,
      );

      if (!mounted) return;

      setState(() {
        _isCreatingProfile = false;
      });

      if (response != null) {
        _showSuccessSnackBar('Profile updated successfully!');

        provider.clearProfileData();

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      } else {
        _showErrorSnackBar('Failed to update profile');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCreatingProfile = false;
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

  Future<void> _createProfile() async {
    FocusScope.of(context).unfocus();

    if (!_validateAllFields()) {
      return;
    }

    final provider = Provider.of<ProfileProvider>(context, listen: false);

    provider.updateName(_nameController.text.trim());
    provider.updateEmail(_emailController.text.trim());

    setState(() {
      _isCreatingProfile = true;
    });

    try {
      debugPrint('🚀 Creating profile with uploaded image: $_uploadedImageUrl');

      final measurements = provider.profile.measurements.map((m) {
        return MeasurementModel(
          id: m.id,
          name: m.name,
          unit: m.unit,
          value: m.value,
        );
      }).toList();

      final response = await _profileService.createProfile(
        profileName: provider.profile.name!,
        gender: provider.profile.gender!,
        email: provider.profile.email!,
        imageUrl: _uploadedImageUrl,
        measurements: measurements,
        address: null,
        relationship: _selectedRelationship,
      );

      if (!mounted) return;

      setState(() {
        _isCreatingProfile = false;
      });

      if (response != null) {
        _showSuccessSnackBar('Profile created successfully!');

        final profileId = response['profile']?['_id'] ?? response['_id'];
        debugPrint('✅ Profile created with ID: $profileId');

        provider.clearProfileData();

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            if (_isFromProfilesList) {
              Navigator.pop(context, true);
            } else {
              Navigator.pushNamed(
                context,
                '/set-location',
                arguments: profileId,
              );
            }
          }
        });
      } else {
        _showErrorSnackBar('Failed to create profile');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCreatingProfile = false;
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

  void _handleSkip() {
    final provider = Provider.of<ProfileProvider>(context, listen: false);

    provider.clearProfileData();

    Navigator.pushNamed(
      context,
      '/set-location',
      arguments: null,
    );

    debugPrint('⏭️ User skipped profile details');
  }

  String _getButtonText() {
    if (_isEditMode) {
      return 'Update Profile';
    } else if (_isFromProfilesList) {
      return 'Save Profile';
    } else {
      return 'Create Profile';
    }
  }

  String _getAppBarTitle() {
    if (_isEditMode) {
      return 'Edit Profile';
    } else {
      return 'Add New Profile';
    }
  }

  // NEW: Check if relationship field should be shown
  bool get _shouldShowRelationshipField {
    // Don't show in original onboarding flow
    if (!_isFromProfilesList && !_isEditMode) {
      return false;
    }

    // Don't show when editing main profile
    if (_isMainProfile) {
      return false;
    }

    // Don't show when creating first profile from profiles list
    if (_isFirstProfile) {
      return false;
    }

    // Show in all other cases
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: (_isFromProfilesList || _isEditMode)
          ? AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _isCreatingProfile || _isUploadingImage
              ? null
              : () => Navigator.pop(context),
        ),
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      )
          : null,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (!_isFromProfilesList && !_isEditMode) ...[
                        const SizedBox(height: 8),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            const Center(
                              child: Text(
                                'Profile Details',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              child: TextButton(
                                onPressed: _isCreatingProfile || _isUploadingImage
                                    ? null
                                    : _handleSkip,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 30),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Skip',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _isCreatingProfile || _isUploadingImage
                                        ? Colors.grey
                                        : Colors.red.shade400,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            'Please complete all fields to continue',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ] else ...[
                        const SizedBox(height: 20),
                      ],

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
                                  _buildImageStatus(),
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
                              enabled: !_isCreatingProfile,
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
                                if (_isEditMode) {
                                  _checkForChanges();
                                }
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
                                                () {
                                              provider.updateGender('Male');
                                              if (_isEditMode) {
                                                _checkForChanges();
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildGenderButton(
                                            'Female',
                                            provider.profile.gender == 'Female',
                                                () {
                                              provider.updateGender('Female');
                                              if (_isEditMode) {
                                                _checkForChanges();
                                              }
                                            },
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
                              enabled: !_isCreatingProfile,
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
                                if (_isEditMode) {
                                  _checkForChanges();
                                }
                              },
                            ),

                            const SizedBox(height: 24),

                            // Relationship Field - Conditionally shown
                            if (_shouldShowRelationshipField) ...[
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
                                decoration: InputDecoration(
                                  hintText: 'Select relationship',
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
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                items: _relationships.map((relationship) {
                                  return DropdownMenuItem(
                                    value: relationship,
                                    child: Text(relationship),
                                  );
                                }).toList(),
                                onChanged: _isCreatingProfile
                                    ? null
                                    : (value) {
                                  setState(() {
                                    _selectedRelationship = value;
                                  });
                                  if (_isEditMode) {
                                    _checkForChanges();
                                  }
                                },
                              ),
                              const SizedBox(height: 24),
                            ],

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

                                    ...provider.profile.measurements
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final index = entry.key;
                                      final measurement = entry.value;

                                      if (!_measurementValueControllers.containsKey(index)) {
                                        _measurementValueControllers[index] = TextEditingController(
                                          text: measurement.value,
                                        );
                                      }

                                      return _buildMeasurementCard(index, measurement);
                                    }).toList(),

                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: _isCreatingProfile ? null : _addMeasurement,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.add,
                                            color: _isCreatingProfile
                                                ? Colors.grey
                                                : Colors.red.shade400,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Add New Measurement',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: _isCreatingProfile
                                                  ? Colors.grey
                                                  : Colors.red.shade400,
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
                          onPressed: (_isCreatingProfile || _isUploadingImage || (_isEditMode && !_hasChanges))
                              ? null
                              : (_isEditMode ? _updateProfile : _createProfile),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade300,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                          child: _isCreatingProfile
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            _getButtonText(),
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

            if (_isUploadingImage)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Uploading image...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        final hasImage = provider.profile.profileImagePath != null &&
            provider.profile.profileImagePath!.isNotEmpty;
        final hasUploadedImage = _uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty;

        final showNetworkImage = _isEditMode && hasUploadedImage && !hasImage;

        return Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
                border: Border.all(
                  color: hasUploadedImage
                      ? Colors.green.shade300
                      : (hasImage ? Colors.orange.shade300 : Colors.grey.shade300),
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
                child: showNetworkImage
                    ? Image.network(
                  _uploadedImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey.shade400,
                    );
                  },
                )
                    : hasImage
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
                onTap: _isUploadingImage || _isCreatingProfile ? null : _pickAndUploadImage,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isUploadingImage || _isCreatingProfile
                        ? Colors.grey
                        : Colors.red.shade400,
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
                  child: _isUploadingImage
                      ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Icon(
                    Icons.edit,
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

  Widget _buildImageStatus() {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        final hasImage = provider.profile.profileImagePath != null &&
            provider.profile.profileImagePath!.isNotEmpty;
        final hasUploadedImage = _uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty;

        IconData icon;
        Color color;
        String text;

        if (hasUploadedImage) {
          icon = Icons.check_circle;
          color = Colors.green.shade400;
          text = 'Image uploaded';
        } else if (hasImage) {
          icon = Icons.cloud_upload;
          color = Colors.orange.shade400;
          text = 'Click to upload';
        } else {
          icon = Icons.warning;
          color = Colors.orange.shade400;
          text = 'Image required';
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGenderButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isCreatingProfile ? null : onTap,
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
    final availableTypes = _getAvailableMeasurementTypes(index);
    final currentType = measurement.name.isEmpty ? null : measurement.name;

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
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: currentType,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Type',
                  hintText: 'Select type',
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
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red, width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                items: [
                  if (currentType != null && !availableTypes.contains(currentType))
                    DropdownMenuItem<String>(
                      value: currentType,
                      child: Text(
                        currentType[0].toUpperCase() + currentType.substring(1),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ...availableTypes.map((type) => DropdownMenuItem<String>(
                    value: type,
                    child: Text(
                      type[0].toUpperCase() + type.substring(1),
                      style: const TextStyle(fontSize: 14),
                    ),
                  )),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
                onChanged: _isCreatingProfile
                    ? null
                    : (value) {
                  if (value != null) {
                    Provider.of<ProfileProvider>(context, listen: false)
                        .updateMeasurementName(index, value);
                    if (_isEditMode) {
                      _checkForChanges();
                    }
                    setState(() {});
                  }
                },
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _measurementValueControllers[index],
                enabled: !_isCreatingProfile,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: 'Value(in cm)',
                  hintText: '38',
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
                  Provider.of<ProfileProvider>(context, listen: false)
                      .updateMeasurementValue(index, value);
                  if (_isEditMode) {
                    _checkForChanges();
                  }
                },
              ),
            ),

            const SizedBox(width: 8),

            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: _isCreatingProfile ? Colors.grey : Colors.red.shade400,
              ),
              onPressed: _isCreatingProfile ? null : () => _removeMeasurement(index),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}