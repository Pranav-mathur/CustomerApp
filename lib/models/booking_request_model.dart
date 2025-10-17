// models/booking_request_model.dart

class BookingRequest {
  final String profileId;
  final String tailorId;
  final String requestedDateTime;
  final List<BookingCategory> categories;
  final List<String>? referenceImages;

  BookingRequest({
    required this.profileId,
    required this.tailorId,
    required this.requestedDateTime,
    required this.categories,
    this.referenceImages,
  });

  Map<String, dynamic> toJson() {
    return {
      'profileId': profileId,
      'tailorId': tailorId,
      'requestedDateTime': requestedDateTime,
      'categories': categories.map((c) => c.toJson()).toList(),
      if (referenceImages != null && referenceImages!.isNotEmpty)
        'referenceImages': referenceImages,
    };
  }
}

class BookingCategory {
  final String gender;
  final String categoryId;
  final String subCategoryName;
  final int quantity;

  BookingCategory({
    required this.gender,
    required this.categoryId,
    required this.subCategoryName,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'gender': gender.toLowerCase(), // Convert to lowercase for API
      'categoryId': categoryId,
      'subCategoryName': subCategoryName,
      'quantity': quantity,
    };
  }
}

// Extended model for internal use with additional fields
class BookingCategoryExtended extends BookingCategory {
  final String subCategoryId;
  final String serviceName;
  final String image;
  final int price;
  String? tag;
  String? reference;

  BookingCategoryExtended({
    required super.gender,
    required super.categoryId,
    required super.subCategoryName,
    required super.quantity,
    required this.subCategoryId,
    required this.serviceName,
    required this.image,
    required this.price,
    this.tag,
    this.reference,
  });

  int get totalPrice => price * quantity;

  BookingCategoryExtended copyWith({
    String? gender,
    String? categoryId,
    String? subCategoryName,
    int? quantity,
    String? subCategoryId,
    String? serviceName,
    String? image,
    int? price,
    String? tag,
    String? reference,
  }) {
    return BookingCategoryExtended(
      gender: gender ?? this.gender,
      categoryId: categoryId ?? this.categoryId,
      subCategoryName: subCategoryName ?? this.subCategoryName,
      quantity: quantity ?? this.quantity,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      serviceName: serviceName ?? this.serviceName,
      image: image ?? this.image,
      price: price ?? this.price,
      tag: tag ?? this.tag,
      reference: reference ?? this.reference,
    );
  }
}