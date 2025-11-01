// screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:io';
import '../providers/profile_provider.dart';
import '../models/home_screen_models.dart';
import '../services/home_service.dart';
import '../services/profile_service.dart';
import '../services/address_service.dart';
import '../models/user_profile_model.dart';
import '../models/address_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final HomeService _homeService = HomeService();
  final ProfileService _profileService = ProfileService();
  final AddressService _addressService = AddressService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  TabController? _tabController;
  String _selectedGender = 'Men';
  List<BannerModel> banners = [];
  List<CategoryModel> categories = [];
  List<TailorModel> featuredTailors = [];
  List<TailorModel> allTailors = [];
  List<String> genderTabs = [];
  String? _selectedCategoryId;
  List<TailorModel> _filteredFeaturedTailors = [];
  List<TailorModel> _filteredAllTailors = [];

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _categoriesData;

  // User data
  UserProfileModel? _userProfile;
  AddressModel? _defaultAddress;
  bool _isLoadingUserData = true;

  // Search related
  bool _isSearchActive = false;
  List<String> _recentSearches = [];
  List<TailorModel> _searchResults = [];

  @override
  void initState() {
    super.initState();
    // ⭐ ADD THIS: Reload global profile when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).loadActiveUserProfile();
    });
    _loadAllData();
    _loadRecentSearches();
    _searchController.addListener(_onSearchChanged);
  }

  void _onTabChanged() {
    if (_tabController == null ||
        !_tabController!.indexIsChanging ||
        genderTabs.isEmpty ||
        _tabController!.index >= genderTabs.length) {
      return;
    }

    setState(() {
      _selectedGender = genderTabs[_tabController!.index];
      _updateCategories();
    });
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadUserData(),
      _loadHomeData(),
    ]);
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
    } else {
      _performSearch(_searchController.text);
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }
    final lowerQuery = query.toLowerCase();

    // Combine featured and all tailors, remove duplicates
    final allTailorsList = [...featuredTailors, ...allTailors];
    final uniqueTailors = <String, TailorModel>{};
    for (var tailor in allTailorsList) {
      uniqueTailors[tailor.id] = tailor;
    }

    // Filter by name
    final results = uniqueTailors.values.where((tailor) {
      return tailor.name.toLowerCase().contains(lowerQuery);
    }).toList();

    setState(() {
      _searchResults = results;
    });

    debugPrint('🔍 Search query: "$query" - Found ${results.length} results');
  }

  Future<void> _loadRecentSearches() async {
    try {
      final searchesJson = await _secureStorage.read(key: 'recent_searches');
      if (searchesJson != null) {
        final List<dynamic> decoded = jsonDecode(searchesJson);
        setState(() {
          _recentSearches = decoded.cast<String>();
        });
      }
    } catch (e) {
      debugPrint('Error loading recent searches: $e');
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) {
        _recentSearches = _recentSearches.sublist(0, 5);
      }
    });
    try {
      final encoded = jsonEncode(_recentSearches);
      await _secureStorage.write(key: 'recent_searches', value: encoded);
    } catch (e) {
      debugPrint('Error saving recent search: $e');
    }
  }

  Future<void> _clearRecentSearches() async {
    setState(() {
      _recentSearches.clear();
    });
    try {
      await _secureStorage.delete(key: 'recent_searches');
    } catch (e) {
      debugPrint('Error clearing recent searches: $e');
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingUserData = true;
    });

    try {
      final results = await Future.wait([
        _profileService.getAllUserProfiles(),
        _addressService.getAllAddresses(),
      ]);

      final profiles = results[0] as List<UserProfileModel>?;
      final addresses = results[1] as List<AddressModel>?;

      setState(() {
        if (profiles != null && profiles.isNotEmpty) {
          _userProfile = profiles.first;
        }

        if (addresses != null && addresses.isNotEmpty) {
          _defaultAddress = addresses.firstWhere(
                (addr) => addr.isDefault == true,
            orElse: () => addresses.first,
          );
        }

        _isLoadingUserData = false;
      });

      debugPrint('✅ User data loaded - Profile: ${_userProfile?.profileName}, Address: ${_defaultAddress?.addressType}');
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      setState(() {
        _isLoadingUserData = false;
      });
    }
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _homeService.getHomeData();

      if (response['success'] == true) {
        final data = response['data'];

        print('=== DEBUG: API Response ===');
        print('Banners type: ${data['banners'].runtimeType}');
        print('Banners data: ${data['banners']}');
        print('Categories type: ${data['categories'].runtimeType}');
        print('Featured tailors count: ${(data['featuredTailors'] as List?)?.length ?? 0}');
        print('All tailors count: ${(data['allTailors'] as List?)?.length ?? 0}');

        List<BannerModel> tempBanners = [];
        try {
          if (data['banners'] != null) {
            tempBanners = (data['banners'] as List)
                .map((item) {
              print('Banner item type: ${item.runtimeType}, value: $item');
              return BannerModel.fromJson(item);
            })
                .toList();
          }
        } catch (e) {
          print('Error parsing banners: $e');
        }

        Map<String, dynamic>? tempCategoriesData;
        try {
          tempCategoriesData = data['categories'] as Map<String, dynamic>;
        } catch (e) {
          print('Error parsing categories: $e');
          tempCategoriesData = {};
        }

        List<String> tempGenderTabs = tempCategoriesData.keys.map((key) {
          return key[0].toUpperCase() + key.substring(1);
        }).toList();

        List<TailorModel> tempFeaturedTailors = [];
        try {
          tempFeaturedTailors = (data['featuredTailors'] as List)
              .map((json) => TailorModel.fromJson(json))
              .toList();
        } catch (e) {
          print('Error parsing featured tailors: $e');
        }

        List<TailorModel> tempAllTailors = [];
        try {
          tempAllTailors = (data['allTailors'] as List)
              .map((json) => TailorModel.fromJson(json))
              .toList();
        } catch (e) {
          print('Error parsing all tailors: $e');
        }

        if (tempGenderTabs.isNotEmpty) {
          bool needsNewController = _tabController == null ||
              _tabController!.length != tempGenderTabs.length;

          if (needsNewController) {
            if (_tabController != null) {
              _tabController!.removeListener(_onTabChanged);
              _tabController!.dispose();
              _tabController = null;
            }

            _tabController = TabController(
              length: tempGenderTabs.length,
              vsync: this,
              initialIndex: 0,
            );
            _tabController!.addListener(_onTabChanged);
          }
        }

        // Debug: Print tailor data BEFORE setState
        print('=== TAILORS DEBUG ===');
        if (tempFeaturedTailors.isNotEmpty) {
          print('Sample Featured Tailor: ${tempFeaturedTailors.first.name}');
          for (var cat in tempFeaturedTailors.first.categories) {
            print('  - Category ID: ${cat.categoryId}, SubCategory: ${cat.subCategoryName}');
          }
        }
        if (tempAllTailors.isNotEmpty) {
          print('Sample All Tailor: ${tempAllTailors.first.name}');
          for (var cat in tempAllTailors.first.categories) {
            print('  - Category ID: ${cat.categoryId}, SubCategory: ${cat.subCategoryName}');
          }
        }

        setState(() {
          banners = tempBanners;
          _categoriesData = tempCategoriesData;
          genderTabs = tempGenderTabs;
          featuredTailors = tempFeaturedTailors;
          allTailors = tempAllTailors;

          _filteredFeaturedTailors = featuredTailors;
          _filteredAllTailors = allTailors;

          if (genderTabs.isNotEmpty) {
            _selectedGender = genderTabs[0];
          }

          _updateCategories();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load data';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('=== ERROR ===');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  void _updateCategories() {
    if (_categoriesData == null || _categoriesData!.isEmpty) {
      setState(() {
        categories = [];
        _selectedCategoryId = null;
        _filteredFeaturedTailors = featuredTailors;
        _filteredAllTailors = allTailors;
      });
      return;
    }

    final genderKey = _selectedGender.toLowerCase();
    print('=== UPDATE CATEGORIES ===');
    print('Selected Gender Key: $genderKey');
    print('Available Gender Keys: ${_categoriesData!.keys.join(", ")}');

    setState(() {
      if (_categoriesData!.containsKey(genderKey)) {
        try {
          categories = (_categoriesData![genderKey] as List)
              .map((json) => CategoryModel.fromJson(json))
              .toList();
          print('Loaded ${categories.length} categories for $genderKey');
          for (var cat in categories) {
            print('  - ${cat.name} (ID: ${cat.id})');
          }
        } catch (e) {
          print('Error parsing categories for $genderKey: $e');
          categories = [];
        }
      } else {
        print('No categories found for gender: $genderKey');
        categories = [];
      }

      _selectedCategoryId = null;
      _filteredFeaturedTailors = featuredTailors;
      _filteredAllTailors = allTailors;
    });
  }

  void _filterTailorsByCategory(String? categoryId) {
    print('=== FILTER TRIGGERED ===');
    print('Selected Category ID: $categoryId');
    print('Current Gender: $_selectedGender');

    setState(() {
      _selectedCategoryId = categoryId;

      if (categoryId == null) {
        // No filter - show all tailors
        _filteredFeaturedTailors = featuredTailors;
        _filteredAllTailors = allTailors;
        print('Filter cleared - showing all tailors');
      } else {
        // Filter by category ID
        _filteredFeaturedTailors = featuredTailors.where((tailor) {
          bool hasCategory = tailor.categories.any((cat) {
            bool matches = cat.categoryId == categoryId;
            if (matches) {
              print('✅ Match found: ${tailor.name} has category ${cat.subCategoryName} with ID ${cat.categoryId}');
            }
            return matches;
          });
          return hasCategory;
        }).toList();

        _filteredAllTailors = allTailors.where((tailor) {
          bool hasCategory = tailor.categories.any((cat) {
            bool matches = cat.categoryId == categoryId;
            return matches;
          });
          return hasCategory;
        }).toList();

        print('=== FILTER RESULTS ===');
        print('Featured Tailors Before: ${featuredTailors.length}');
        print('Featured Tailors After: ${_filteredFeaturedTailors.length}');
        print('All Tailors Before: ${allTailors.length}');
        print('All Tailors After: ${_filteredAllTailors.length}');

        if (_filteredFeaturedTailors.isEmpty && _filteredAllTailors.isEmpty) {
          print('⚠️ NO MATCHES FOUND!');
          print('Available category IDs in tailors:');
          Set<String> allCategoryIds = {};
          for (var tailor in [...featuredTailors, ...allTailors]) {
            for (var cat in tailor.categories) {
              allCategoryIds.add(cat.categoryId);
            }
          }
          print('Category IDs: ${allCategoryIds.join(", ")}');
        }
      }
    });
  }

  void _openDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Drawer',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: _buildModernDrawer(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    if (_tabController != null) {
      _tabController!.removeListener(_onTabChanged);
      _tabController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSearchActive) {
      return _buildSearchView();
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                  ? _buildErrorState()
                  : RefreshIndicator(
                onRefresh: _loadAllData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildBanner(),
                      const SizedBox(height: 16),
                      _buildGenderTabs(),
                      const SizedBox(height: 16),
                      _buildCategories(),
                      const SizedBox(height: 24),
                      _buildFeaturedTailors(),
                      const SizedBox(height: 24),
                      _buildAllTailors(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text('Loading...', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Oops! Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            // const SizedBox(height: 8),
            // Text(_errorMessage ?? 'Unknown error', style: TextStyle(fontSize: 14, color: Colors.grey.shade600), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAllData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          GestureDetector(
            // onTap: () => Navigator.pushNamed(context, '/profile-details'),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
                border: Border.all(color: Colors.red.shade300, width: 2),
              ),
              child: ClipOval(
                child: _userProfile?.imageUrl != null
                    ? Image.network(
                  _userProfile!.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: 30, color: Colors.grey.shade400),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade400)));
                  },
                )
                    : Icon(Icons.person, size: 30, color: Colors.grey.shade400),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/add-address'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_defaultAddress?.addressType?.toUpperCase() ?? 'No Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      // const SizedBox(width: 4),
                      // Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey.shade600),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _defaultAddress != null ? '${_defaultAddress!.street}, ${_defaultAddress!.city}...' : 'Add your address',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          IconButton(icon: Icon(Icons.menu, color: Colors.black87, size: 28), onPressed: _openDrawer),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isSearchActive = true;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey.shade400),
              const SizedBox(width: 12),
              Text(
                'Search tailor, category',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSearchActive = false;
                        _searchController.clear();
                        _searchResults.clear();
                      });
                    },
                    child: const Icon(Icons.arrow_back, color: Colors.black87),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search tailor, category',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        // This triggers _onSearchChanged via the listener
                        // Force rebuild to show/hide clear button
                        setState(() {});
                      },
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          _saveRecentSearch(value.trim());
                        }
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchController.clear();
                          _searchResults.clear();
                        });
                      },
                      child: Icon(Icons.close, color: Colors.grey.shade600, size: 20),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (_searchController.text.trim().isNotEmpty) {
                        _saveRecentSearch(_searchController.text.trim());
                      }
                    },
                    child: Icon(Icons.search, color: Colors.grey.shade600, size: 22),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _searchController.text.isEmpty
                  ? _buildRecentSearchesContent()
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearchesContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.history, size: 20, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'Recent Searched',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentSearches.map((search) {
                  return GestureDetector(
                    onTap: () {
                      _searchController.text = search;
                      _performSearch(search);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        search,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.star, size: 16, color: Colors.grey.shade700),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Featured Tailors',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: featuredTailors.length,
              itemBuilder: (context, index) => _buildTailorCard(featuredTailors[index], isHorizontal: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No tailors found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with a different name',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildTailorCard(_searchResults[index], isHorizontal: false);
      },
    );
  }

  Widget _buildBanner() {
    if (banners.isEmpty) return const SizedBox();

    return Container(
      height: 150,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: PageView.builder(
        itemCount: banners.length,
        itemBuilder: (context, index) {
          final banner = banners[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(image: NetworkImage(banner.imageUrl), fit: BoxFit.cover),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                ),
              ),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(16),
              child: Text("Big Bazaar Sale - Up to 40% Off", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGenderTabs() {
    if (genderTabs.isEmpty || _tabController == null) return const SizedBox();

    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1))),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.red.shade400,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        indicatorColor: Colors.red.shade400,
        indicatorWeight: 3,
        tabs: genderTabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }

  Widget _buildCategories() {
    if (categories.isEmpty) return const SizedBox();

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) => _buildCategoryItem(categories[index]),
      ),
    );
  }

  Widget _buildCategoryItem(CategoryModel category) {
    final isSelected = _selectedCategoryId == category.id;

    return GestureDetector(
      onTap: () {
        print('=== CATEGORY TAPPED ===');
        print('Category: ${category.name}');
        print('Category ID: ${category.id}');
        print('Gender: ${category.gender}');
        print('Currently Selected Gender: $_selectedGender');

        if (isSelected) {
          print('Deselecting category');
          _filterTailorsByCategory(null);
        } else {
          print('Selecting category');
          _filterTailorsByCategory(category.id);
        }
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getCategoryColor(category.name),
                border: isSelected ? Border.all(color: Colors.red.shade400, width: 3) : null,
                boxShadow: isSelected ? [BoxShadow(color: Colors.red.shade400.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)] : null,
              ),
              child: Center(child: Icon(_getCategoryIcon(category.name), size: 32, color: Colors.white)),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.red.shade400 : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected) Container(margin: const EdgeInsets.only(top: 2), width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.shade400)),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String name) {
    final colors = [Colors.red.shade300, Colors.orange.shade300, Colors.green.shade300, Colors.yellow.shade600, Colors.grey.shade400];
    return colors[name.hashCode % colors.length];
  }

  IconData _getCategoryIcon(String name) {
    final icons = {
      'Blazer': Icons.business_center, 'Sherwani': Icons.checkroom, 'Kurta': Icons.checkroom_outlined,
      'Shirts': Icons.shopping_bag, 'Jackets': Icons.dry_cleaning, 'Saree': Icons.woman, 'Lehenga': Icons.woman_2,
      'Blouse': Icons.shopping_bag_outlined, 'Suit': Icons.business, 'Gown': Icons.celebration,
      'Shirt': Icons.child_care, 'Frock': Icons.child_friendly, 'Dress': Icons.face, 'Bridal': Icons.favorite,
      'Party Wear': Icons.party_mode, 'Formal': Icons.work, 'Couture': Icons.star,
    };
    return icons[name] ?? Icons.checkroom;
  }

  Widget _buildFeaturedTailors() {
    if (_filteredFeaturedTailors.isEmpty) {
      if (_selectedCategoryId != null) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('No featured tailors found for this category', style: TextStyle(fontSize: 15, color: Colors.grey.shade600), textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      }
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.brown.shade700, size: 20),
              const SizedBox(width: 8),
              Text('Featured Tailors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              if (_selectedCategoryId != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Text('${_filteredFeaturedTailors.length}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red.shade400)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _filteredFeaturedTailors.length,
            itemBuilder: (context, index) => _buildTailorCard(_filteredFeaturedTailors[index], isHorizontal: true),
          ),
        ),
      ],
    );
  }

  Widget _buildAllTailors() {
    if (_filteredAllTailors.isEmpty) {
      if (_selectedCategoryId != null) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('No tailors found for this category', style: TextStyle(fontSize: 15, color: Colors.grey.shade600), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _filterTailorsByCategory(null),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade400, side: BorderSide(color: Colors.red.shade400)),
                  child: const Text('Clear Filter'),
                ),
              ],
            ),
          ),
        );
      }
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text('Tailors for your service', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _selectedCategoryId != null ? Colors.red.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '(${_filteredAllTailors.length})',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _selectedCategoryId != null ? Colors.red.shade400 : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedCategoryId != null)
                TextButton.icon(
                  onPressed: () => _filterTailorsByCategory(null),
                  icon: Icon(Icons.clear, size: 16, color: Colors.red.shade400),
                  label: Text('Clear', style: TextStyle(fontSize: 13, color: Colors.red.shade400)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 32)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedCategoryId != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade200)),
              child: Row(
                children: [
                  Icon(Icons.filter_alt, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Filtered by category', style: TextStyle(fontSize: 13, color: Colors.blue.shade700, fontWeight: FontWeight.w500))),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Filters', Icons.filter_list),
                const SizedBox(width: 8),
                _buildFilterChip('Sort By', Icons.sort),
                const SizedBox(width: 8),
                _buildFilterChip('within 5km', null),
                const SizedBox(width: 8),
                _buildFilterChip('Rating > 4', null),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filteredAllTailors.length,
          itemBuilder: (context, index) => _buildTailorCard(_filteredAllTailors[index], isHorizontal: false),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, IconData? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: Colors.grey.shade700), const SizedBox(width: 4)],
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTailorCard(TailorModel tailor, {required bool isHorizontal}) {
    if (isHorizontal) {
      return GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/tailor-detail', arguments: tailor.id),
        child: Container(
          width: 180,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        image: DecorationImage(image: NetworkImage(tailor.imageUrl), fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          children: [
                            Icon(Icons.currency_rupee, size: 12, color: Colors.white),
                            Text('from ₹${tailor.startingPrice.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                        child: Icon(Icons.favorite_border, size: 16, color: Colors.red.shade400),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tailor.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                            child: Row(
                              children: [
                                Icon(Icons.star, size: 12, color: Colors.green.shade700),
                                const SizedBox(width: 2),
                                Text(tailor.rating.toString(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text('(${tailor.reviewCount})', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade600),
                          Text('${tailor.distance} km', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                          Expanded(child: Text(tailor.deliveryTime, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(tailor.specialties.join(', '), style: TextStyle(fontSize: 10, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/tailor-detail', arguments: tailor.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        image: DecorationImage(image: NetworkImage(tailor.imageUrl), fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            Icon(Icons.currency_rupee, size: 14, color: Colors.white),
                            Text('from ₹${tailor.startingPrice.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.favorite_border, size: 20, color: Colors.red.shade400),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(tailor.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                            child: Row(
                              children: [
                                Icon(Icons.star, size: 14, color: Colors.green.shade700),
                                const SizedBox(width: 4),
                                Text(tailor.rating.toString(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.star_half, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text('${tailor.rating} (${tailor.reviewCount})', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          const SizedBox(width: 16),
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text('${tailor.distance} km', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          const SizedBox(width: 16),
                          Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(tailor.deliveryTime, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(tailor.specialties.join(', '), style: TextStyle(fontSize: 12, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildModernDrawer() {
    return Material(
      color: Colors.white,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(-5, 0))],
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                color: Colors.grey.shade50,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300, width: 2),
                          ),
                          child: ClipOval(
                            child: _userProfile?.imageUrl != null
                                ? Image.network(
                              _userProfile!.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: 40, color: Colors.grey.shade400),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade400)));
                              },
                            )
                                : Icon(Icons.person, size: 40, color: Colors.grey.shade400),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_userProfile?.profileName ?? 'Guest User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(_userProfile?.mobileNumber ?? 'Add phone number', style: TextStyle(fontSize: 14, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        // GestureDetector(
                        //   onTap: () {
                        //     Navigator.pop(context);
                        //     Navigator.pushNamed(context, '/profile-details');
                        //   },
                        //   child: Container(
                        //     padding: const EdgeInsets.all(8),
                        //     decoration: BoxDecoration(color: Colors.brown.shade50, borderRadius: BorderRadius.circular(8)),
                        //     child: Icon(Icons.edit, size: 20, color: Colors.brown.shade700),
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      child: Text('My Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                    ),
                    _buildDrawerItem(
                      icon: Icons.shopping_bag_outlined,
                      title: 'My Orders',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/my-orders');
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.location_on_outlined,
                      title: 'Saved Addresses',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/address-list');
                      },
                    ),
                    // _buildDrawerItem(
                    //   icon: Icons.payment_outlined,
                    //   title: 'Payments',
                    //   onTap: () => Navigator.pop(context),
                    // ),
                    _buildDrawerItem(
                      icon: Icons.person_outline,
                      title: 'My Profiles',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/profiles-list');
                      },
                    ),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: Colors.grey.shade200),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      child: Text('Settings & Support', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                    ),
                    // _buildDrawerItem(icon: Icons.headset_mic_outlined, title: 'Contact Us', onTap: () => Navigator.pop(context)),
                    // _buildDrawerItem(icon: Icons.share_outlined, title: 'Share App with Friends', onTap: () => Navigator.pop(context)),
                    _buildDrawerItem(
                      icon: Icons.logout_outlined,
                      title: 'Logout',
                      onTap: () {
                        Navigator.pop(context);
                        _showLogoutDialog();
                      },
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

  Widget _buildDrawerItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 22, color: Colors.grey.shade700),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87))),
            Icon(Icons.chevron_right, size: 24, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600))),
          ElevatedButton(
            onPressed: () async {
              await _clearRecentSearches();
              if (mounted) {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}