// data/mock_orders_data.dart

class MockOrdersData {
  static Map<String, dynamic> getOrdersData() {
    return {
      "upcomingOrders": [
        {
          "id": "ORD001",
          "tailorId": "1",
          "tailorName": "Vishaal Tailors",
          "tailorImage": "https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=100&h=100&fit=crop",
          "pickupTime": "10:30 PM",
          "pickupDate": "30 July",
          "items": [
            {
              "id": "item1",
              "quantity": 1,
              "itemType": "Shrits",
              "itemCategory": "Casual shirt"
            },
            {
              "id": "item2",
              "quantity": 1,
              "itemType": "Shrits",
              "itemCategory": "Formal shirt"
            }
          ],
          "status": "Order Confirmed",
          "expectedDelivery": null,
          "orderType": "upcoming",
          "rating": null
        },
        {
          "id": "ORD002",
          "tailorId": "3",
          "tailorName": "Royal Tailoring",
          "tailorImage": "https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=100&h=100&fit=crop",
          "pickupTime": "02:00 PM",
          "pickupDate": "31 July",
          "items": [
            {
              "id": "item3",
              "quantity": 2,
              "itemType": "Pants",
              "itemCategory": "Formal trouser"
            }
          ],
          "status": "Order Confirmed",
          "expectedDelivery": null,
          "orderType": "upcoming",
          "rating": null
        }
      ],
      "currentOrders": [
        {
          "id": "ORD003",
          "tailorId": "2",
          "tailorName": "Masterji Tailors",
          "tailorImage": "https://images.unsplash.com/photo-1606928778821-dfef15e8b32e?w=100&h=100&fit=crop",
          "pickupTime": "10:30 PM",
          "pickupDate": "30 July",
          "items": [
            {
              "id": "item4",
              "quantity": 1,
              "itemType": "Shrits",
              "itemCategory": "Formal shirt"
            },
            {
              "id": "item5",
              "quantity": 1,
              "itemType": "Shrits",
              "itemCategory": "Formal shirt"
            }
          ],
          "status": "Stitching in Progress",
          "expectedDelivery": "12 Aug '25",
          "orderType": "current",
          "rating": null
        },
        {
          "id": "ORD004",
          "tailorId": "4",
          "tailorName": "Style Studio",
          "tailorImage": "https://images.unsplash.com/photo-1617127365659-c47fa864d8bc?w=100&h=100&fit=crop",
          "pickupTime": "11:00 AM",
          "pickupDate": "28 July",
          "items": [
            {
              "id": "item6",
              "quantity": 1,
              "itemType": "Kurta",
              "itemCategory": "Wedding kurta"
            }
          ],
          "status": "Stitching in Progress",
          "expectedDelivery": "15 Aug '25",
          "orderType": "current",
          "rating": null
        }
      ],
      "pastOrders": [
        {
          "id": "ORD005",
          "tailorId": "2",
          "tailorName": "Imperial Stitch",
          "tailorImage": "https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=100&h=100&fit=crop",
          "pickupTime": "10:30 PM",
          "pickupDate": "30 July",
          "items": [
            {
              "id": "item7",
              "quantity": 1,
              "itemType": "Shrits",
              "itemCategory": "Formal shirt"
            },
            {
              "id": "item8",
              "quantity": 1,
              "itemType": "Shrits",
              "itemCategory": "Formal shirt"
            }
          ],
          "status": "Delivered",
          "expectedDelivery": null,
          "orderType": "past",
          "rating": null
        },
        {
          "id": "ORD006",
          "tailorId": "1",
          "tailorName": "Vishaal Tailors",
          "tailorImage": "https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=100&h=100&fit=crop",
          "pickupTime": "10:30 PM",
          "pickupDate": "30 July",
          "items": [
            {
              "id": "item9",
              "quantity": 1,
              "itemType": "Shrits",
              "itemCategory": "Formal shirt"
            }
          ],
          "status": "Delivered",
          "expectedDelivery": null,
          "orderType": "past",
          "rating": 4.5
        },
        {
          "id": "ORD007",
          "tailorId": "6",
          "tailorName": "Elite Stitching",
          "tailorImage": "https://images.unsplash.com/photo-1622470953794-aa9c70b0fb9d?w=100&h=100&fit=crop",
          "pickupTime": "03:00 PM",
          "pickupDate": "15 July",
          "items": [
            {
              "id": "item10",
              "quantity": 2,
              "itemType": "Blazer",
              "itemCategory": "Wedding blazer"
            }
          ],
          "status": "Delivered",
          "expectedDelivery": null,
          "orderType": "past",
          "rating": null
        }
      ]
    };
  }
}