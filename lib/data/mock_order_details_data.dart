// data/mock_order_details_data.dart

class MockOrderDetailsData {
  static Map<String, dynamic> getOrderDetails(String orderId) {
    // Mock data for different orders
    final orderDetailsMap = {
      "ORD001": {
        "orderId": "34564",
        "status": "Order Confirmed",
        "pickupTime": "10:30 PM",
        "pickupDate": "30 July",
        "canEditPickupTime": true,
        "items": [
          {
            "id": "item1",
            "quantity": 1,
            "itemType": "Shrits",
            "itemCategory": "Casual shirt",
            "assignedTo": "Arjun Das"
          },
          {
            "id": "item2",
            "quantity": 1,
            "itemType": "Shrits",
            "itemCategory": "Formal shirt",
            "assignedTo": "Arjun Das"
          }
        ],
        "tailor": {
          "id": "1",
          "name": "Vishaal Tailors",
          "imageUrl": "https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=100&h=100&fit=crop",
          "rating": 4.9,
          "reviewCount": 200
        },
        "pickupAddress": {
          "name": "SNN Raj Vista",
          "address": "312, MG road, Koramangala, Bangalore - 560001"
        },
        "payment": {
          "amount": 2198,
          "paymentMethod": "HDFC Card",
          "cardNumber": "xx7354"
        },
        "placedOn": "9:38 PM • 12 July '25"
      },
      "ORD002": {
        "orderId": "34565",
        "status": "Order Confirmed",
        "pickupTime": "02:00 PM",
        "pickupDate": "31 July",
        "canEditPickupTime": true,
        "items": [
          {
            "id": "item3",
            "quantity": 2,
            "itemType": "Pants",
            "itemCategory": "Formal trouser",
            "assignedTo": "Rahul Kumar"
          }
        ],
        "tailor": {
          "id": "3",
          "name": "Royal Tailoring",
          "imageUrl": "https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=100&h=100&fit=crop",
          "rating": 4.3,
          "reviewCount": 150
        },
        "pickupAddress": {
          "name": "SNN Raj Vista",
          "address": "312, MG road, Koramangala, Bangalore - 560001"
        },
        "payment": {
          "amount": 1599,
          "paymentMethod": "UPI",
          "cardNumber": "xxx@paytm"
        },
        "placedOn": "11:20 AM • 13 July '25"
      },
      "ORD003": {
        "orderId": "34566",
        "status": "Stitching in Progress",
        "pickupTime": "10:30 PM",
        "pickupDate": "30 July",
        "canEditPickupTime": false,
        "items": [
          {
            "id": "item4",
            "quantity": 1,
            "itemType": "Shrits",
            "itemCategory": "Formal shirt",
            "assignedTo": "Priya Sharma"
          },
          {
            "id": "item5",
            "quantity": 1,
            "itemType": "Shrits",
            "itemCategory": "Formal shirt",
            "assignedTo": "Priya Sharma"
          }
        ],
        "tailor": {
          "id": "2",
          "name": "Masterji Tailors",
          "imageUrl": "https://images.unsplash.com/photo-1606928778821-dfef15e8b32e?w=100&h=100&fit=crop",
          "rating": 4.1,
          "reviewCount": 200
        },
        "pickupAddress": {
          "name": "SNN Raj Vista",
          "address": "312, MG road, Koramangala, Bangalore - 560001"
        },
        "payment": {
          "amount": 1899,
          "paymentMethod": "Debit Card",
          "cardNumber": "xx4521"
        },
        "placedOn": "3:15 PM • 10 July '25"
      },
      "ORD004": {
        "orderId": "34567",
        "status": "Stitching in Progress",
        "pickupTime": "11:00 AM",
        "pickupDate": "28 July",
        "canEditPickupTime": false,
        "items": [
          {
            "id": "item6",
            "quantity": 1,
            "itemType": "Kurta",
            "itemCategory": "Wedding kurta",
            "assignedTo": "Vijay Singh"
          }
        ],
        "tailor": {
          "id": "4",
          "name": "Style Studio",
          "imageUrl": "https://images.unsplash.com/photo-1617127365659-c47fa864d8bc?w=100&h=100&fit=crop",
          "rating": 4.5,
          "reviewCount": 320
        },
        "pickupAddress": {
          "name": "SNN Raj Vista",
          "address": "312, MG road, Koramangala, Bangalore - 560001"
        },
        "payment": {
          "amount": 3499,
          "paymentMethod": "Cash",
          "cardNumber": "On Delivery"
        },
        "placedOn": "8:45 AM • 08 July '25"
      },
      "ORD005": {
        "orderId": "34568",
        "status": "Delivered",
        "pickupTime": "10:30 PM",
        "pickupDate": "30 July",
        "canEditPickupTime": false,
        "items": [
          {
            "id": "item7",
            "quantity": 1,
            "itemType": "Shrits",
            "itemCategory": "Formal shirt",
            "assignedTo": "Amit Patel"
          },
          {
            "id": "item8",
            "quantity": 1,
            "itemType": "Shrits",
            "itemCategory": "Formal shirt",
            "assignedTo": "Amit Patel"
          }
        ],
        "tailor": {
          "id": "2",
          "name": "Imperial Stitch",
          "imageUrl": "https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=100&h=100&fit=crop",
          "rating": 4.1,
          "reviewCount": 200
        },
        "pickupAddress": {
          "name": "SNN Raj Vista",
          "address": "312, MG road, Koramangala, Bangalore - 560001"
        },
        "payment": {
          "amount": 1799,
          "paymentMethod": "Google Pay",
          "cardNumber": "xxx@oksbi"
        },
        "placedOn": "6:20 PM • 05 July '25"
      }
    };

    return orderDetailsMap[orderId] ?? orderDetailsMap["ORD001"]!;
  }
}