// screens/book_appointment_screen_v2.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
import '../models/address_model.dart';
import '../models/updated_booking_models.dart';
import '../models/booking_request_model.dart';
import '../services/address_service.dart';
import '../services/auth_service.dart';

class BookAppointmentScreenV2 extends StatefulWidget {
  final BookingDataV2 bookingData;

  const BookAppointmentScreenV2({
    Key? key,
    required this.bookingData,
  }) : super(key: key);

  @override
  State<BookAppointmentScreenV2> createState() => _BookAppointmentScreenV2State();
}

class _BookAppointmentScreenV2State extends State<BookAppointmentScreenV2> {
  late BookingDataV2 bookingData;
  final AddressService _addressService = AddressService();

  // Replace with your actual API base URL
  static const String baseUrl = 'YOUR_API_BASE_URL';

  List<AddressModel> addresses = [];
  bool isLoadingAddresses = true;
  String? addressError;
  bool isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    bookingData = widget.bookingData;
    _loadAddresses();
  }

  // Get JWT token from shared preferences
  // Future<String?> _getAuthToken() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     return prefs.getString('auth_token');
  //   } catch (e) {
  //     print('Error getting auth token: $e');
  //     return null;
  //   }
  // }

  // Create booking API call with address details
  Future<Map<String, dynamic>?> _createBookingAPI(Map<String, dynamic> bookingData) async {
    try {
      const String apiUrl = 'http://100.27.221.127:3000/api/v1/bookings';
      final AuthService _authService = AuthService();// Get this from your auth service
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = Uri.parse('$apiUrl');

      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      // Add address details to the booking data
      if (this.bookingData.selectedAddress != null) {
        final address = this.bookingData.selectedAddress!;
        bookingData['address'] = {
          'id': address.id,
          'label': address.label,
          'street': address.street,
          'city': address.city,
          'state': address.state,
          'pincode': address.pincode,
          'mobile': address.mobile,
          'isDefault': address.isDefault,
        };
      }

      // final url = Uri.parse('$baseUrl/api/bookings');

      print('Calling API: $url');
      print('Request Body: ${json.encode(bookingData)}');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(bookingData),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        // Success - Parse the response
        final responseData = json.decode(response.body);
        return responseData;
      } else if (response.statusCode == 401) {
        // Unauthorized - Token expired or invalid
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 400) {
        // Bad request - Validation error
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Invalid booking data';
        throw Exception(errorMessage);
      } else if (response.statusCode == 500) {
        // Server error
        throw Exception('Server error. Please try again later.');
      } else {
        // Other errors
        throw Exception('Failed to create booking. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createBooking: $e');
      rethrow;
    }
  }

  Future<void> _loadAddresses() async {
    setState(() {
      isLoadingAddresses = true;
      addressError = null;
    });

    try {
      final fetchedAddresses = await _addressService.getAllAddresses();

      setState(() {
        if (fetchedAddresses != null) {
          addresses = fetchedAddresses;

          // Auto-select default address if available and no address is selected
          if (bookingData.selectedAddress == null && addresses.isNotEmpty) {
            final defaultAddress = addresses.firstWhere(
                  (addr) => addr.isDefault,
              orElse: () => addresses.first,
            );
            bookingData = bookingData.copyWith(selectedAddress: defaultAddress);
          }
        }
        isLoadingAddresses = false;
      });
    } catch (e) {
      setState(() {
        isLoadingAddresses = false;
        addressError = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load addresses: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadAddresses,
            ),
          ),
        );
      }
    }
  }

  void _updateCategoryQuantity(String subCategoryId, int change) {
    setState(() {
      final categoryIndex = bookingData.categories
          .indexWhere((c) => c.subCategoryId == subCategoryId);

      if (categoryIndex != -1) {
        final currentQuantity = bookingData.categories[categoryIndex].quantity;
        final newQuantity = currentQuantity + change;

        if (newQuantity > 0) {
          bookingData.categories[categoryIndex] = bookingData.categories[categoryIndex]
              .copyWith(quantity: newQuantity);
        } else {
          bookingData.categories.removeAt(categoryIndex);
        }

        _recalculatePayment();
      }
    });
  }

  void _updateCategoryTag(String subCategoryId, String tag) {
    setState(() {
      final categoryIndex = bookingData.categories
          .indexWhere((c) => c.subCategoryId == subCategoryId);
      if (categoryIndex != -1) {
        bookingData.categories[categoryIndex].tag = tag;
      }
    });
  }

  void _updateCategoryReference(String subCategoryId, String reference) {
    setState(() {
      final categoryIndex = bookingData.categories
          .indexWhere((c) => c.subCategoryId == subCategoryId);
      if (categoryIndex != -1) {
        bookingData.categories[categoryIndex].reference = reference;
      }
    });
  }

  void _recalculatePayment() {
    final totalTailoring = bookingData.categories
        .fold<int>(0, (sum, category) => sum + category.totalPrice);

    setState(() {
      bookingData = bookingData.copyWith(
        paymentBreakup: PaymentBreakup.calculate(totalTailoring: totalTailoring),
      );
    });
  }

  void _updateDateTime(String date, String time) {
    final requestedDateTime = _parseDateTime(date, time);
    setState(() {
      bookingData = bookingData.copyWith(
        pickupDate: date,
        pickupTime: time,
        requestedDateTime: requestedDateTime,
      );
    });
  }

  DateTime _parseDateTime(String date, String time) {
    DateTime baseDate;
    final now = DateTime.now();

    if (date.toLowerCase() == 'today') {
      baseDate = now;
    } else if (date.toLowerCase() == 'tomorrow') {
      baseDate = now.add(const Duration(days: 1));
    } else {
      baseDate = now;
    }

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

    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }

  void _showAddFabricBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAddFabricSheet(),
    );
  }

  void _showPickupTimeBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildPickupTimeSheet(),
    );
  }

  void _showAddressSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAddressSelectionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (bookingData.categories.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Book Appointment',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildSectionTitle('Selected Services'),
                      _buildAddFabricCard(),
                      const SizedBox(height: 12),
                      _buildSelectedServicesList(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Preferred Pickup Time'),
                      _buildPickupTimeCard(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Pickup Location'),
                      _buildPickupLocationCard(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Payment Breakup'),
                      _buildPaymentBreakup(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              _buildPaymentFooter(),
            ],
          ),
          if (isProcessingPayment)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Processing your booking...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildAddFabricCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.brown.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showAddFabricBottomSheet,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1591195853828-11db59a44f6b',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bookingData.bringOwnFabric ? 'Fabric Added' : 'Get Fabric',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bookingData.bringOwnFabric
                            ? 'Bringing own fabric'
                            : 'we\'ll bring fabric with us',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    bookingData.bringOwnFabric ? 'Change' : '+ Add Fabric',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedServicesList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: bookingData.categories.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          final category = bookingData.categories[index];
          return _buildServiceItem(category);
        },
      ),
    );
  }

  Widget _buildServiceItem(BookingCategoryExtended category) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(category.image),
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
                      category.serviceName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${category.subCategoryName} · ₹${category.price}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18, color: Colors.white),
                      onPressed: () => _updateCategoryQuantity(category.subCategoryId, -1),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 24),
                      child: Text(
                        '${category.quantity}',
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
                      onPressed: () => _updateCategoryQuantity(category.subCategoryId, 1),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showTagDialog(category),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    category.tag ?? 'Tag',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showReferenceDialog(category),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category.reference ?? 'Reference',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickupTimeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.access_time,
                    color: Colors.grey.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '${bookingData.pickupDate} ${bookingData.pickupTime}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickupLocationCard() {
    if (isLoadingAddresses) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (addressError != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 32),
            const SizedBox(height: 8),
            Text(
              'Failed to load addresses',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadAddresses,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final selectedAddress = bookingData.selectedAddress;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showAddressSelectionBottomSheet,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: Colors.grey.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedAddress?.label ?? 'Select Location',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (selectedAddress != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${selectedAddress.street}, ${selectedAddress.city}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentBreakup() {
    final breakup = bookingData.paymentBreakup;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBreakupRow('Total Tailoring', '₹${breakup.totalTailoring}'),
            const SizedBox(height: 12),
            _buildBreakupRow('Pickup Fee', '₹${breakup.pickupFee}'),
            const SizedBox(height: 12),
            _buildBreakupRow('Tax', '₹${breakup.tax}'),
            if (breakup.discount > 0) ...[
              const SizedBox(height: 12),
              _buildBreakupRow(
                'Discount',
                '-₹${breakup.discount}',
                isDiscount: true,
              ),
            ],
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '₹${breakup.totalAmount}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakupRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDiscount ? Colors.green.shade700 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentFooter() {
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
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (bookingData.categories.isEmpty || isProcessingPayment)
                ? null
                : () => _processPayment(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isProcessingPayment
                  ? 'Processing...'
                  : 'Pay  ₹${bookingData.paymentBreakup.totalAmount}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddFabricSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fabric Options',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: Icon(Icons.shopping_bag, color: Colors.red.shade400),
            title: const Text('Get fabric from tailor'),
            subtitle: const Text('Tailor will bring fabric catalog'),
            onTap: () {
              setState(() {
                bookingData = bookingData.copyWith(bringOwnFabric: false);
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.checkroom, color: Colors.blue.shade400),
            title: const Text('I\'ll bring my own fabric'),
            subtitle: const Text('Bring your fabric to appointment'),
            onTap: () {
              setState(() {
                bookingData = bookingData.copyWith(bringOwnFabric: true);
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPickupTimeSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Pickup Time',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Current: ${bookingData.pickupDate} ${bookingData.pickupTime}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Show your TimeSlotPicker here and update the date/time
              // _showTimeSlotPicker();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Change Time'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSelectionSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Pickup Location',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (addresses.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Icon(Icons.location_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No addresses found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: addresses.length,
                itemBuilder: (context, index) {
                  final address = addresses[index];
                  final isSelected = bookingData.selectedAddress?.id == address.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.red.shade400 : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () {
                        setState(() {
                          bookingData = bookingData.copyWith(selectedAddress: address);
                        });
                        Navigator.pop(context);
                      },
                      leading: Icon(
                        Icons.location_on,
                        color: isSelected ? Colors.red.shade400 : Colors.grey.shade600,
                      ),
                      title: Row(
                        children: [
                          Text(
                            address.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (address.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Default',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('${address.street}, ${address.city}, ${address.state} - ${address.pincode}'),
                          const SizedBox(height: 2),
                          Text(
                            address.mobile,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: Colors.red.shade400)
                          : null,
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/add-address').then((_) {
                _loadAddresses();
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Address'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  void _showTagDialog(BookingCategoryExtended category) {
    final controller = TextEditingController(text: category.tag);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., For work, Casual wear',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateCategoryTag(category.subCategoryId, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showReferenceDialog(BookingCategoryExtended category) {
    final controller = TextEditingController(text: category.reference);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Reference'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add a reference note for the tailor',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g., Like the collar in photo',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateCategoryReference(category.subCategoryId, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _processPayment() {
    if (bookingData.selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a pickup location'),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }

    _showConfirmationDialog();
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Confirm Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Amount: ₹${bookingData.paymentBreakup.totalAmount}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Services: ${bookingData.categories.length} items',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            Text(
              'Pickup: ${bookingData.pickupDate} ${bookingData.pickupTime}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            Text(
              'Location: ${bookingData.selectedAddress!.label}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmBooking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Proceed to Pay'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBooking() async {
    setState(() {
      isProcessingPayment = true;
    });

    try {
      // Create the booking request
      final bookingRequest = bookingData.toBookingRequest();
      final requestJson = bookingRequest.toJson();

      print('Booking Request JSON (before adding address):');
      print(requestJson);

      // Call the API (address will be added inside _createBookingAPI)
      final response = await _createBookingAPI(requestJson);

      setState(() {
        isProcessingPayment = false;
      });

      if (response != null) {
        // Show success dialog
        _showSuccessDialog(
          bookingId: response['bookingId'] ?? '',
          totalPrice: response['totalPrice']?.toString() ?? '0',
          itemsCount: response['itemsCount']?.toString() ?? '0',
          paymentLink: response['paymentLink'],
          message: response['message'] ?? 'Booking created successfully',
        );
      } else {
        throw Exception('Failed to create booking');
      }
    } catch (e) {
      setState(() {
        isProcessingPayment = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _confirmBooking,
            ),
          ),
        );
      }
    }
  }

  void _showSuccessDialog({
    required String bookingId,
    required String totalPrice,
    required String itemsCount,
    required String message,
    String? paymentLink,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green.shade600,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Booking Created!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Booking ID:',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        bookingId,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount:',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '₹$totalPrice',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items:',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        itemsCount,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (paymentLink != null) ...[
            ElevatedButton(
              onPressed: () {
                // TODO: Open payment link or navigate to payment screen
                // You can use url_launcher package: launch(paymentLink);
                // Or navigate to your payment screen
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.pop(context);

                // Example: If you want to open the payment link
                // import 'package:url_launcher/url_launcher.dart';
                // launchUrl(Uri.parse(paymentLink));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text(
                'Pay Now',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton(
            onPressed: () {
              // Navigate back to home (close all booking screens)
              Navigator.pop(context); // Close success dialog
              Navigator.pop(context); // Close booking screen
              Navigator.pop(context); // Go back to previous screen/home
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Go to Home'),
          ),
        ],
      ),
    );
  }
}