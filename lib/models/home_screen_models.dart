// models/home_screen_models.dart

class BannerModel {
  final String imageUrl;

  BannerModel({required this.imageUrl});

  factory BannerModel.fromJson(dynamic json) {
    // Handle both String and Map formats
    if (json is String) {
      return BannerModel(imageUrl: json);
    } else if (json is Map<String, dynamic>) {
      return BannerModel(imageUrl: json['imageUrl'] ?? json['image_url'] ?? '');
    }
    return BannerModel(imageUrl: '');
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String gender;
  final List<SubCategory> subCategories;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.gender,
    required this.subCategories,
    required this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      gender: json['gender'] ?? '',
      subCategories: (json['sub_categories'] as List?)
          ?.map((e) => SubCategory.fromJson(e))
          .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

class SubCategory {
  final String name;
  final String gender;
  final DateTime createdAt;

  SubCategory({
    required this.name,
    required this.gender,
    required this.createdAt,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      name: json['name'] ?? '',
      gender: json['gender'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

class TailorModel {
  final String id;
  final String name;
  final String imageUrl;
  final List<String> portfolioImages;
  final List<TailorCategory> categories;
  final TailorAddress address;
  final Location location;
  final bool isSponsored;
  final double rating;
  final int reviewCount;
  final bool isProfileComplete;
  final int deliveryDate;
  final double startingPrice;
  final BankAccount? bankAccount;
  final bool kycDone;
  final DateTime createdAt;

  TailorModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.portfolioImages,
    required this.categories,
    required this.address,
    required this.location,
    required this.isSponsored,
    required this.rating,
    required this.reviewCount,
    required this.isProfileComplete,
    required this.deliveryDate,
    required this.startingPrice,
    this.bankAccount,
    required this.kycDone,
    required this.createdAt,
  });

  // Computed properties for UI
  double get distance => 2.5; // Calculate based on location
  String get deliveryTime => '$deliveryDate days';
  List<String> get specialties =>
      categories.map((c) => c.subCategoryName).toList();

  factory TailorModel.fromJson(Map<String, dynamic> json) {
    try {
      return TailorModel(
        id: json['_id']?.toString() ?? '',
        name: json['name'] ?? 'Unknown Tailor',
        imageUrl: json['profile_pic'] ?? '',
        portfolioImages: json['portfolio_images'] != null
            ? List<String>.from(json['portfolio_images'])
            : [],
        categories: json['categories'] != null
            ? (json['categories'] as List)
            .map((e) => TailorCategory.fromJson(e as Map<String, dynamic>))
            .toList()
            : [],
        address: json['address'] != null
            ? TailorAddress.fromJson(json['address'] as Map<String, dynamic>)
            : TailorAddress(street: '', city: '', state: '', pincode: '', mobile: ''),
        location: json['location'] != null
            ? Location.fromJson(json['location'] as Map<String, dynamic>)
            : Location(type: 'Point', coordinates: [0.0, 0.0]),
        isSponsored: json['is_sponsored'] ?? false,
        rating: (json['avg_rating'] ?? 0).toDouble(),
        reviewCount: json['review_count'] ?? 0,
        isProfileComplete: json['is_profile_complete'] ?? false,
        deliveryDate: json['deliveryDate'] ?? 5,
        startingPrice: (json['startingPrice'] ?? 0).toDouble(),
        bankAccount: json['bank_account'] != null
            ? BankAccount.fromJson(json['bank_account'] as Map<String, dynamic>)
            : null,
        kycDone: json['kyc_done'] ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing TailorModel: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}

class TailorCategory {
  final String categoryId;
  final String subCategoryName;
  final double price;
  final String deliveryTime;
  final List<String> displayImages;

  TailorCategory({
    required this.categoryId,
    required this.subCategoryName,
    required this.price,
    required this.deliveryTime,
    required this.displayImages,
  });

  factory TailorCategory.fromJson(Map<String, dynamic> json) {
    return TailorCategory(
      categoryId: json['category_id']?.toString() ?? '',
      subCategoryName: json['sub_category_name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      deliveryTime: json['delivery_time'] ?? '',
      displayImages: json['display_images'] != null
          ? List<String>.from(json['display_images'])
          : [],
    );
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
      street: json['street']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
    );
  }
}

class Location {
  final String type;
  final List<double> coordinates;

  Location({
    required this.type,
    required this.coordinates,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    List<double> coords = [0.0, 0.0];

    if (json['coordinates'] != null && json['coordinates'] is List) {
      try {
        coords = (json['coordinates'] as List).map((e) => (e ?? 0).toDouble()).toList() as List<double>;
      } catch (e) {
        print('Error parsing coordinates: $e');
      }
    }

    return Location(
      type: json['type']?.toString() ?? 'Point',
      coordinates: coords,
    );
  }

  double get longitude => coordinates.isNotEmpty ? coordinates[0] : 0.0;
  double get latitude => coordinates.length > 1 ? coordinates[1] : 0.0;
}

class BankAccount {
  final String bankName;
  final String bankAccountNumber;
  final String ifscCode;
  final String accountHolderName;
  final bool isVerified;

  BankAccount({
    required this.bankName,
    required this.bankAccountNumber,
    required this.ifscCode,
    required this.accountHolderName,
    required this.isVerified,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      bankName: json['bank_name'] ?? '',
      bankAccountNumber: json['bank_account_number'] ?? '',
      ifscCode: json['ifsc_code'] ?? '',
      accountHolderName: json['account_holder_name'] ?? '',
      isVerified: json['is_verified'] ?? false,
    );
  }
}