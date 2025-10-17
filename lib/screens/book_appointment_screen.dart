// // screens/book_appointment_screen.dart
//
// import 'package:flutter/material.dart';
// import '../models/book_appointment_models.dart';
//
// class BookAppointmentScreen extends StatefulWidget {
//   final BookingData bookingData;
//
//   const BookAppointmentScreen({
//     Key? key,
//     required this.bookingData,
//   }) : super(key: key);
//
//   @override
//   State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
// }
//
// class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
//   late BookingData bookingData;
//
//   @override
//   void initState() {
//     super.initState();
//     bookingData = widget.bookingData;
//   }
//
//   void _updateServiceQuantity(String subCategoryId, int change) {
//     setState(() {
//       final serviceIndex = bookingData.selectedServices
//           .indexWhere((s) => s.subCategoryId == subCategoryId);
//
//       if (serviceIndex != -1) {
//         final currentQuantity = bookingData.selectedServices[serviceIndex].quantity;
//         final newQuantity = currentQuantity + change;
//
//         if (newQuantity > 0) {
//           bookingData.selectedServices[serviceIndex].quantity = newQuantity;
//         } else {
//           // Remove service if quantity becomes 0
//           bookingData.selectedServices.removeAt(serviceIndex);
//         }
//
//         // Recalculate payment breakup
//         _recalculatePayment();
//       }
//     });
//   }
//
//   void _updateServiceTag(String subCategoryId, String tag) {
//     setState(() {
//       final serviceIndex = bookingData.selectedServices
//           .indexWhere((s) => s.subCategoryId == subCategoryId);
//       if (serviceIndex != -1) {
//         bookingData.selectedServices[serviceIndex].tag = tag;
//       }
//     });
//   }
//
//   void _updateServiceReference(String subCategoryId, String reference) {
//     setState(() {
//       final serviceIndex = bookingData.selectedServices
//           .indexWhere((s) => s.subCategoryId == subCategoryId);
//       if (serviceIndex != -1) {
//         bookingData.selectedServices[serviceIndex].reference = reference;
//       }
//     });
//   }
//
//   void _recalculatePayment() {
//     final totalTailoring = bookingData.selectedServices
//         .fold<int>(0, (sum, service) => sum + service.totalPrice);
//
//     bookingData = bookingData.copyWith(
//       paymentBreakup: PaymentBreakup.calculate(totalTailoring: totalTailoring),
//     );
//   }
//
//   void _showAddFabricBottomSheet() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => _buildAddFabricSheet(),
//     );
//   }
//
//   void _showPickupTimeBottomSheet() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => _buildPickupTimeSheet(),
//     );
//   }
//
//   void _showPickupLocationBottomSheet() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => _buildPickupLocationSheet(),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (bookingData.selectedServices.isEmpty) {
//       // Navigate back if no services selected
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         Navigator.pop(context);
//       });
//     }
//
//     return Scaffold(
//       backgroundColor: Colors.grey.shade50,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 1,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black87),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Book Appointment',
//           style: TextStyle(
//             color: Colors.black87,
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: false,
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(height: 16),
//                   _buildSectionTitle('Selected Services'),
//                   _buildAddFabricCard(),
//                   const SizedBox(height: 12),
//                   _buildSelectedServicesList(),
//                   const SizedBox(height: 24),
//                   _buildSectionTitle('Preferred Pickup Time'),
//                   _buildPickupTimeCard(),
//                   const SizedBox(height: 24),
//                   _buildSectionTitle('Pickup Location'),
//                   _buildPickupLocationCard(),
//                   const SizedBox(height: 24),
//                   _buildSectionTitle('Payment Breakup'),
//                   _buildPaymentBreakup(),
//                   const SizedBox(height: 100),
//                 ],
//               ),
//             ),
//           ),
//           _buildPaymentFooter(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Text(
//         title,
//         style: TextStyle(
//           fontSize: 16,
//           fontWeight: FontWeight.w600,
//           color: Colors.grey.shade700,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAddFabricCard() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       decoration: BoxDecoration(
//         color: Colors.brown.shade700,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: _showAddFabricBottomSheet,
//           borderRadius: BorderRadius.circular(12),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Container(
//                   width: 60,
//                   height: 60,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(8),
//                     image: const DecorationImage(
//                       image: NetworkImage(
//                         'https://images.unsplash.com/photo-1591195853828-11db59a44f6b',
//                       ),
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         bookingData.bringOwnFabric ? 'Fabric Added' : 'Get Fabric',
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         bookingData.bringOwnFabric
//                             ? 'Bringing own fabric'
//                             : 'we\'ll bring fabric with us',
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.white.withOpacity(0.9),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   decoration: BoxDecoration(
//                     color: Colors.red.shade400,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     bookingData.bringOwnFabric ? 'Change' : '+ Add Fabric',
//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSelectedServicesList() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: ListView.separated(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         itemCount: bookingData.selectedServices.length,
//         separatorBuilder: (context, index) => Divider(
//           height: 1,
//           color: Colors.grey.shade200,
//         ),
//         itemBuilder: (context, index) {
//           final service = bookingData.selectedServices[index];
//           return _buildServiceItem(service);
//         },
//       ),
//     );
//   }
//
//   Widget _buildServiceItem(SelectedService service) {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 70,
//                 height: 70,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(8),
//                   image: DecorationImage(
//                     image: NetworkImage(service.image),
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       service.categoryName,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       '${service.serviceName} · ₹${service.price}',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 decoration: BoxDecoration(
//                   color: Colors.red.shade400,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.remove, size: 18, color: Colors.white),
//                       onPressed: () => _updateServiceQuantity(service.subCategoryId, -1),
//                       padding: const EdgeInsets.all(4),
//                       constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
//                     ),
//                     Container(
//                       constraints: const BoxConstraints(minWidth: 24),
//                       child: Text(
//                         '${service.quantity}',
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.add, size: 18, color: Colors.white),
//                       onPressed: () => _updateServiceQuantity(service.subCategoryId, 1),
//                       padding: const EdgeInsets.all(4),
//                       constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: () => _showTagDialog(service),
//                   style: OutlinedButton.styleFrom(
//                     side: BorderSide(color: Colors.grey.shade300),
//                     padding: const EdgeInsets.symmetric(vertical: 10),
//                   ),
//                   child: Text(
//                     service.tag ?? 'Tag',
//                     style: TextStyle(
//                       fontSize: 13,
//                       color: Colors.grey.shade700,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: () => _showReferenceDialog(service),
//                   style: OutlinedButton.styleFrom(
//                     side: BorderSide(color: Colors.grey.shade300),
//                     padding: const EdgeInsets.symmetric(vertical: 10),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         service.reference ?? 'Reference',
//                         style: TextStyle(
//                           fontSize: 13,
//                           color: Colors.grey.shade700,
//                         ),
//                       ),
//                       const SizedBox(width: 4),
//                       Icon(
//                         Icons.info_outline,
//                         size: 16,
//                         color: Colors.grey.shade600,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPickupTimeCard() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: _showPickupTimeBottomSheet,
//           borderRadius: BorderRadius.circular(12),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade100,
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     Icons.access_time,
//                     color: Colors.grey.shade700,
//                     size: 24,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Text(
//                     '${bookingData.pickupDate} ${bookingData.pickupTime}',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ),
//                 Icon(
//                   Icons.keyboard_arrow_down,
//                   color: Colors.grey.shade600,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPickupLocationCard() {
//     final location = bookingData.pickupLocation;
//
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: _showPickupLocationBottomSheet,
//           borderRadius: BorderRadius.circular(12),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade100,
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     Icons.location_on,
//                     color: Colors.grey.shade700,
//                     size: 24,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         location?.addressType ?? 'Select Location',
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       if (location != null) ...[
//                         const SizedBox(height: 4),
//                         Text(
//                           location.fullAddress,
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey.shade600,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//                 Icon(
//                   Icons.chevron_right,
//                   color: Colors.grey.shade600,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPaymentBreakup() {
//     final breakup = bookingData.paymentBreakup;
//
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildBreakupRow('Total Tailoring', '₹${breakup.totalTailoring}'),
//             const SizedBox(height: 12),
//             _buildBreakupRow('Pickup Fee', '₹${breakup.pickupFee}'),
//             const SizedBox(height: 12),
//             _buildBreakupRow('Tax', '₹${breakup.tax}'),
//             if (breakup.discount > 0) ...[
//               const SizedBox(height: 12),
//               _buildBreakupRow(
//                 'Discount',
//                 '-₹${breakup.discount}',
//                 isDiscount: true,
//               ),
//             ],
//             const SizedBox(height: 16),
//             Divider(height: 1, color: Colors.grey.shade300),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Total Amount',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 Text(
//                   '₹${breakup.totalAmount}',
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBreakupRow(String label, String value, {bool isDiscount = false}) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 15,
//             color: Colors.grey.shade700,
//           ),
//         ),
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 15,
//             fontWeight: FontWeight.w600,
//             color: isDiscount ? Colors.green.shade700 : Colors.black87,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildPaymentFooter() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         child: SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: bookingData.selectedServices.isEmpty
//                 ? null
//                 : () => _processPayment(),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red.shade400,
//               disabledBackgroundColor: Colors.grey.shade300,
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: Text(
//               'Pay  ₹${bookingData.paymentBreakup.totalAmount}',
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Bottom Sheets
//   Widget _buildAddFabricSheet() {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Fabric Options',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 24),
//           ListTile(
//             leading: Icon(Icons.shopping_bag, color: Colors.red.shade400),
//             title: const Text('Get fabric from tailor'),
//             subtitle: const Text('Tailor will bring fabric catalog'),
//             onTap: () {
//               setState(() {
//                 bookingData = bookingData.copyWith(bringOwnFabric: false);
//               });
//               Navigator.pop(context);
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.checkroom, color: Colors.blue.shade400),
//             title: const Text('I\'ll bring my own fabric'),
//             subtitle: const Text('Bring your fabric to appointment'),
//             onTap: () {
//               setState(() {
//                 bookingData = bookingData.copyWith(bringOwnFabric: true);
//               });
//               Navigator.pop(context);
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPickupTimeSheet() {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Select Pickup Time',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Current: ${bookingData.pickupDate} ${bookingData.pickupTime}',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey.shade600,
//             ),
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               // Navigate to time selection or show date/time pickers
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red.shade400,
//               minimumSize: const Size(double.infinity, 48),
//             ),
//             child: const Text('Change Time'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPickupLocationSheet() {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Pickup Location',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 24),
//           if (bookingData.pickupLocation != null) ...[
//             ListTile(
//               leading: const Icon(Icons.location_on, color: Colors.red),
//               title: Text(bookingData.pickupLocation!.addressType),
//               subtitle: Text(bookingData.pickupLocation!.fullAddress),
//               trailing: const Icon(Icons.check_circle, color: Colors.green),
//             ),
//             const SizedBox(height: 16),
//           ],
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               Navigator.pushNamed(context, '/add-address');
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red.shade400,
//               minimumSize: const Size(double.infinity, 48),
//             ),
//             child: const Text('Change Location'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showTagDialog(SelectedService service) {
//     final controller = TextEditingController(text: service.tag);
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Add Tag'),
//         content: TextField(
//           controller: controller,
//           decoration: const InputDecoration(
//             hintText: 'e.g., For work, Casual wear',
//             border: OutlineInputBorder(),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               _updateServiceTag(service.subCategoryId, controller.text);
//               Navigator.pop(context);
//             },
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showReferenceDialog(SelectedService service) {
//     final controller = TextEditingController(text: service.reference);
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Add Reference'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               'Add a reference note for the tailor',
//               style: TextStyle(fontSize: 14),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: controller,
//               decoration: const InputDecoration(
//                 hintText: 'e.g., Like the collar in photo',
//                 border: OutlineInputBorder(),
//               ),
//               maxLines: 3,
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               _updateServiceReference(service.subCategoryId, controller.text);
//               Navigator.pop(context);
//             },
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _processPayment() {
//     // Validate booking data
//     if (bookingData.pickupLocation == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('Please select a pickup location'),
//           backgroundColor: Colors.orange.shade700,
//         ),
//       );
//       return;
//     }
//
//     // Show payment processing dialog
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         title: const Text('Confirm Booking'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Total Amount: ₹${bookingData.paymentBreakup.totalAmount}',
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Services: ${bookingData.selectedServices.length} items',
//               style: TextStyle(color: Colors.grey.shade700),
//             ),
//             Text(
//               'Pickup: ${bookingData.pickupDate} ${bookingData.pickupTime}',
//               style: TextStyle(color: Colors.grey.shade700),
//             ),
//             Text(
//               'Location: ${bookingData.pickupLocation!.addressType}',
//               style: TextStyle(color: Colors.grey.shade700),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(
//               'Cancel',
//               style: TextStyle(color: Colors.grey.shade600),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               // Navigate to payment gateway or confirm booking
//               _confirmBooking();
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red.shade400,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: const Text('Proceed to Pay'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _confirmBooking() {
//     // Here you would integrate with payment gateway
//     // For now, show success message
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               Icons.check_circle,
//               color: Colors.green.shade600,
//               size: 64,
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               'Booking Confirmed!',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Your appointment has been booked successfully',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context); // Close dialog
//               Navigator.pop(context); // Go back to previous screen
//               Navigator.pop(context); // Go back to home
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red.shade400,
//               minimumSize: const Size(double.infinity, 48),
//             ),
//             child: const Text('Go to Home'),
//           ),
//         ],
//       ),
//     );
//   }
// }