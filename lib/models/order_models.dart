// models/order_models.dart

import 'package:flutter/material.dart';

class OrderItem {
  final String id;
  final int quantity;
  final String itemType;
  final String itemCategory;

  OrderItem({
    required this.id,
    required this.quantity,
    required this.itemType,
    required this.itemCategory,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      quantity: json['quantity'] ?? 1,
      itemType: json['itemType'] ?? '',
      itemCategory: json['itemCategory'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantity': quantity,
      'itemType': itemType,
      'itemCategory': itemCategory,
    };
  }
}

class OrderModel {
  final String id;
  final String tailorId;
  final String tailorName;
  final String tailorImage;
  final String pickupTime;
  final String pickupDate;
  final List<OrderItem> items;
  final String status;
  final String? expectedDelivery;
  final String orderType;
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
      id: json['id'] ?? '',
      tailorId: json['tailorId'] ?? '',
      tailorName: json['tailorName'] ?? '',
      tailorImage: json['tailorImage'] ?? '',
      pickupTime: json['pickupTime'] ?? '',
      pickupDate: json['pickupDate'] ?? '',
      items: (json['items'] as List?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ??
          [],
      status: json['status'] ?? '',
      expectedDelivery: json['expectedDelivery'],
      orderType: json['orderType'] ?? '',
      rating: json['rating']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
  }

  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'requested':
      case 'order confirmed':
      case 'confirmed':
        return Colors.blue;
      case 'stitching in progress':
      case 'in progress':
        return Colors.orange;
      case 'ready for delivery':
      case 'ready':
        return Colors.purple;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool get canBeRated {
    return orderType == 'past' &&
        rating == null &&
        (status.toLowerCase() == 'delivered' ||
            status.toLowerCase() == 'completed');
  }
}