// lib/screens/set_location_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../widgets/location_search_bar.dart';
import '../widgets/location_summary_card.dart';
import '../utils/responsive_helper.dart';

class SetLocationScreen extends StatefulWidget {
  const SetLocationScreen({Key? key}) : super(key: key);

  @override
  State<SetLocationScreen> createState() => _SetLocationScreenState();
}

class _SetLocationScreenState extends State<SetLocationScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  // Store the profileId passed from ProfileDetailsScreen
  String? _profileId;
  bool _isFromProfilesList = false;

  @override
  void initState() {
    super.initState();

    // Get current location and handle arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Get the profileId argument
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args != null) {
        if (args is Map) {
          // Handle map arguments (for future extensibility)
          setState(() {
            _profileId = args['profileId'] as String?;
            _isFromProfilesList = args['fromProfilesList'] == true;
          });
        } else if (args is String) {
          // Handle direct profileId string
          setState(() {
            _profileId = args;
          });
        }
      }

      debugPrint('📍 SetLocationScreen - Received profile ID: $_profileId');

      // Get current location
      context.read<LocationProvider>().getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onMapMove(LatLng center) {
    context.read<LocationProvider>().updateMapCenter(center);
  }

  void _onCurrentLocationPressed() async {
    final provider = context.read<LocationProvider>();
    final success = await provider.getCurrentLocation();

    if (success) {
      _mapController.move(provider.currentMapCenter, 15.0);
    } else {
      _showErrorSnackBar(provider.errorMessage ?? 'Unable to get location');
    }
  }

  void _onConfirmLocation() {
    final locationProvider = context.read<LocationProvider>();
    final location = locationProvider.selectedLocation;

    if (location != null) {
      debugPrint('✅ Location confirmed: ${location.displayName}');
      debugPrint('📍 Coordinates: ${location.coordinates.latitude}, ${location.coordinates.longitude}');

      // Prepare location data to pass
      final locationData = {
        'profileId': _profileId,
        'locationData': {
          'displayName': location.displayName,
          'street': location.address,
          'city': location.city,
          'state': location.state,
          'country': location.country,
          'postalCode': location.postalCode,
          'latitude': location.coordinates.latitude,
          'longitude': location.coordinates.longitude,
        },
      };

      // Navigate to AddAddressScreen with location data
      Navigator.pushNamed(
        context,
        '/add-address',
        arguments: locationData,
      );
    } else {
      _showErrorSnackBar('Please select a location');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: responsive.sp(24),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Set Location',
          style: TextStyle(
            color: Colors.black,
            fontSize: responsive.sp(20),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar - Responsive padding
          Padding(
            padding: EdgeInsets.all(responsive.wp(4)),
            child: LocationSearchBar(
              controller: _searchController,
              onSearchResultSelected: (location) {
                _mapController.move(location.coordinates, 15.0);
                _searchController.clear();
                FocusScope.of(context).unfocus();
              },
            ),
          ),

          // Map Section
          Expanded(
            child: Consumer<LocationProvider>(
              builder: (context, provider, child) {
                return Stack(
                  children: [
                    // Map
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: provider.currentMapCenter,
                        initialZoom: 15.0,
                        onPositionChanged: (position, hasGesture) {
                          if (hasGesture && position.center != null) {
                            _onMapMove(position.center!);
                          }
                        },
                      ),
                      children: [
                        // ✅ UPDATED: Use CartoDB tiles (more reliable)
                        TileLayer(
                          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'com.casadarzi.tailor_app',
                          maxZoom: 19,
                        ),
                      ],
                    ),

                    // Center Pin (Fixed position) - Responsive size
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: responsive.isMobile
                                ? responsive.sp(48)
                                : responsive.sp(56),
                            color: Colors.red,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: responsive.isMobile
                                ? responsive.sp(48)
                                : responsive.sp(56),
                          ),
                        ],
                      ),
                    ),

                    // Current Location Button - Responsive positioning
                    Positioned(
                      right: responsive.wp(4),
                      bottom: screenHeight * 0.22, // 22% from bottom
                      child: FloatingActionButton(
                        heroTag: 'currentLocation',
                        onPressed: _onCurrentLocationPressed,
                        backgroundColor: Colors.white,
                        elevation: 4,
                        child: provider.isLoadingLocation
                            ? SizedBox(
                          width: responsive.sp(24),
                          height: responsive.sp(24),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: responsive.sp(24),
                        ),
                      ),
                    ),

                    // Loading Overlay - Responsive positioning and sizing
                    if (provider.isGeocodingAddress)
                      Positioned(
                        bottom: screenHeight * 0.25, // 25% from bottom
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.wp(4),
                              vertical: responsive.hp(1),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(
                                responsive.sp(20),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: responsive.sp(16),
                                  height: responsive.sp(16),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: responsive.wp(2)),
                                Text(
                                  'Getting address...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: responsive.sp(14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Location Summary Card
          const LocationSummaryCard(),

          // Confirm Button - Responsive padding and sizing
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(responsive.wp(4)),
            child: ElevatedButton(
              onPressed: _onConfirmLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(
                  vertical: responsive.hp(2),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    responsive.sp(12),
                  ),
                ),
                elevation: 2,
              ),
              child: Text(
                'Confirm Location',
                style: TextStyle(
                  fontSize: responsive.sp(16),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}