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
  });

  factory TailorDetail.fromJson(Map<String, dynamic> json) {
    Map<String, ServiceGender> servicesMap = {};
    (json['services'] as Map<String, dynamic>).forEach((key, value) {
      servicesMap[key] = ServiceGender.fromJson(value);
    });

    return TailorDetail(
      tailorId: json['tailorId'],
      name: json['name'],
      profileImage: json['profileImage'],
      rating: json['rating'].toDouble(),
      reviewCount: json['reviewCount'],
      googleRating: json['googleRating'].toDouble(),
      distance: json['distance'].toDouble(),
      deliveryTime: json['deliveryTime'],
      startingPrice: json['startingPrice'],
      tabs: List<String>.from(json['tabs']),
      services: servicesMap,
      gallery: (json['gallery'] as List)
          .map((item) => GalleryItem.fromJson(item))
          .toList(),
      reviews: (json['reviews'] as List)
          .map((item) => ReviewItem.fromJson(item))
          .toList(),
      availableSlots: (json['availableSlots'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, List<String>.from(value)),
      ),
    );
  }
}

class ServiceGender {
  final List<ServiceCategory> categories;

  ServiceGender({required this.categories});

  factory ServiceGender.fromJson(Map<String, dynamic> json) {
    return ServiceGender(
      categories: (json['categories'] as List)
          .map((item) => ServiceCategory.fromJson(item))
          .toList(),
    );
  }
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

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      isExpanded: json['isExpanded'] ?? false,
      subCategories: (json['subCategories'] as List)
          .map((item) => SubCategory.fromJson(item))
          .toList(),
    );
  }
}

class SubCategory {
  final String subCategoryId;
  final String name;
  final String image;
  final int price;
  final double rating;
  final int reviewCount;
  int quantity;

  SubCategory({
    required this.subCategoryId,
    required this.name,
    required this.image,
    required this.price,
    required this.rating,
    required this.reviewCount,
    this.quantity = 0,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      subCategoryId: json['subCategoryId'],
      name: json['name'],
      image: json['image'],
      price: json['price'],
      rating: json['rating'].toDouble(),
      reviewCount: json['reviewCount'],
      quantity: json['quantity'] ?? 0,
    );
  }
}

class GalleryItem {
  final String imageUrl;
  final String caption;

  GalleryItem({
    required this.imageUrl,
    required this.caption,
  });

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    return GalleryItem(
      imageUrl: json['imageUrl'],
      caption: json['caption'],
    );
  }
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

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      reviewId: json['reviewId'],
      userName: json['userName'],
      userImage: json['userImage'],
      rating: json['rating'].toDouble(),
      reviewText: json['reviewText'],
      date: json['date'],
      images: List<String>.from(json['images'] ?? []),
    );
  }
}