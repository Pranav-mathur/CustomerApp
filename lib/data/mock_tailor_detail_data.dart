// data/mock_tailor_detail_data.dart

class MockTailorDetailData {
  static Map<String, dynamic> getTailorDetail(String tailorId) {
    return {
      "tailorId": "T001",
      "name": "Vishaal Tailors",
      "profileImage": "https://images.unsplash.com/photo-1507679799987-c73779587ccf",
      "rating": 4.9,
      "reviewCount": 200,
      "googleRating": 4.7,
      "distance": 0.52,
      "deliveryTime": "4 day delivery",
      "startingPrice": 899,
      "tabs": ["Services", "Gallery", "Reviews"],
      "services": {
        "Men": {
          "categories": [
            {
              "categoryId": "C001",
              "categoryName": "Shirts",
              "isExpanded": true,
              "subCategories": [
                {
                  "subCategoryId": "SC001",
                  "name": "Casual shirts",
                  "image": "https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf",
                  "price": 1999,
                  "rating": 4.8,
                  "reviewCount": 20,
                  "quantity": 0
                },
                {
                  "subCategoryId": "SC002",
                  "name": "Formal shirts",
                  "image": "https://images.unsplash.com/photo-1603252109303-2751441dd157",
                  "price": 899,
                  "rating": 4.8,
                  "reviewCount": 20,
                  "quantity": 0
                },
                {
                  "subCategoryId": "SC003",
                  "name": "Party wear shirts",
                  "image": "https://images.unsplash.com/photo-1596755094514-f87e34085b2c",
                  "price": 1499,
                  "rating": 4.7,
                  "reviewCount": 15,
                  "quantity": 0
                }
              ]
            },
            {
              "categoryId": "C002",
              "categoryName": "Suits and Blazers",
              "isExpanded": false,
              "subCategories": [
                {
                  "subCategoryId": "SC004",
                  "name": "Business suit",
                  "image": "https://images.unsplash.com/photo-1507679799987-c73779587ccf",
                  "price": 4999,
                  "rating": 4.9,
                  "reviewCount": 35,
                  "quantity": 0
                },
                {
                  "subCategoryId": "SC005",
                  "name": "Blazer",
                  "image": "https://images.unsplash.com/photo-1593030761757-71fae45fa0e7",
                  "price": 3499,
                  "rating": 4.8,
                  "reviewCount": 28,
                  "quantity": 0
                },
                {
                  "subCategoryId": "SC006",
                  "name": "Tuxedo",
                  "image": "https://images.unsplash.com/photo-1621976498727-9e5d56476276",
                  "price": 5999,
                  "rating": 4.9,
                  "reviewCount": 42,
                  "quantity": 0
                }
              ]
            },
            {
              "categoryId": "C003",
              "categoryName": "Sherwani",
              "isExpanded": false,
              "subCategories": [
                {
                  "subCategoryId": "SC007",
                  "name": "Wedding Sherwani",
                  "image": "https://images.unsplash.com/photo-1617127365659-c47fa864d8bc",
                  "price": 6999,
                  "rating": 4.9,
                  "reviewCount": 52,
                  "quantity": 0
                },
                {
                  "subCategoryId": "SC008",
                  "name": "Party Sherwani",
                  "image": "https://images.unsplash.com/photo-1622290291468-a28f7a7dc6a8",
                  "price": 4999,
                  "rating": 4.8,
                  "reviewCount": 38,
                  "quantity": 0
                }
              ]
            },
            {
              "categoryId": "C004",
              "categoryName": "Kurta Pajama",
              "isExpanded": false,
              "subCategories": [
                {
                  "subCategoryId": "SC009",
                  "name": "Cotton Kurta",
                  "image": "https://images.unsplash.com/photo-1583391733981-9c0b0c5d44e4",
                  "price": 1299,
                  "rating": 4.7,
                  "reviewCount": 24,
                  "quantity": 0
                },
                {
                  "subCategoryId": "SC010",
                  "name": "Silk Kurta",
                  "image": "https://images.unsplash.com/photo-1612817288484-6f916006741a",
                  "price": 1999,
                  "rating": 4.8,
                  "reviewCount": 31,
                  "quantity": 0
                }
              ]
            }
          ]
        },
        "Women": {
          "categories": [
            {
              "categoryId": "C005",
              "categoryName": "Saree",
              "isExpanded": false,
              "subCategories": [
                {
                  "subCategoryId": "SC011",
                  "name": "Designer Saree",
                  "image": "https://images.unsplash.com/photo-1610030469983-98e550d6193c",
                  "price": 3999,
                  "rating": 4.9,
                  "reviewCount": 45,
                  "quantity": 0
                },
                {
                  "subCategoryId": "SC012",
                  "name": "Casual Saree",
                  "image": "https://images.unsplash.com/photo-1583391733956-6c78276477e9",
                  "price": 1999,
                  "rating": 4.7,
                  "reviewCount": 32,
                  "quantity": 0
                }
              ]
            },
            {
              "categoryId": "C006",
              "categoryName": "Lehenga",
              "isExpanded": false,
              "subCategories": [
                {
                  "subCategoryId": "SC013",
                  "name": "Bridal Lehenga",
                  "image": "https://images.unsplash.com/photo-1598439210625-cf8e05e3e0f0",
                  "price": 8999,
                  "rating": 5.0,
                  "reviewCount": 68,
                  "quantity": 0
                },
                {
                  "subCategoryId": "SC014",
                  "name": "Party Lehenga",
                  "image": "https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b",
                  "price": 4999,
                  "rating": 4.8,
                  "reviewCount": 42,
                  "quantity": 0
                }
              ]
            },
            {
              "categoryId": "C007",
              "categoryName": "Blouse",
              "isExpanded": false,
              "subCategories": [
                {
                  "subCategoryId": "SC015",
                  "name": "Designer Blouse",
                  "image": "https://images.unsplash.com/photo-1594633312681-425c7b97ccd1",
                  "price": 1499,
                  "rating": 4.8,
                  "reviewCount": 38,
                  "quantity": 0
                },
                {
                  "subCategoryId": "SC016",
                  "name": "Simple Blouse",
                  "image": "https://images.unsplash.com/photo-1596783342105-e8b8e8c3e9c0",
                  "price": 799,
                  "rating": 4.6,
                  "reviewCount": 25,
                  "quantity": 0
                }
              ]
            }
          ]
        },
        "Kids": {
          "categories": [
            {
              "categoryId": "C008",
              "categoryName": "Shirt",
              "isExpanded": false,
              "subCategories": [
                {
                  "subCategoryId": "SC017",
                  "name": "Casual Shirt",
                  "image": "https://images.unsplash.com/photo-1519238263530-99bdd11df2ea",
                  "price": 699,
                  "rating": 4.7,
                  "reviewCount": 18,
                  "quantity": 0
                },
                {
                  "subCategoryId": "SC018",
                  "name": "Formal Shirt",
                  "image": "https://images.unsplash.com/photo-1503342217505-b0a15ec3261c",
                  "price": 599,
                  "rating": 4.6,
                  "reviewCount": 15,
                  "quantity": 0
                }
              ]
            },
            {
              "categoryId": "C009",
              "categoryName": "Frock",
              "isExpanded": false,
              "subCategories": [
                {
                  "subCategoryId": "SC019",
                  "name": "Party Frock",
                  "image": "https://images.unsplash.com/photo-1518831959646-742c3a14ebf7",
                  "price": 1299,
                  "rating": 4.8,
                  "reviewCount": 22,
                  "quantity": 0
                },
                {
                  "subCategoryId": "SC020",
                  "name": "Casual Frock",
                  "image": "https://images.unsplash.com/photo-1519238263530-99bdd11df2ea",
                  "price": 899,
                  "rating": 4.7,
                  "reviewCount": 19,
                  "quantity": 0
                }
              ]
            }
          ]
        },
        "Designers": {
          "categories": [
            {
              "categoryId": "C010",
              "categoryName": "Bridal",
              "isExpanded": false,
              "subCategories": [
                {
                  "subCategoryId": "SC021",
                  "name": "Custom Bridal Wear",
                  "image": "https://images.unsplash.com/photo-1594552072238-85490c21c5e6",
                  "price": 15999,
                  "rating": 5.0,
                  "reviewCount": 85,
                  "quantity": 0
                }
              ]
            },
            {
              "categoryId": "C011",
              "categoryName": "Party Wear",
              "isExpanded": false,
              "subCategories": [
                {
                  "subCategoryId": "SC022",
                  "name": "Designer Gown",
                  "image": "https://images.unsplash.com/photo-1566174053879-31528523f8ae",
                  "price": 9999,
                  "rating": 4.9,
                  "reviewCount": 62,
                  "quantity": 0
                }
              ]
            }
          ]
        }
      },
      "gallery": [
        {
          "imageUrl": "https://images.unsplash.com/photo-1507679799987-c73779587ccf",
          "caption": "Tailoring Work Sample 1"
        },
        {
          "imageUrl": "https://images.unsplash.com/photo-1617127365659-c47fa864d8bc",
          "caption": "Tailoring Work Sample 2"
        },
        {
          "imageUrl": "https://images.unsplash.com/photo-1610030469983-98e550d6193c",
          "caption": "Tailoring Work Sample 3"
        },
        {
          "imageUrl": "https://images.unsplash.com/photo-1598439210625-cf8e05e3e0f0",
          "caption": "Tailoring Work Sample 4"
        }
      ],
      "reviews": [
        {
          "reviewId": "R001",
          "userName": "Rahul Sharma",
          "userImage": "https://i.pravatar.cc/150?img=12",
          "rating": 5.0,
          "reviewText": "Excellent work! Very professional and timely delivery.",
          "date": "2024-09-15",
          "images": []
        },
        {
          "reviewId": "R002",
          "userName": "Priya Patel",
          "userImage": "https://i.pravatar.cc/150?img=47",
          "rating": 4.8,
          "reviewText": "Great quality stitching. Highly recommended!",
          "date": "2024-09-10",
          "images": [
            "https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf"
          ]
        }
      ],
      "availableSlots": {
        "today": ["12:00 PM", "2:00 PM", "4:00 PM", "6:00 PM"],
        "tomorrow": ["10:00 AM", "12:00 PM", "2:00 PM", "4:00 PM", "6:00 PM"],
        "dayAfterTomorrow": ["10:00 AM", "12:00 PM", "2:00 PM", "4:00 PM"]
      }
    };
  }
}