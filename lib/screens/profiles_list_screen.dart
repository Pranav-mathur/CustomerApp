// screens/profiles_list_screen.dart

import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';

class ProfilesListScreen extends StatefulWidget {
  const ProfilesListScreen({Key? key}) : super(key: key);

  @override
  State<ProfilesListScreen> createState() => _ProfilesListScreenState();
}

class _ProfilesListScreenState extends State<ProfilesListScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  List<UserProfileModel> _profiles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _handleUnauthorizedError() async {
    // Clear stored auth data from secure storage
    await _authService.clearSession();

    if (!mounted) return;

    // Show a message to the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session expired. Please login again.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );

    // Small delay to show the snackbar
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Navigate to login page and clear navigation stack
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login', // Replace with your actual login route
          (Route<dynamic> route) => false,
    );
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profiles = await _profileService.getAllUserProfiles();

      if (!mounted) return;

      setState(() {
        _profiles = profiles ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      // Check if the error is a 401 (Unauthorized) error
      if (e.toString().contains('Session expired') ||
          e.toString().contains('Authentication token not found') ||
          e.toString().contains('Unauthorized')) {
        await _handleUnauthorizedError();
        return;
      }

      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
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
        title: const Text(
          'My Profiles',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
          ? _buildErrorState()
          : _buildProfilesList(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading profiles...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.06),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: screenWidth * 0.16,
              color: Colors.red.shade300,
            ),
            SizedBox(height: screenWidth * 0.04),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenWidth * 0.02),
            Text(
              _errorMessage ?? 'Unknown error',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenWidth * 0.06),
            ElevatedButton.icon(
              onPressed: _loadProfiles,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.06,
                  vertical: screenWidth * 0.03,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilesList() {
    final screenWidth = MediaQuery.of(context).size.width;

    if (_profiles.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.06),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline,
                size: screenWidth * 0.2,
                color: Colors.grey.shade300,
              ),
              SizedBox(height: screenWidth * 0.04),
              Text(
                'No profiles yet',
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: screenWidth * 0.02),
              Text(
                'Create your first profile to get started',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenWidth * 0.06),
              ElevatedButton.icon(
                onPressed: () async {
                  // Navigate to profile details with flag indicating it's from profiles list
                  final result = await Navigator.pushNamed(
                    context,
                    '/profile-details',
                    arguments: {'fromProfilesList': true},
                  );

                  // If profile was created successfully, reload the list
                  if (result == true) {
                    _loadProfiles();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add New Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.06,
                    vertical: screenWidth * 0.035,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profiles created by you',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadProfiles,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              itemCount: _profiles.length + 1, // +1 for Add New Profile button
              itemBuilder: (context, index) {
                if (index == _profiles.length) {
                  return _buildAddNewProfileButton();
                }
                return _buildProfileCard(_profiles[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(UserProfileModel profile) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine if this is the main user profile
    final isMainProfile = profile.profileName.toLowerCase().contains('you') ||
        profile.profileName.toLowerCase().contains('admin') ||
        _profiles.indexOf(profile) == 0;

    return Container(
      margin: EdgeInsets.only(bottom: screenWidth * 0.04),
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
      child: InkWell(
        onTap: () async {
          // Navigate to profile edit screen
          final result = await Navigator.pushNamed(
            context,
            '/profile-details',
            arguments: {
              'editProfile': profile,
            },
          );

          // If profile was updated successfully, reload the list
          if (result == true) {
            _loadProfiles();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Row(
            children: [
              // Profile Image
              Container(
                width: screenWidth * 0.15,
                height: screenWidth * 0.15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: profile.imageUrl != null && profile.imageUrl!.isNotEmpty
                      ? Image.network(
                    profile.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        size: screenWidth * 0.075,
                        color: Colors.grey.shade400,
                      );
                    },
                  )
                      : Icon(
                    Icons.person,
                    size: screenWidth * 0.075,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              // Profile Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.profileName,
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    Row(
                      children: [
                        if (isMainProfile) ...[
                          Flexible(
                            child: Text(
                              'You (admin)',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
                            child: Text(
                              '•',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ],
                        Flexible(
                          child: Text(
                            '${profile.measurements.length} measurement${profile.measurements.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              // Arrow Icon
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: screenWidth * 0.07,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddNewProfileButton() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.only(top: screenWidth * 0.02, bottom: screenWidth * 0.06),
      child: InkWell(
        onTap: () async {
          // Navigate to profile details with flag indicating it's from profiles list
          final result = await Navigator.pushNamed(
            context,
            '/profile-details',
            arguments: {'fromProfilesList': true},
          );

          // If profile was created successfully, reload the list
          if (result == true) {
            _loadProfiles();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.04),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                color: Colors.red.shade400,
                size: screenWidth * 0.06,
              ),
              SizedBox(width: screenWidth * 0.02),
              Text(
                'Add New Profile',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}