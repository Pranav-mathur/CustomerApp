// // models/book_appointment_models.dart
//
// class BookingData {
//   final String tailorId;
//   final String tailorName;
//   final List<SelectedService> selectedServices;
//   final String pickupDate;
//   final String pickupTime;
//   final PickupLocation? pickupLocation;
//   final bool bringOwnFabric;
//   final PaymentBreakup paymentBreakup;
//
//   BookingData({
//     required this.tailorId,
//     required this.tailorName,
//     required this.selectedServices,
//     required this.pickupDate,
//     required this.pickupTime,
//     this.pickupLocation,
//     this.bringOwnFabric = false,
//     required this.paymentBreakup,
//   });
//
//   BookingData copyWith({
//     String? tailorId,
//     String? tailorName,
//     List<SelectedService>? selectedServices,
//     String? pickupDate,
//     String? pickupTime,
//     PickupLocation? pickupLocation,
//     bool? bringOwnFabric,
//     PaymentBreakup? paymentBreakup,
//   }) {
//     return BookingData(
//       tailorId: tailorId ?? this.tailorId,
//       tailorName: tailorName ?? this.tailorName,
//       selectedServices: selectedServices ?? this.selectedServices,
//       pickupDate: pickupDate ?? this.pickupDate,
//       pickupTime: pickupTime ?? this.pickupTime,
//       pickupLocation: pickupLocation ?? this.pickupLocation,
//       bringOwnFabric: bringOwnFabric ?? this.bringOwnFabric,
//       paymentBreakup: paymentBreakup ?? this.paymentBreakup,
//     );
//   }
// }
//
// class SelectedService {
//   final String subCategoryId;
//   final String categoryName;
//   final String serviceName;
//   final String image;
//   final int price;
//   int quantity;
//   String? tag;
//   String? reference;
//
//   SelectedService({
//     required this.subCategoryId,
//     required this.categoryName,
//     required this.serviceName,
//     required this.image,
//     required this.price,
//     required this.quantity,
//     this.tag,
//     this.reference,
//   });
//
//   int get totalPrice => price * quantity;
//
//   SelectedService copyWith({
//     String? subCategoryId,
//     String? categoryName,
//     String? serviceName,
//     String? image,
//     int? price,
//     int? quantity,
//     String? tag,
//     String? reference,
//   }) {
//     return SelectedService(
//       subCategoryId: subCategoryId ?? this.subCategoryId,
//       categoryName: categoryName ?? this.categoryName,
//       serviceName: serviceName ?? this.serviceName,
//       image: image ?? this.image,
//       price: price ?? this.price,
//       quantity: quantity ?? this.quantity,
//       tag: tag ?? this.tag,
//       reference: reference ?? this.reference,
//     );
//   }
// }
//
// class PickupLocation {
//   final String addressType;
//   final String houseFlatBlock;
//   final String streetAndCity;
//
//   PickupLocation({
//     required this.addressType,
//     required this.houseFlatBlock,
//     required this.streetAndCity,
//   });
//
//   String get fullAddress {
//     return '$houseFlatBlock, $streetAndCity';
//   }
// }
//
// class PaymentBreakup {
//   final int totalTailoring;
//   final int pickupFee;
//   final int tax;
//   final int discount;
//
//   PaymentBreakup({
//     required this.totalTailoring,
//     required this.pickupFee,
//     required this.tax,
//     this.discount = 0,
//   });
//
//   int get totalAmount => totalTailoring + pickupFee + tax - discount;
//
//   factory PaymentBreakup.calculate({
//     required int totalTailoring,
//     int pickupFee = 50,
//     double taxPercentage = 0.18, // 18% GST
//     int discount = 0,
//   }) {
//     final tax = (totalTailoring * taxPercentage).round();
//     return PaymentBreakup(
//       totalTailoring: totalTailoring,
//       pickupFee: pickupFee,
//       tax: tax,
//       discount: discount,
//     );
//   }
// }