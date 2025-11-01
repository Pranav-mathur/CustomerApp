// models/tailor_detail_models.dart

class TailorDetail {
  final String tailorId;
  final String name;
  final String profileImage;
  final double rating;
  final int reviewCount;
  final double googleRating;
  final double distance;
  final String deliveryTime;
  final int startingPrice;
  final List<String> tabs;
  final Map<String, ServiceGender> services;
  final List<GalleryItem> gallery;
  final List<ReviewItem> reviews;
  final Map<String, List<String>> availableSlots;
  final TailorAddress? address;
  final TailorLocation? location;

  TailorDetail({
    required this.tailorId,
    required this.name,
    required this.profileImage,
    required this.rating,
    required this.reviewCount,
    required this.googleRating,
    required this.distance,
    required this.deliveryTime,
    required this.startingPrice,
    required this.tabs,
    required this.services,
    required this.gallery,
    required this.reviews,
    required this.availableSlots,
    this.address,
    this.location,
  });

  factory TailorDetail.fromApiResponse(Map<String, dynamic> json) {
    final tailorData = json['tailor'] as Map<String, dynamic>;

    // Extract rating info
    final ratingsData = tailorData['ratingsAndReviews'] as Map<String, dynamic>?;
    final avgRating = (ratingsData?['avg_rating'] ?? 4.0).toDouble();
    final reviewCount = ratingsData?['review_count'] ?? 0;

    // Parse gallery from portfolioImages
    // --- Collect gallery images from categories only ---
    final catData = tailorData['categories'] as Map<String, dynamic>? ?? {};
    List<GalleryItem> gallery = [];

    catData.forEach((gender, catList) {
      if (catList is List) {
        for (var category in catList) {
          final subCats = (category['sub_categories'] ?? []) as List;
          for (var subCat in subCats) {
            final displayImages = subCat['display_images'] as List<dynamic>? ?? [];
            for (var img in displayImages) {
              gallery.add(GalleryItem(
                imageUrl: img.toString(),
                caption: subCat['sub_category_name'] ?? '',
              ));
            }
          }
        }
      }
    });


    // Parse reviews
    final reviewsList = ratingsData?['reviews'] as List<dynamic>? ?? [];
    final reviews = reviewsList.map((review) => ReviewItem.fromApiJson(review)).toList();

    // Parse categories and convert to services map
    final categoriesData = tailorData['categories'] as Map<String, dynamic>? ?? {};
    final services = _parseCategories(categoriesData, avgRating, reviewCount);

    // Calculate starting price from all subcategories
    int minPrice = 999999;
    services.forEach((gender, serviceGender) {
      for (var category in serviceGender.categories) {
        for (var subCategory in category.subCategories) {
          if (subCategory.price < minPrice) {
            minPrice = subCategory.price;
          }
        }
      }
    });
    if (minPrice == 999999) minPrice = 899;

    // Get first delivery time from categories
    String deliveryTime = '5 days delivery';
    bool foundDeliveryTime = false;
    services.forEach((gender, serviceGender) {
      if (!foundDeliveryTime && serviceGender.categories.isNotEmpty) {
        final firstCategory = serviceGender.categories.first;
        if (firstCategory.subCategories.isNotEmpty) {
          deliveryTime = firstCategory.subCategories.first.deliveryTime;
          foundDeliveryTime = true;
        }
      }
    });

    // Parse address
    final addressData = tailorData['address'] as Map<String, dynamic>?;
    final address = addressData != null ? TailorAddress.fromJson(addressData) : null;

    // Parse location
    final locationData = tailorData['location'] as Map<String, dynamic>?;
    final location = locationData != null ? TailorLocation.fromJson(locationData) : null;

    // Calculate distance (default to 0.52 km if not available)
    final distance = 0.52; // You can calculate this based on user location and tailor location

    return TailorDetail(
      tailorId: tailorData['id'] ?? '',
      name: tailorData['name'] ?? '',
      profileImage: tailorData['profile_pic'] ?? '',
      rating: avgRating,
      reviewCount: reviewCount,
      googleRating: avgRating, // Using same rating as Google rating
      distance: distance,
      deliveryTime: deliveryTime,
      startingPrice: minPrice,
      tabs: ['Services', 'Gallery', 'Reviews'],
      services: services,
      gallery: gallery,
      reviews: reviews,
      availableSlots: {
        'today': ['12:00 PM', '2:00 PM', '4:00 PM', '6:00 PM'],
        'tomorrow': ['10:00 AM', '12:00 PM', '2:00 PM', '4:00 PM', '6:00 PM'],
        'dayAfterTomorrow': ['10:00 AM', '12:00 PM', '2:00 PM', '4:00 PM'],
      },
      address: address,
      location: location,
    );
  }

  static Map<String, ServiceGender> _parseCategories(
      Map<String, dynamic> categoriesData,
      double defaultRating,
      int defaultReviewCount,
      ) {
    Map<String, ServiceGender> services = {};

    // Map API gender keys to display names
    final genderMap = {
      'men': 'Men',
      'women': 'Women',
      'kids': 'Kids',
    };

    genderMap.forEach((apiGender, displayGender) {
      final genderCategories = categoriesData[apiGender] as List<dynamic>? ?? [];

      if (genderCategories.isNotEmpty) {
        final categories = genderCategories.map((cat) {
          final categoryData = cat as Map<String, dynamic>;
          final subCategoriesList = categoryData['sub_categories'] as List<dynamic>? ?? [];

          final subCategories = subCategoriesList.asMap().entries.map((entry) {
            final index = entry.key;
            final subCat = entry.value as Map<String, dynamic>;

            // Get first display image or use default
            final displayImages = subCat['display_images'] as List<dynamic>? ?? [];
            final imageUrl = displayImages.isNotEmpty
                ? displayImages[0].toString()
                : 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf';

            return SubCategory(
              subCategoryId: '${categoryData['category_id']}_$index',
              name: subCat['sub_category_name'] ?? '',
              image: imageUrl,
              price: subCat['price'] ?? 0,
              rating: defaultRating,
              reviewCount: defaultReviewCount,
              quantity: 0,
              deliveryTime: subCat['delivery_time'] ?? '5 Days',
            );
          }).toList();

          return ServiceCategory(
            categoryId: categoryData['category_id'] ?? '',
            categoryName: categoryData['category_name'] ?? '',
            isExpanded: false,
            subCategories: subCategories,
          );
        }).toList();

        services[displayGender] = ServiceGender(categories: categories);
      }
    });

    return services;
  }
}

class TailorAddress {
  final String street;
  final String city;
  final String state;
  final String pincode;
  final String mobile;

  TailorAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
    required this.mobile,
  });

  factory TailorAddress.fromJson(Map<String, dynamic> json) {
    return TailorAddress(
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      mobile: json['mobile'] ?? '',
    );
  }

  String get fullAddress => '$street, $city, $state - $pincode';
}

class TailorLocation {
  final double latitude;
  final double longitude;

  TailorLocation({
    required this.latitude,
    required this.longitude,
  });

  factory TailorLocation.fromJson(Map<String, dynamic> json) {
    return TailorLocation(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }
}

class ServiceGender {
  final List<ServiceCategory> categories;

  ServiceGender({required this.categories});
}

class ServiceCategory {
  final String categoryId;
  final String categoryName;
  bool isExpanded;
  final List<SubCategory> subCategories;

  ServiceCategory({
    required this.categoryId,
    required this.categoryName,
    required this.isExpanded,
    required this.subCategories,
  });
}

class SubCategory {
  final String subCategoryId;
  final String name;
  final String image;
  final int price;
  final double rating;
  final int reviewCount;
  int quantity;
  final String deliveryTime;

  SubCategory({
    required this.subCategoryId,
    required this.name,
    required this.image,
    required this.price,
    required this.rating,
    required this.reviewCount,
    this.quantity = 0,
    required this.deliveryTime,
  });

  int get totalPrice => price * quantity;
}

class GalleryItem {
  final String imageUrl;
  final String caption;

  GalleryItem({
    required this.imageUrl,
    required this.caption,
  });
}

class ReviewItem {
  final String reviewId;
  final String userName;
  final String userImage;
  final double rating;
  final String reviewText;
  final String date;
  final List<String> images;

  ReviewItem({
    required this.reviewId,
    required this.userName,
    required this.userImage,
    required this.rating,
    required this.reviewText,
    required this.date,
    required this.images,
  });

  factory ReviewItem.fromApiJson(Map<String, dynamic> json) {
    final userData = json['user'] as Map<String, dynamic>? ?? {};

    // Format the date
    String formattedDate = 'N/A';
    if (json['created_at'] != null) {
      try {
        final dateTime = DateTime.parse(json['created_at']);
        formattedDate = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      } catch (e) {
        formattedDate = json['created_at'].toString().split('T')[0];
      }
    }

    return ReviewItem(
      reviewId: json['id'] ?? '',
      userName: userData['name'] ?? 'Anonymous',
      userImage: userData['profile_pic'] ?? 'https://i.pravatar.cc/150?img=1',
      rating: (json['rating'] ?? 0).toDouble(),
      reviewText: json['review_text'] ?? '',
      date: formattedDate,
      images: [], // API doesn't have review images in current structure
    );
  }
}