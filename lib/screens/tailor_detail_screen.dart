// screens/tailor_detail_screen.dart

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
  List<String> genderTabs = ['Men', 'Women', 'Kids'];
  String? selectedDate; // Changed to nullable
  String? selectedTime; // Changed to nullable
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load tailor details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadTailorDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
    return Container(
      padding: const EdgeInsets.all(16),
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
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tailorDetail!.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          tailorDetail!.rating.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        ...List.generate(
                          5,
                              (index) => Icon(
                            Icons.star,
                            size: 14,
                            color: index < tailorDetail!.rating.floor()
                                ? Colors.orange
                                : Colors.grey.shade300,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${tailorDetail!.reviewCount})',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/480px-Google_%22G%22_logo.svg.png',
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tailorDetail!.googleRating.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.people_outline, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${tailorDetail!.distance.toStringAsFixed(2)} km',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 16),
              Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                tailorDetail!.deliveryTime,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 16),
              Icon(Icons.camera_alt_outlined, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                'starts from ₹${tailorDetail!.startingPrice}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
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
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        indicatorColor: Colors.red.shade400,
        indicatorWeight: 3,
        tabs: const [
          Tab(
            icon: Icon(Icons.grid_view, size: 20),
            text: 'Services',
          ),
          Tab(
            icon: Icon(Icons.photo_library_outlined, size: 20),
            text: 'Gallery',
          ),
          Tab(
            icon: Icon(Icons.star_outline, size: 20),
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
    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
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
                  const SizedBox(height: 8),
                  Text(
                    gender,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.red.shade400 : Colors.black87,
                    ),
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
      padding: const EdgeInsets.all(16),
      itemCount: serviceGender.categories.length,
      itemBuilder: (context, index) {
        final category = serviceGender.categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(ServiceCategory category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      category.categoryName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    category.isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(subCategory.image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subCategory.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₹${subCategory.price}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.star, size: 12, color: Colors.orange),
                    const SizedBox(width: 2),
                    Text(
                      '${subCategory.rating}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '(${subCategory.reviewCount})',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(70, 36),
              ),
              child: const Text(
                '+ Add',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18, color: Colors.white),
                    onPressed: () => _updateQuantity(
                      selectedGender,
                      categoryId,
                      subCategory.subCategoryId,
                      -1,
                    ),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 24),
                    child: Text(
                      '${subCategory.quantity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    onPressed: () => _updateQuantity(
                      selectedGender,
                      categoryId,
                      subCategory.subCategoryId,
                      1,
                    ),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGalleryTab() {
    if (tailorDetail!.gallery.isEmpty) {
      return Center(
        child: Text(
          'No gallery images available',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
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
    if (tailorDetail!.reviews.isEmpty) {
      return Center(
        child: Text(
          'No reviews available',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tailorDetail!.reviews.length,
      itemBuilder: (context, index) {
        final review = tailorDetail!.reviews[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(review.userImage),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.userName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            ...List.generate(
                              5,
                                  (i) => Icon(
                                Icons.star,
                                size: 14,
                                color: i < review.rating.floor()
                                    ? Colors.orange
                                    : Colors.grey.shade300,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              review.date,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                review.reviewText,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              if (review.images.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: review.images.length,
                    itemBuilder: (context, i) {
                      return Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 8),
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
    // Check if time slot is selected
    final bool hasTimeSlot = selectedDate != null && selectedTime != null;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(
                'Appointment Time',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Fabric pickup & measurement',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _showTimeSlotPicker,
            child: Container(
              padding: const EdgeInsets.all(16),
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
                    size: 18,
                    color: hasTimeSlot ? Colors.grey.shade600 : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasTimeSlot ? selectedDate! : 'Choose Time Slot',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: hasTimeSlot ? Colors.black87 : Colors.orange.shade700,
                          ),
                        ),
                        if (hasTimeSlot) ...[
                          const SizedBox(height: 2),
                          Text(
                            selectedTime!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 2),
                          Text(
                            'Tap to select date and time',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: hasTimeSlot ? Colors.grey.shade600 : Colors.orange.shade700,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasTimeSlot ? _navigateToBookAppointment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$totalItems Selected',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: hasTimeSlot ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Container(
                    width: 1,
                    height: 20,
                    color: hasTimeSlot
                        ? Colors.white.withOpacity(0.5)
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 24),
                  Text(
                    'Book Appointment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: hasTimeSlot ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: hasTimeSlot ? Colors.white : Colors.grey.shade600,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
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
      // Try to parse the date string
      try {
        baseDate = now;
      } catch (e) {
        baseDate = now;
      }
    }

    // Parse time (e.g., "12:00 PM")
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
      // If time parsing fails, default to current time
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
    // Validate time slot is selected
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

    // Collect all selected services as BookingCategoryExtended
    List<BookingCategoryExtended> bookingCategories = [];

    tailorDetail!.services.forEach((gender, serviceGender) {
      for (var category in serviceGender.categories) {
        for (var subCategory in category.subCategories) {
          if (subCategory.quantity > 0) {
            bookingCategories.add(
              BookingCategoryExtended(
                gender: gender, // Men, Women, Kids
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

    // Calculate payment breakup
    final totalTailoring = bookingCategories.fold<int>(
      0,
          (sum, category) => sum + category.totalPrice,
    );

    final paymentBreakup = PaymentBreakup.calculate(
      totalTailoring: totalTailoring,
    );

    // Convert selected date and time to DateTime
    final requestedDateTime = _parseDateTime(selectedDate!, selectedTime!);

    // Create booking data
    final bookingData = BookingDataV2(
      tailorId: tailorDetail!.tailorId,
      tailorName: tailorDetail!.name,
      categories: bookingCategories,
      pickupDate: selectedDate!,
      pickupTime: selectedTime!,
      requestedDateTime: requestedDateTime,
      paymentBreakup: paymentBreakup,
    );

    // Navigate to book appointment screen
    Navigator.pushNamed(
      context,
      '/book-appointment',
      arguments: bookingData,
    );
  }
}