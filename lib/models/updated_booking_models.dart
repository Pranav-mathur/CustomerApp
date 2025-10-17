// models/updated_booking_models.dart

import 'address_model.dart';
import 'booking_request_model.dart';
import 'address_models.dart';

class BookingDataV2 {
  final String tailorId;
  final String tailorName;
  final List<BookingCategoryExtended> categories;
  final String pickupDate;
  final String pickupTime;
  final DateTime requestedDateTime;
  final AddressModel? selectedAddress;
  final PaymentBreakup paymentBreakup;
  final bool bringOwnFabric;

  BookingDataV2({
    required this.tailorId,
    required this.tailorName,
    required this.categories,
    required this.pickupDate,
    required this.pickupTime,
    required this.requestedDateTime,
    this.selectedAddress,
    required this.paymentBreakup,
    this.bringOwnFabric = false,
  });

  BookingDataV2 copyWith({
    String? tailorId,
    String? tailorName,
    List<BookingCategoryExtended>? categories,
    String? pickupDate,
    String? pickupTime,
    DateTime? requestedDateTime,
    AddressModel? selectedAddress,
    PaymentBreakup? paymentBreakup,
    bool? bringOwnFabric,
  }) {
    return BookingDataV2(
      tailorId: tailorId ?? this.tailorId,
      tailorName: tailorName ?? this.tailorName,
      categories: categories ?? this.categories,
      pickupDate: pickupDate ?? this.pickupDate,
      pickupTime: pickupTime ?? this.pickupTime,
      requestedDateTime: requestedDateTime ?? this.requestedDateTime,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      paymentBreakup: paymentBreakup ?? this.paymentBreakup,
      bringOwnFabric: bringOwnFabric ?? this.bringOwnFabric,
    );
  }

  // Convert to API format
  BookingRequest toBookingRequest() {
    if (selectedAddress == null) {
      throw Exception('Address must be selected before creating booking request');
    }

    return BookingRequest(
      profileId: selectedAddress?.id ?? "",
      tailorId: tailorId,
      requestedDateTime: requestedDateTime.toIso8601String(),
      categories: categories.map((cat) => BookingCategory(
        gender: cat.gender,
        categoryId: cat.categoryId,
        subCategoryName: cat.subCategoryName,
        quantity: cat.quantity,
      )).toList(),
      referenceImages: _getReferencesWithImages(),
    );
  }

  List<String>? _getReferencesWithImages() {
    // Collect all reference images if any
    // For now returning null, but you can implement image collection logic
    return null;
  }
}

class PaymentBreakup {
  final int totalTailoring;
  final int pickupFee;
  final int tax;
  final int discount;
  final int totalAmount;

  PaymentBreakup({
    required this.totalTailoring,
    required this.pickupFee,
    required this.tax,
    required this.discount,
    required this.totalAmount,
  });

  factory PaymentBreakup.calculate({
    required int totalTailoring,
    int pickupFee = 50,
    double taxRate = 0.05,
    int discount = 0,
  }) {
    final tax = (totalTailoring * taxRate).round();
    final totalAmount = totalTailoring + pickupFee + tax - discount;

    return PaymentBreakup(
      totalTailoring: totalTailoring,
      pickupFee: pickupFee,
      tax: tax,
      discount: discount,
      totalAmount: totalAmount,
    );
  }
}