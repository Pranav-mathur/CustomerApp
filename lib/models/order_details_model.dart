// models/order_details_model.dart

import 'package:flutter/material.dart';

class OrderDetailsItem {
  final String id;
  final int quantity;
  final String itemType;
  final String itemCategory;
  final String assignedTo;

  OrderDetailsItem({
    required this.id,
    required this.quantity,
    required this.itemType,
    required this.itemCategory,
    required this.assignedTo,
  });

  factory OrderDetailsItem.fromJson(Map<String, dynamic> json) {
    return OrderDetailsItem(
      id: json['id'] ?? '',
      quantity: json['quantity'] ?? 1,
      itemType: json['itemType'] ?? '',
      itemCategory: json['itemCategory'] ?? '',
      assignedTo: json['assignedTo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantity': quantity,
      'itemType': itemType,
      'itemCategory': itemCategory,
      'assignedTo': assignedTo,
    };
  }
}

class TailorInfo {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final int reviewCount;

  TailorInfo({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
  });

  factory TailorInfo.fromJson(Map<String, dynamic> json) {
    return TailorInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }
}

class PickupAddress {
  final String name;
  final String address;

  PickupAddress({
    required this.name,
    required this.address,
  });

  factory PickupAddress.fromJson(Map<String, dynamic> json) {
    return PickupAddress(
      name: json['name'] ?? '',
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
    };
  }
}

class PaymentDetails {
  final double amount;
  final String paymentMethod;
  final String cardNumber;

  PaymentDetails({
    required this.amount,
    required this.paymentMethod,
    required this.cardNumber,
  });

  factory PaymentDetails.fromJson(Map<String, dynamic> json) {
    return PaymentDetails(
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      cardNumber: json['cardNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'paymentMethod': paymentMethod,
      'cardNumber': cardNumber,
    };
  }
}

class OrderDetailsModel {
  final String orderId;
  final String status;
  final String pickupTime;
  final String pickupDate;
  final bool canEditPickupTime;
  final List<OrderDetailsItem> items;
  final TailorInfo tailor;
  final PickupAddress pickupAddress;
  final PaymentDetails payment;
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
      orderId: json['orderId'] ?? '',
      status: json['status'] ?? '',
      pickupTime: json['pickupTime'] ?? '',
      pickupDate: json['pickupDate'] ?? '',
      canEditPickupTime: json['canEditPickupTime'] ?? false,
      items: (json['items'] as List?)
          ?.map((item) => OrderDetailsItem.fromJson(item))
          .toList() ??
          [],
      tailor: TailorInfo.fromJson(json['tailor'] ?? {}),
      pickupAddress: PickupAddress.fromJson(json['pickupAddress'] ?? {}),
      payment: PaymentDetails.fromJson(json['payment'] ?? {}),
      placedOn: json['placedOn'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'status': status,
      'pickupTime': pickupTime,
      'pickupDate': pickupDate,
      'canEditPickupTime': canEditPickupTime,
      'items': items.map((item) => item.toJson()).toList(),
      'tailor': tailor.toJson(),
      'pickupAddress': pickupAddress.toJson(),
      'payment': payment.toJson(),
      'placedOn': placedOn,
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
      case 'stitching':
        return Colors.orange;
      case 'ready for delivery':
      case 'ready to deliver':
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
}