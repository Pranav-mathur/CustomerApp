// screens/my_orders_screen.dart

import 'package:flutter/material.dart';
import '../models/order_models.dart';
import '../data/mock_orders_data.dart';
import 'order_details_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({Key? key}) : super(key: key);

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<OrderModel> upcomingOrders = [];
  List<OrderModel> currentOrders = [];
  List<OrderModel> pastOrders = [];

  @override
  void initState() {
    super.initState();
    _loadOrdersData();
  }

  void _loadOrdersData() {
    final data = MockOrdersData.getOrdersData();

    setState(() {
      upcomingOrders = (data['upcomingOrders'] as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();

      currentOrders = (data['currentOrders'] as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();

      pastOrders = (data['pastOrders'] as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upcoming Orders Section
            if (upcomingOrders.isNotEmpty) ...[
              _buildSectionTitle('Upcoming Orders'),
              ...upcomingOrders.map((order) => _buildOrderCard(order)),
            ],

            // Current Orders Section
            if (currentOrders.isNotEmpty) ...[
              _buildSectionTitle('Current Orders'),
              ...currentOrders.map((order) => _buildOrderCard(order)),
            ],

            // Past Orders Section
            if (pastOrders.isNotEmpty) ...[
              _buildSectionTitle('Past Orders'),
              ...pastOrders.map((order) => _buildOrderCard(order)),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigate to order details
          _showOrderDetails(order);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tailor Info Row
              Row(
                children: [
                  // Tailor Image
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(order.tailorImage),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Tailor Name and Pickup Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.tailorName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.orderType == 'upcoming'
                              ? 'Pickup: ${order.pickupTime}, ${order.pickupDate}'
                              : 'Picked: ${order.pickupTime}, ${order.pickupDate}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow Icon
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 24,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Order Items
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                    const SizedBox(width: 8),
                    Text(
                      '• ${item.itemCategory}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )),

              const SizedBox(height: 12),

              // Status and Delivery Row
              if (order.expectedDelivery != null)
              // Row with both status and expected delivery in columns
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.status,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: order.getStatusColor(),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Expected Delivery Column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Expected delivery:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.expectedDelivery!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
              // Single row for upcoming/past orders
                Row(
                  children: [
                    Text(
                      'Status: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        order.status,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: order.getStatusColor(),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

              // Rating Section (for past orders without rating)
              if (order.canBeRated) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Rate',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ...List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => _rateOrder(order, index + 1),
                        child: Icon(
                          Icons.star_border,
                          size: 28,
                          color: Colors.grey.shade400,
                        ),
                      );
                    }),
                  ],
                ),
              ],

              // Already Rated (for past orders with rating)
              if (order.rating != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Your Rating: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    ...List.generate(5, (index) {
                      return Icon(
                        index < order.rating!.floor()
                            ? Icons.star
                            : Icons.star_border,
                        size: 20,
                        color: Colors.amber,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      order.rating!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _rateOrder(OrderModel order, int rating) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Rate Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rate your experience with ${order.tailorName}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  size: 32,
                  color: Colors.amber,
                );
              }),
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
              setState(() {
                // Update rating in the order
                final index = pastOrders.indexWhere((o) => o.id == order.id);
                if (index != -1) {
                  pastOrders[index] = OrderModel(
                    id: order.id,
                    tailorId: order.tailorId,
                    tailorName: order.tailorName,
                    tailorImage: order.tailorImage,
                    pickupTime: order.pickupTime,
                    pickupDate: order.pickupDate,
                    items: order.items,
                    status: order.status,
                    expectedDelivery: order.expectedDelivery,
                    orderType: order.orderType,
                    rating: rating.toDouble(),
                  );
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for your rating!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(OrderModel order) {
    // Navigate to order details screen using named route with arguments
    Navigator.pushNamed(
      context,
      '/order-details',
      arguments: order, // Pass entire order object
    );
  }
}