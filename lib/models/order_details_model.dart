// models/order_details_model.dart

import 'package:flutter/material.dart';

class OrderItemDetailModel {
  final String id;
  final int quantity;
  final String itemType;
  final String itemCategory;
  final String assignedTo;

  OrderItemDetailModel({
    required this.id,
    required this.quantity,
    required this.itemType,
    required this.itemCategory,
    required this.assignedTo,
  });

  factory OrderItemDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderItemDetailModel(
      id: json['id'],
      quantity: json['quantity'],
      itemType: json['itemType'],
      itemCategory: json['itemCategory'],
      assignedTo: json['assignedTo'],
    );
  }
}

class TailorDetailModel {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final int reviewCount;

  TailorDetailModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
  });

  factory TailorDetailModel.fromJson(Map<String, dynamic> json) {
    return TailorDetailModel(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      rating: json['rating'].toDouble(),
      reviewCount: json['reviewCount'],
    );
  }
}

class PaymentDetailModel {
  final double amount;
  final String paymentMethod;
  final String cardNumber;

  PaymentDetailModel({
    required this.amount,
    required this.paymentMethod,
    required this.cardNumber,
  });

  factory PaymentDetailModel.fromJson(Map<String, dynamic> json) {
    return PaymentDetailModel(
      amount: json['amount'].toDouble(),
      paymentMethod: json['paymentMethod'],
      cardNumber: json['cardNumber'],
    );
  }
}

class PickupAddressModel {
  final String name;
  final String address;

  PickupAddressModel({
    required this.name,
    required this.address,
  });

  factory PickupAddressModel.fromJson(Map<String, dynamic> json) {
    return PickupAddressModel(
      name: json['name'],
      address: json['address'],
    );
  }
}

class OrderDetailsModel {
  final String orderId;
  final String status;
  final String pickupTime;
  final String pickupDate;
  final bool canEditPickupTime;
  final List<OrderItemDetailModel> items;
  final TailorDetailModel tailor;
  final PickupAddressModel pickupAddress;
  final PaymentDetailModel payment;
  final String placedOn;

  OrderDetailsModel({
    required this.orderId,
    required this.status,
    required this.pickupTime,
    required this.pickupDate,
    required this.canEditPickupTime,
    required this.items,
    required this.tailor,
    required this.pickupAddress,
    required this.payment,
    required this.placedOn,
  });

  factory OrderDetailsModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailsModel(
      orderId: json['orderId'],
      status: json['status'],
      pickupTime: json['pickupTime'],
      pickupDate: json['pickupDate'],
      canEditPickupTime: json['canEditPickupTime'],
      items: (json['items'] as List)
          .map((item) => OrderItemDetailModel.fromJson(item))
          .toList(),
      tailor: TailorDetailModel.fromJson(json['tailor']),
      pickupAddress: PickupAddressModel.fromJson(json['pickupAddress']),
      payment: PaymentDetailModel.fromJson(json['payment']),
      placedOn: json['placedOn'],
    );
  }

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
}