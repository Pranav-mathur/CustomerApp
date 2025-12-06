// screens/order_details_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/order_models.dart';
import '../models/order_details_model.dart';
import '../services/auth_service.dart';
import 'contact_us_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel? order; // Made optional
  final String? bookingId; // New parameter for direct navigation
  final bool showContinueButton; // New parameter to show Continue button

  const OrderDetailsScreen({
    Key? key,
    this.order,
    this.bookingId,
    this.showContinueButton = false,
  }) : super(key: key);

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  OrderDetailsModel? orderDetails;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Replace with your actual API URL and token
      const String apiBaseUrl = 'http://100.27.221.127:3000/api/v1/bookings';
      final AuthService _authService = AuthService();// Get this from your auth service
      final token = await _authService.getToken();

      // Use bookingId if provided, otherwise use order.id
      final String orderId = widget.bookingId ?? widget.order?.id ?? '';

      if (orderId.isEmpty) {
        throw Exception('No order ID provided');
      }

      final response = await http.get(
        Uri.parse('$apiBaseUrl/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final bookingData = jsonData['booking'];

        setState(() {
          orderDetails = _convertApiToOrderDetailsModel(bookingData);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load order details. Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading order details: $e';
        isLoading = false;
      });
    }
  }

  OrderDetailsModel _convertApiToOrderDetailsModel(Map<String, dynamic> apiData) {
    // Parse requestedDateTime
    DateTime requestedDateTime = DateTime.parse(apiData['requestedDateTime']);
    String pickupTime = _formatTime(requestedDateTime);
    String pickupDate = _formatDate(requestedDateTime);

    // Convert items
    List<OrderDetailsItem> items = (apiData['items'] as List).map((item) {
      return OrderDetailsItem(
        id: item['type'] ?? '',
        quantity: item['quantity'] ?? 1,
        itemType: item['category'] ?? '',
        itemCategory: item['type'] ?? '',
        assignedTo: apiData['tailor']['name'] ?? 'Tailor', // Using tailor name as assignedTo
      );
    }).toList();

    // Convert tailor info
    TailorInfo tailor = TailorInfo(
      id: apiData['tailor']['id'] ?? '',
      name: apiData['tailor']['name'] ?? '',
      imageUrl: apiData['tailor']['imageUrl'] ?? '',
      rating: (apiData['tailor']['rating'] ?? 0).toDouble(),
      reviewCount: apiData['tailor']['reviewCount'] ?? 0,
    );

    // Convert address
    PickupAddress pickupAddress = PickupAddress(
      name: apiData['address']['address_type'] ?? 'Address',
      address: _formatAddress(apiData['address']),
    );

    // Convert payment - using totalPrice from booking
    PaymentDetails payment = PaymentDetails(
      amount: (apiData['totalPrice'] ?? 0).toDouble(),
      paymentMethod: apiData['payment_status'] == 'paid' ? 'Paid' : 'Pending',
      cardNumber: apiData['payment_status'] == 'paid' ? 'Online' : 'Not Paid',
    );

    // Format createdAt
    DateTime createdAt = DateTime.parse(apiData['createdAt']);
    String placedOn = _formatPlacedOn(createdAt);

    // Determine if pickup time can be edited (only for Requested/Confirmed status)
    bool canEditPickupTime = apiData['status'] == 'Requested' ||
        apiData['status'] == 'Confirmed';

    return OrderDetailsModel(
      orderId: apiData['bookingId'] ?? '',
      status: apiData['status'] ?? 'Unknown',
      pickupTime: pickupTime,
      pickupDate: pickupDate,
      canEditPickupTime: canEditPickupTime,
      items: items,
      tailor: tailor,
      pickupAddress: pickupAddress,
      payment: payment,
      placedOn: placedOn,
    );
  }

  String _formatAddress(Map<String, dynamic> address) {
    List<String> parts = [];

    if (address['street'] != null && address['street'].isNotEmpty) {
      parts.add(address['street']);
    }
    if (address['city'] != null && address['city'].isNotEmpty) {
      parts.add(address['city']);
    }
    if (address['state'] != null && address['state'].isNotEmpty) {
      parts.add(address['state']);
    }
    if (address['pincode'] != null && address['pincode'].isNotEmpty) {
      parts.add(address['pincode'].toString());
    }

    return parts.join(', ');
  }

  String _formatTime(DateTime dateTime) {
    int hour = dateTime.hour;
    int minute = dateTime.minute;
    String period = hour >= 12 ? 'PM' : 'AM';

    if (hour > 12) {
      hour -= 12;
    } else if (hour == 0) {
      hour = 12;
    }

    String minuteStr = minute.toString().padLeft(2, '0');
    return '$hour:$minuteStr $period';
  }

  String _formatDate(DateTime dateTime) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dateTime.day} ${months[dateTime.month - 1]}';
  }

  String _formatPlacedOn(DateTime dateTime) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String year = dateTime.year.toString().substring(2);
    String time = _formatTime(dateTime);
    return '$time • ${dateTime.day} ${months[dateTime.month - 1]} \'$year';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: widget.showContinueButton
              ? const SizedBox.shrink() // Hide back button
              : IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          automaticallyImplyLeading: false,
          actions: widget.showContinueButton
              ? [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ]
              : null,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: widget.showContinueButton
              ? const SizedBox.shrink() // Hide back button
              : IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          automaticallyImplyLeading: false,
          actions: widget.showContinueButton
              ? [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ]
              : null,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOrderDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (orderDetails == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: widget.showContinueButton
              ? const SizedBox.shrink() // Hide back button
              : IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          automaticallyImplyLeading: false,
          actions: widget.showContinueButton
              ? [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ]
              : null,
        ),
        body: const Center(child: Text('No order details available')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Back Button and Continue Button Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Show back button only when NOT from payment flow
                  widget.showContinueButton
                      ? const SizedBox(width: 48) // Empty space to balance the row
                      : IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  if (widget.showContinueButton)
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Status Icon and Title
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: orderDetails!.getStatusColor(),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      orderDetails!.status,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Preferred Pickup Time
                    _buildCompactCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preferred Pickup Time',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 20,
                                    color: Colors.black87,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${orderDetails!.pickupTime}, ${orderDetails!.pickupDate}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Items + Tailor Combined
                    _buildCompactCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Items',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Items
                          ...orderDetails!.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          '${item.quantity} x ${item.itemType}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            '• ${item.itemCategory}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item.assignedTo,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )),

                          const SizedBox(height: 4),

                          // Tailor Info
                          InkWell(
                            onTap: () {},
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(orderDetails!.tailor.imageUrl),
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
                                        orderDetails!.tailor.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            orderDetails!.tailor.rating.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          ...List.generate(5, (index) {
                                            return Icon(
                                              index < orderDetails!.tailor.rating.floor()
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              size: 16,
                                              color: Colors.amber,
                                            );
                                          }),
                                          const SizedBox(width: 6),
                                          Text(
                                            '(${orderDetails!.tailor.reviewCount})',
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Pickup Address
                    _buildCompactCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pickup Address',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 24,
                                color: Colors.black87,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      orderDetails!.pickupAddress.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      orderDetails!.pickupAddress.address,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Payment Details
                    _buildCompactCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Details',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Amount',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '₹${orderDetails!.payment.amount.toInt()}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Paid via',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  '${orderDetails!.payment.paymentMethod} | ${orderDetails!.payment.cardNumber}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Order ID and Placed On
                    _buildCompactCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order ID',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  orderDetails!.orderId,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Placed on',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  orderDetails!.placedOn,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Need Support - Contact Us
                    _buildCompactCard(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ContactUsScreen(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.headset_mic_outlined,
                              size: 24,
                              color: Colors.black87,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Need Support?',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Contact Us',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 24,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}