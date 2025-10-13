// models/order_models.dart

import 'package:flutter/material.dart';

class OrderItemModel {
  final String id;
  final int quantity;
  final String itemType;
  final String itemCategory;

  OrderItemModel({
    required this.id,
    required this.quantity,
    required this.itemType,
    required this.itemCategory,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      quantity: json['quantity'],
      itemType: json['itemType'],
      itemCategory: json['itemCategory'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'quantity': quantity,
    'itemType': itemType,
    'itemCategory': itemCategory,
  };
}

class OrderModel {
  final String id;
  final String tailorId;
  final String tailorName;
  final String tailorImage;
  final String pickupTime;
  final String pickupDate;
  final List<OrderItemModel> items;
  final String status;
  final String? expectedDelivery;
  final String orderType; // 'upcoming', 'current', 'past'
  final double? rating;

  OrderModel({
    required this.id,
    required this.tailorId,
    required this.tailorName,
    required this.tailorImage,
    required this.pickupTime,
    required this.pickupDate,
    required this.items,
    required this.status,
    this.expectedDelivery,
    required this.orderType,
    this.rating,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      tailorId: json['tailorId'],
      tailorName: json['tailorName'],
      tailorImage: json['tailorImage'],
      pickupTime: json['pickupTime'],
      pickupDate: json['pickupDate'],
      items: (json['items'] as List)
          .map((item) => OrderItemModel.fromJson(item))
          .toList(),
      status: json['status'],
      expectedDelivery: json['expectedDelivery'],
      orderType: json['orderType'],
      rating: json['rating']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tailorId': tailorId,
    'tailorName': tailorName,
    'tailorImage': tailorImage,
    'pickupTime': pickupTime,
    'pickupDate': pickupDate,
    'items': items.map((item) => item.toJson()).toList(),
    'status': status,
    'expectedDelivery': expectedDelivery,
    'orderType': orderType,
    'rating': rating,
  };

  // Get status color
  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'order confirmed':
        return Colors.green;
      case 'stitching in progress':
        return Colors.orange;
      case 'delivered':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Check if order can be rated
  bool get canBeRated => orderType == 'past' && rating == null;
}