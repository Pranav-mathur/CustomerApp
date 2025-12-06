// screens/tailor_detail_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book_appointment_models.dart';
import '../models/booking_request_model.dart';
import '../models/tailor_detail_models.dart';
import '../models/updated_booking_models.dart';
import '../services/tailor_service.dart';
import '../providers/profile_provider.dart';
import '../screens/time_slot_picker.dart';

class TailorDetailScreen extends StatefulWidget {
  final String tailorId;

  const TailorDetailScreen({
    Key? key,
    required this.tailorId,
  }) : super(key: key);

  @override
  State<TailorDetailScreen> createState() => _TailorDetailScreenState();
}

class _TailorDetailScreenState extends State<TailorDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TailorDetail? tailorDetail;
  bool isLoading = true;
  String? errorMessage;
  String selectedGender = 'Men';
  List<String> genderTabs = ['Men', 'Women', 'Kids', 'Designers'];
  String? selectedDate;
  String? selectedTime;
  int totalItems = 0;

  final TailorService _tailorService = TailorService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTailorDetail();
  }

  Future<void> _loadTailorDetail() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final detail = await _tailorService.getTailorDetail(widget.tailorId);
      print(detail.services);
      print('\n=== GALLERY DATA (JSON) ===');
      final galleryJson = detail.gallery.map((item) => {
        'imageUrl': item.imageUrl,
      }).toList();
      print(JsonEncoder.withIndent('  ').convert(galleryJson));

      setState(() {
        tailorDetail = detail;
        isLoading = false;
        _calculateTotalItems();
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  void _calculateTotalItems() {
    if (tailorDetail == null) return;

    int total = 0;
    tailorDetail!.services.forEach((gender, serviceGender) {
      for (var category in serviceGender.categories) {
        for (var subCategory in category.subCategories) {
          total += subCategory.quantity;
        }
      }
    });
    setState(() {
      totalItems = total;
    });
  }

  void _updateQuantity(String gender, String categoryId, String subCategoryId, int change) {
    if (tailorDetail == null) return;

    setState(() {
      final serviceGender = tailorDetail!.services[gender];
      if (serviceGender != null) {
        final category = serviceGender.categories
            .firstWhere((cat) => cat.categoryId == categoryId);
        final subCategory = category.subCategories
            .firstWhere((sub) => sub.subCategoryId == subCategoryId);

        int newQuantity = subCategory.quantity + change;
        if (newQuantity >= 0) {
          subCategory.quantity = newQuantity;
          _calculateTotalItems();
        }
      }
    });
  }

  void _toggleCategory(String gender, String categoryId) {
    if (tailorDetail == null) return;

    setState(() {
      final serviceGender = tailorDetail!.services[gender];
      if (serviceGender != null) {
        final category = serviceGender.categories
            .firstWhere((cat) => cat.categoryId == categoryId);
        category.isExpanded = !category.isExpanded;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? _buildLoadingState()
            : errorMessage != null
            ? _buildErrorState()
            : tailorDetail == null
            ? _buildEmptyState()
            : Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildServicesTab(),
                  _buildGalleryTab(),
                  _buildReviewsTab(),
                ],
              ),
            ),
            if (totalItems > 0) _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.08,
          vertical: 24,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: screenWidth * 0.16,
              color: Colors.red.shade400,
            ),
            SizedBox(height: screenWidth * 0.04),
            Text(
              'Failed to load tailor details',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: screenWidth * 0.02),
            Text(
              errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: screenWidth * 0.06),
            ElevatedButton(
              onPressed: _loadTailorDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.08,
                  vertical: 12,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('No tailor details available'),
    );
  }

  Widget _buildHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: screenWidth * 0.06,
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tailorDetail!.name,
                      style: TextStyle(
                        fontSize: screenWidth * 0.053,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Row(
                      children: [
                        Text(
                          tailorDetail!.rating.toString(),
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        ...List.generate(
                          5,
                              (index) => Icon(
                            Icons.star,
                            size: screenWidth * 0.035,
                            color: index < tailorDetail!.rating.floor()
                                ? Colors.orange
                                : Colors.grey.shade300,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        Flexible(
                          child: Text(
                            '(${tailorDetail!.reviewCount})',
                            style: TextStyle(
                              fontSize: screenWidth * 0.032,
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
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.025,
                  vertical: screenHeight * 0.006,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/480px-Google_%22G%22_logo.svg.png',
                      width: screenWidth * 0.04,
                      height: screenWidth * 0.04,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.star, size: screenWidth * 0.04),
                    ),
                    SizedBox(width: screenWidth * 0.015),
                    Text(
                      tailorDetail!.googleRating.toString(),
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildInfoChip(
                  Icons.people_outline,
                  '${tailorDetail!.distance.toStringAsFixed(1)} km',
                  screenWidth,
                ),
                SizedBox(width: screenWidth * 0.04),
                _buildInfoChip(
                  Icons.shopping_bag_outlined,
                  tailorDetail!.deliveryTime,
                  screenWidth,
                ),
                SizedBox(width: screenWidth * 0.04),
                _buildInfoChip(
                  Icons.camera_alt_outlined,
                  'from ₹${tailorDetail!.startingPrice}',
                  screenWidth,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, double screenWidth) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: screenWidth * 0.04, color: Colors.grey.shade600),
        SizedBox(width: screenWidth * 0.01),
        Text(
          text,
          style: TextStyle(
            fontSize: screenWidth * 0.032,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.red.shade400,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: TextStyle(
          fontSize: screenWidth * 0.038,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: screenWidth * 0.038,
          fontWeight: FontWeight.normal,
        ),
        indicatorColor: Colors.red.shade400,
        indicatorWeight: 3,
        tabs: [
          Tab(
            icon: Icon(Icons.grid_view, size: screenWidth * 0.05),
            text: 'Services',
          ),
          Tab(
            icon: Icon(Icons.photo_library_outlined, size: screenWidth * 0.05),
            text: 'Gallery',
          ),
          Tab(
            icon: Icon(Icons.star_outline, size: screenWidth * 0.05),
            text: 'Reviews',
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    return Column(
      children: [
        _buildGenderSelector(),
        Expanded(
          child: _buildServicesList(),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final itemWidth = screenWidth * 0.22;
    final itemHeight = screenHeight * 0.18;

    return Container(
      height: itemHeight,
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        itemCount: genderTabs.length,
        itemBuilder: (context, index) {
          final gender = genderTabs[index];
          final isSelected = selectedGender == gender;

          String imageUrl;
          Color bgColor;

          switch (gender) {
            case 'Men':
              imageUrl = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d';
              bgColor = Colors.green.shade100;
              break;
            case 'Women':
              imageUrl = 'https://images.unsplash.com/photo-1494790108377-be9c29b29330';
              bgColor = Colors.orange.shade100;
              break;
            case 'Kids':
              imageUrl = 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9';
              bgColor = Colors.pink.shade100;
              break;
            case 'Designers':
              imageUrl = 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d';
              bgColor = Colors.purple.shade100;
              break;
            default:
              imageUrl = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d';
              bgColor = Colors.grey.shade100;
          }

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedGender = gender;
              });
            },
            child: Container(
              width: itemWidth,
              margin: EdgeInsets.only(right: screenWidth * 0.03),
              child: Column(
                children: [
                  Container(
                    width: itemWidth,
                    height: itemWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: bgColor,
                      border: Border.all(
                        color: isSelected ? Colors.red.shade400 : Colors.transparent,
                        width: 2,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.008),
                  Text(
                    gender,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.red.shade400 : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServicesList() {
    final serviceGender = tailorDetail!.services[selectedGender];
    if (serviceGender == null || serviceGender.categories.isEmpty) {
      return Center(
        child: Text(
          'No services available',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      itemCount: serviceGender.categories.length,
      itemBuilder: (context, index) {
        final category = serviceGender.categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(ServiceCategory category) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleCategory(selectedGender, category.categoryId),
            child: Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      category.categoryName,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    category.isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                    size: screenWidth * 0.06,
                  ),
                ],
              ),
            ),
          ),
          if (category.isExpanded)
            ...category.subCategories.map((subCategory) {
              return _buildSubCategoryItem(category.categoryId, subCategory);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildSubCategoryItem(String categoryId, SubCategory subCategory) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final imageSize = screenWidth * 0.18;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(subCategory.image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subCategory.name,
                  style: TextStyle(
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: screenHeight * 0.005),
                Wrap(
                  spacing: screenWidth * 0.02,
                  runSpacing: screenHeight * 0.005,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '₹${subCategory.price}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.036,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: screenWidth * 0.03,
                          color: Colors.orange,
                        ),
                        SizedBox(width: screenWidth * 0.005),
                        Text(
                          '${subCategory.rating}',
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          ' (${subCategory.reviewCount})',
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          if (subCategory.quantity == 0)
            OutlinedButton(
              onPressed: () => _updateQuantity(
                selectedGender,
                categoryId,
                subCategory.subCategoryId,
                1,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade400,
                side: BorderSide(color: Colors.red.shade400),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: screenHeight * 0.008,
                ),
                minimumSize: Size(screenWidth * 0.16, screenHeight * 0.04),
              ),
              child: Text(
                '+ Add',
                style: TextStyle(
                  fontSize: screenWidth * 0.032,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.remove,
                      size: screenWidth * 0.045,
                      color: Colors.white,
                    ),
                    onPressed: () => _updateQuantity(
                      selectedGender,
                      categoryId,
                      subCategory.subCategoryId,
                      -1,
                    ),
                    padding: EdgeInsets.all(screenWidth * 0.01),
                    constraints: BoxConstraints(
                      minWidth: screenWidth * 0.08,
                      minHeight: screenWidth * 0.08,
                    ),
                  ),
                  Container(
                    constraints: BoxConstraints(minWidth: screenWidth * 0.06),
                    child: Text(
                      '${subCategory.quantity}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add,
                      size: screenWidth * 0.045,
                      color: Colors.white,
                    ),
                    onPressed: () => _updateQuantity(
                      selectedGender,
                      categoryId,
                      subCategory.subCategoryId,
                      1,
                    ),
                    padding: EdgeInsets.all(screenWidth * 0.01),
                    constraints: BoxConstraints(
                      minWidth: screenWidth * 0.08,
                      minHeight: screenWidth * 0.08,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGalleryTab() {
    final screenWidth = MediaQuery.of(context).size.width;

    if (tailorDetail!.gallery.isEmpty) {
      return Center(
        child: Text(
          'No gallery images available',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(screenWidth * 0.04),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: screenWidth < 360 ? 2 : 2,
        crossAxisSpacing: screenWidth * 0.03,
        mainAxisSpacing: screenWidth * 0.03,
        childAspectRatio: 0.8,
      ),
      itemCount: tailorDetail!.gallery.length,
      itemBuilder: (context, index) {
        final item = tailorDetail!.gallery[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: NetworkImage(item.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (tailorDetail!.reviews.isEmpty) {
      return Center(
        child: Text(
          'No reviews available',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(screenWidth * 0.04),
      itemCount: tailorDetail!.reviews.length,
      itemBuilder: (context, index) {
        final review = tailorDetail!.reviews[index];
        return Container(
          margin: EdgeInsets.only(bottom: screenWidth * 0.04),
          padding: EdgeInsets.all(screenWidth * 0.04),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: screenWidth * 0.06,
                    backgroundImage: NetworkImage(review.userImage),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.userName,
                          style: TextStyle(
                            fontSize: screenWidth * 0.038,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: screenHeight * 0.005),
                        Row(
                          children: [
                            ...List.generate(
                              5,
                                  (i) => Icon(
                                Icons.star,
                                size: screenWidth * 0.035,
                                color: i < review.rating.floor()
                                    ? Colors.orange
                                    : Colors.grey.shade300,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Flexible(
                              child: Text(
                                review.date,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.03,
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
                ],
              ),
              SizedBox(height: screenHeight * 0.012),
              Text(
                review.reviewText,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              if (review.images.isNotEmpty) ...[
                SizedBox(height: screenHeight * 0.012),
                SizedBox(
                  height: screenWidth * 0.2,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: review.images.length,
                    itemBuilder: (context, i) {
                      return Container(
                        width: screenWidth * 0.2,
                        margin: EdgeInsets.only(right: screenWidth * 0.02),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(review.images[i]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final hasTimeSlot = selectedDate != null && selectedTime != null;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: screenWidth * 0.05,
                  color: Colors.grey.shade700,
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  'Appointment Time',
                  style: TextStyle(
                    fontSize: screenWidth * 0.036,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.008),
            Row(
              children: [
                Text(
                  'Fabric pickup & measurement',
                  style: TextStyle(
                    fontSize: screenWidth * 0.032,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.015),
            InkWell(
              onTap: _showTimeSlotPicker,
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: hasTimeSlot ? Colors.grey.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasTimeSlot ? Colors.grey.shade300 : Colors.orange.shade300,
                    width: hasTimeSlot ? 1 : 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: screenWidth * 0.045,
                      color: hasTimeSlot ? Colors.grey.shade600 : Colors.orange.shade700,
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasTimeSlot ? selectedDate! : 'Choose Time Slot',
                            style: TextStyle(
                              fontSize: screenWidth * 0.038,
                              fontWeight: FontWeight.bold,
                              color: hasTimeSlot ? Colors.black87 : Colors.orange.shade700,
                            ),
                          ),
                          if (hasTimeSlot) ...[
                            SizedBox(height: screenHeight * 0.003),
                            Text(
                              selectedTime!,
                              style: TextStyle(
                                fontSize: screenWidth * 0.032,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ] else ...[
                            SizedBox(height: screenHeight * 0.003),
                            Text(
                              'Tap to select date and time',
                              style: TextStyle(
                                fontSize: screenWidth * 0.032,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: screenWidth * 0.06,
                      color: hasTimeSlot ? Colors.grey.shade600 : Colors.orange.shade700,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: hasTimeSlot ? _navigateToBookAppointment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isVerySmall = constraints.maxWidth < 300;

                    if (isVerySmall) {
                      // Stack layout for very small screens
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$totalItems Selected',
                            style: TextStyle(
                              fontSize: screenWidth * 0.038,
                              fontWeight: FontWeight.bold,
                              color: hasTimeSlot ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Book Appointment',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.038,
                                  fontWeight: FontWeight.bold,
                                  color: hasTimeSlot ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Icon(
                                Icons.arrow_forward,
                                color: hasTimeSlot ? Colors.white : Colors.grey.shade600,
                                size: screenWidth * 0.05,
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    // Horizontal layout for normal screens
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$totalItems Selected',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.bold,
                            color: hasTimeSlot ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.04),
                        Container(
                          width: 1,
                          height: screenHeight * 0.025,
                          color: hasTimeSlot
                              ? Colors.white.withOpacity(0.5)
                              : Colors.grey.shade400,
                        ),
                        SizedBox(width: screenWidth * 0.04),
                        Flexible(
                          child: Text(
                            'Book Appointment',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                              color: hasTimeSlot ? Colors.white : Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Icon(
                          Icons.arrow_forward,
                          color: hasTimeSlot ? Colors.white : Colors.grey.shade600,
                          size: screenWidth * 0.05,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeSlotPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TimeSlotPicker(
        initialDate: selectedDate,
        initialTime: selectedTime,
        onConfirm: (date, time) {
          setState(() {
            selectedDate = date;
            selectedTime = time;
          });
        },
      ),
    );
  }

  DateTime _parseDateTime(String date, String time) {
    DateTime baseDate;
    final now = DateTime.now();

    if (date.toLowerCase() == 'today') {
      baseDate = now;
    } else if (date.toLowerCase() == 'tomorrow') {
      baseDate = now.add(const Duration(days: 1));
    } else {
      try {
        baseDate = now;
      } catch (e) {
        baseDate = now;
      }
    }

    try {
      final timeParts = time.split(' ');
      final hourMin = timeParts[0].split(':');
      int hour = int.parse(hourMin[0]);
      final minute = int.parse(hourMin[1]);
      final isPM = timeParts.length > 1 && timeParts[1].toUpperCase() == 'PM';

      if (isPM && hour != 12) {
        hour += 12;
      } else if (!isPM && hour == 12) {
        hour = 0;
      }

      return DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        hour,
        minute,
      );
    } catch (e) {
      return DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        now.hour,
        now.minute,
      );
    }
  }

  void _navigateToBookAppointment() {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time slot first'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    List<BookingCategoryExtended> bookingCategories = [];

    tailorDetail!.services.forEach((gender, serviceGender) {
      for (var category in serviceGender.categories) {
        for (var subCategory in category.subCategories) {
          if (subCategory.quantity > 0) {
            bookingCategories.add(
              BookingCategoryExtended(
                gender: gender,
                categoryId: category.categoryId,
                subCategoryName: subCategory.name,
                quantity: subCategory.quantity,
                subCategoryId: subCategory.subCategoryId,
                serviceName: subCategory.name,
                image: subCategory.image,
                price: subCategory.price,
              ),
            );
          }
        }
      }
    });

    if (bookingCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one service'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final totalTailoring = bookingCategories.fold<int>(
      0,
          (sum, category) => sum + category.totalPrice,
    );

    final paymentBreakup = PaymentBreakup.calculate(
      totalTailoring: totalTailoring,
    );

    final requestedDateTime = _parseDateTime(selectedDate!, selectedTime!);

    final bookingData = BookingDataV2(
      tailorId: tailorDetail!.tailorId,
      tailorName: tailorDetail!.name,
      categories: bookingCategories,
      pickupDate: selectedDate!,
      pickupTime: selectedTime!,
      requestedDateTime: requestedDateTime,
      paymentBreakup: paymentBreakup,
    );

    Navigator.pushNamed(
      context,
      '/book-appointment',
      arguments: bookingData,
    );
  }
}