// data/mock_home_data.dart (UPDATED)

class MockHomeData {
  // static Map<String, dynamic> getHomeData() {
  //   return {
  //     "success": true,
  //     "data": {
  //       "banners": [
  //         "https://images.unsplash.com/photo-1617127365659-c47fa864d8bc?w=800&h=300&fit=crop",
  //         "https://images.unsplash.com/photo-1519741497674-611481863552?w=800&h=300&fit=crop",
  //         "https://images.unsplash.com/photo-1583847268964-b28dc8f51f92?w=800&h=300&fit=crop"
  //       ],
  //       "categories": {
  //         "men": [
  //           {
  //             "_id": "m1",
  //             "name": "Blazer",
  //             "gender": "men",
  //             "sub_categories": [
  //               {
  //                 "name": "Formal Blazer",
  //                 "gender": "men",
  //                 "created_at": "2023-01-01T00:00:00.000Z"
  //               },
  //               {
  //                 "name": "Casual Blazer",
  //                 "gender": "men",
  //                 "created_at": "2023-01-01T00:00:00.000Z"
  //               }
  //             ],
  //             "created_at": "2023-01-01T00:00:00.000Z"
  //           },
  //           {
  //             "_id": "m2",
  //             "name": "Sherwani",
  //             "gender": "men",
  //             "sub_categories": [
  //               {
  //                 "name": "Wedding Sherwani",
  //                 "gender": "men",
  //                 "created_at": "2023-01-01T00:00:00.000Z"
  //               }
  //             ],
  //             "created_at": "2023-01-01T00:00:00.000Z"
  //           },
  //           {
  //             "_id": "m3",
  //             "name": "Kurta",
  //             "gender": "men",
  //             "sub_categories": [],
  //             "created_at": "2023-01-01T00:00:00.000Z"
  //           },
  //           {
  //             "_id": "m4",
  //             "name": "Shirts",
  //             "gender": "men",
  //             "sub_categories": [
  //               {
  //                 "name": "Formal Shirts",
  //                 "gender": "men",
  //                 "created_at": "2023-01-01T00:00:00.000Z"
  //               },
  //               {
  //                 "name": "Casual Shirts",
  //                 "gender": "men",
  //                 "created_at": "2023-01-01T00:00:00.000Z"
  //               }
  //             ],
  //             "created_at": "2023-01-01T00:00:00.000Z"
  //           },
  //           {
  //             "_id": "m5",
  //             "name": "Jackets",
  //             "gender": "men",
  //             "sub_categories": [],
  //             "created_at": "2023-01-01T00:00:00.000Z"
  //           }
  //         ],
  //         "women": [
  //           {
  //             "_id": "w1",
  //             "name": "Saree",
  //             "gender": "women",
  //             "sub_categories": [
  //               {
  //                 "name": "Designer Saree",
  //                 "gender": "women",
  //                 "created_at": "2023-01-01T00:00:00.000Z"
  //               }
  //             ],
  //             "created_at": "2023-01-01T00:00:00.000Z"
  //           },
  //           {
  //             "_id": "w2",
  //             "name": "Lehenga",
  //             "gender": "women",
  //             "sub_categories": [
  //               {
  //                 "name": "Bridal Lehenga",
  //                 "gender": "women",
  //                 "created_at": "2023-01-01T00:00:00.000Z"
  //               }
  //             ],
  //             "created_at": "2023-01-01T00:00:00.000Z"
  //           },
  //           {
  //             "_id": "w3",
  //             "name": "Blouse",
  //             "gender": "women",
  //             "sub_categories": [],
  //             "created_at": "2023-01-01T00:00:00.000Z"
  //           },
  //           {
  //             "_id": "w4",
  //             "name": "Suit",
  //             "gender": "women",
  //             "sub_categories": [],
  //             "created_at": "2023-01-01T00:00:00.000Z"
  //           },
  //           {
  //             "_id": "w5",
  //             "name": "Gown",
  //             "gender": "women",
  //             "sub_categories": [],
  //             "created_at": "2023-01-01T00:00:00.000Z"
  //           }
  //         ],
  //         "kids": [
  //           {
  //             "_id": "k1",
  //             "name": "Shirt",
  //             "gender": "kids",
  //             "sub_categories": [],
  //             "created_at": "2023-01-01T00:00:00.000Z"
  //           },
  //           {
  //             "_id": "k2",
  //             "name": "Frock",
  //             "gender": "kids",
  //             "sub_categories": [],
  //             "created_at": "2023-01-01T00:00:00.000Z"
  //           },
  //           {
  //             "_id": "k3",
  //             "name": "Kurta",
  //             "gender": "kids",
  //             "sub_categories": [],
  //             "created_at": "2023-01-01T00:00:00.000Z"
  //           },
  //           {
  //             "_id": "k4",
  //             "name": "Dress",
  //             "gender": "kids",
  //             "sub_categories": [],
  //             "created_at": "2023-01-01T00:00:00.000Z"
  //           }
  //         ],
  //         "designers": [
  //           {
  //             "_id": "d1",
  //             "name": "Bridal",
  //             "gender": "designers",
  //             "sub_categories": [],
  //             "created_at": "2023-01-01T00:00:00.000Z"
  //           },
  //           {
  //             "_id": "d2",
  //             "name": "Party Wear",
  //             "gender": "designers",
  //             "sub_categories": [],
  //             "created_at": "2023-01-01T00:00:00.000Z"
  //           },
  //           {
  //             "_id": "d3",
  //             "name": "Formal",
  //             "gender": "designers",
  //             "sub_categories": [],
  //             "created_at": "2023-01-01T00:00:00.000Z"
  //           },
  //           {
  //             "_id": "d4",
  //             "name": "Couture",
  //             "gender": "designers",
  //             "sub_categories": [],
  //             "created_at": "2023-01-01T00:00:00.000Z"
  //           }
  //         ]
  //       },
  //       "featuredTailors": [
  //         {
  //           "_id": "T001",
  //           "name": "Vishaal Tailors",
  //           "profile_pic": "https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=400&h=300&fit=crop",
  //           "portfolio_images": [
  //             "https://images.unsplash.com/photo-1507679799987-c73779587ccf",
  //             "https://images.unsplash.com/photo-1606928778821-dfef15e8b32e"
  //           ],
  //           "categories": [
  //             {
  //               "category_id": "m2",
  //               "sub_category_name": "Wedding Sherwani",
  //               "price": 899,
  //               "delivery_time": "4 days",
  //               "display_images": ["https://images.unsplash.com/photo-1617127365659-c47fa864d8bc"]
  //             },
  //             {
  //               "category_id": "w2",
  //               "sub_category_name": "Bridal Lehenga",
  //               "price": 1499,
  //               "delivery_time": "5 days",
  //               "display_images": ["https://images.unsplash.com/photo-1598439210625-cf8e05e3e0f0"]
  //             }
  //           ],
  //           "address": {
  //             "street": "MG Road",
  //             "city": "Bangalore",
  //             "state": "Karnataka",
  //             "pincode": "560001",
  //             "mobile": "9876543210"
  //           },
  //           "location": {
  //             "type": "Point",
  //             "coordinates": [77.5946, 12.9716]
  //           },
  //           "is_sponsored": true,
  //           "avg_rating": 4.9,
  //           "review_count": 200,
  //           "is_profile_complete": true,
  //           "deliveryDate": 4,
  //           "startingPrice": 899,
  //           "bank_account": {
  //             "bank_name": "HDFC Bank",
  //             "bank_account_number": "1234567890",
  //             "ifsc_code": "HDFC0000123",
  //             "account_holder_name": "Vishaal Tailors",
  //             "is_verified": true
  //           },
  //           "kyc_done": true,
  //           "created_at": "2023-01-01T00:00:00.000Z"
  //         },
  //         {
  //           "_id": "T002",
  //           "name": "Imperial Stitch",
  //           "profile_pic": "https://images.unsplash.com/photo-1606928778821-dfef15e8b32e?w=400&h=300&fit=crop",
  //           "portfolio_images": [],
  //           "categories": [
  //             {
  //               "category_id": "m2",
  //               "sub_category_name": "Wedding Sherwani",
  //               "price": 899,
  //               "delivery_time": "4 days",
  //               "display_images": []
  //             }
  //           ],
  //           "address": {
  //             "street": "Indiranagar",
  //             "city": "Bangalore",
  //             "state": "Karnataka",
  //             "pincode": "560038",
  //             "mobile": "9876543211"
  //           },
  //           "location": {
  //             "type": "Point",
  //             "coordinates": [77.6408, 12.9716]
  //           },
  //           "is_sponsored": true,
  //           "avg_rating": 4.9,
  //           "review_count": 200,
  //           "is_profile_complete": true,
  //           "deliveryDate": 4,
  //           "startingPrice": 899,
  //           "bank_account": null,
  //           "kyc_done": true,
  //           "created_at": "2023-01-01T00:00:00.000Z"
  //         },
  //         {
  //           "_id": "T003",
  //           "name": "Royal Tailoring",
  //           "profile_pic": "https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400&h=300&fit=crop",
  //           "portfolio_images": [],
  //           "categories": [
  //             {
  //               "category_id": "m1",
  //               "sub_category_name": "Formal Blazer",
  //               "price": 999,
  //               "delivery_time": "3 days",
  //               "display_images": []
  //             }
  //           ],
  //           "address": {
  //             "street": "Koramangala",
  //             "city": "Bangalore",
  //             "state": "Karnataka",
  //             "pincode": "560095",
  //             "mobile": "9876543212"
  //           },
  //           "location": {
  //             "type": "Point",
  //             "coordinates": [77.6269, 12.9352]
  //           },
  //           "is_sponsored": true,
  //           "avg_rating": 4.3,
  //           "review_count": 150,
  //           "is_profile_complete": true,
  //           "deliveryDate": 3,
  //           "startingPrice": 999,
  //           "bank_account": null,
  //           "kyc_done": false,
  //           "created_at": "2023-01-01T00:00:00.000Z"
  //         },
  //         {
  //           "_id": "T004",
  //           "name": "Designer Studio",
  //           "profile_pic": "https://images.unsplash.com/photo-1583391733981-5bcd6fb7c4e1?w=400&h=300&fit=crop",
  //           "portfolio_images": [],
  //           "categories": [
  //             {
  //               "category_id": "w2",
  //               "sub_category_name": "Bridal Lehenga",
  //               "price": 1499,
  //               "delivery_time": "5 days",
  //               "display_images": []
  //             }
  //           ],
  //           "address": {
  //             "street": "Whitefield",
  //             "city": "Bangalore",
  //             "state": "Karnataka",
  //             "pincode": "560066",
  //             "mobile": "9876543213"
  //           },
  //           "location": {
  //             "type": "Point",
  //             "coordinates": [77.7499, 12.9698]
  //           },
  //           "is_sponsored": true,
  //           "avg_rating": 4.6,
  //           "review_count": 320,
  //           "is_profile_complete": true,
  //           "deliveryDate": 5,
  //           "startingPrice": 1499,
  //           "bank_account": null,
  //           "kyc_done": true,
  //           "created_at": "2023-01-01T00:00:00.000Z"
  //         }
  //       ],
  //       "allTailors": [
  //         {
  //           "_id": "T001",
  //           "name": "Vishaal Tailors",
  //           "profile_pic": "https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=400&h=300&fit=crop",
  //           "portfolio_images": [
  //             "https://images.unsplash.com/photo-1507679799987-c73779587ccf",
  //             "https://images.unsplash.com/photo-1606928778821-dfef15e8b32e"
  //           ],
  //           "categories": [
  //             {
  //               "category_id": "m2",
  //               "sub_category_name": "Wedding Sherwani",
  //               "price": 899,
  //               "delivery_time": "4 days",
  //               "display_images": []
  //             }
  //           ],
  //           "address": {
  //             "street": "MG Road",
  //             "city": "Bangalore",
  //             "state": "Karnataka",
  //             "pincode": "560001",
  //             "mobile": "9876543210"
  //           },
  //           "location": {
  //             "type": "Point",
  //             "coordinates": [77.5946, 12.9716]
  //           },
  //           "is_sponsored": true,
  //           "avg_rating": 4.9,
  //           "review_count": 200,
  //           "is_profile_complete": true,
  //           "deliveryDate": 4,
  //           "startingPrice": 899,
  //           "distance": 0.52,
  //           "bank_account": null,
  //           "kyc_done": true,
  //           "created_at": "2023-01-01T00:00:00.000Z"
  //         },
  //         {
  //           "_id": "T002",
  //           "name": "Imperial Stitch",
  //           "profile_pic": "https://images.unsplash.com/photo-1606928778821-dfef15e8b32e?w=400&h=300&fit=crop",
  //           "portfolio_images": [],
  //           "categories": [
  //             {
  //               "category_id": "m2",
  //               "sub_category_name": "Wedding Sherwani",
  //               "price": 899,
  //               "delivery_time": "4 days",
  //               "display_images": []
  //             }
  //           ],
  //           "address": {
  //             "street": "Indiranagar",
  //             "city": "Bangalore",
  //             "state": "Karnataka",
  //             "pincode": "560038",
  //             "mobile": "9876543211"
  //           },
  //           "location": {
  //             "type": "Point",
  //             "coordinates": [77.6408, 12.9716]
  //           },
  //           "is_sponsored": false,
  //           "avg_rating": 4.9,
  //           "review_count": 200,
  //           "is_profile_complete": true,
  //           "deliveryDate": 4,
  //           "startingPrice": 899,
  //           "distance": 0.52,
  //           "bank_account": null,
  //           "kyc_done": true,
  //           "created_at": "2023-01-01T00:00:00.000Z"
  //         },
  //         {
  //           "_id": "T003",
  //           "name": "Royal Tailoring",
  //           "profile_pic": "https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400&h=300&fit=crop",
  //           "portfolio_images": [],
  //           "categories": [
  //             {
  //               "category_id": "m1",
  //               "sub_category_name": "Formal Blazer",
  //               "price": 999,
  //               "delivery_time": "3 days",
  //               "display_images": []
  //             }
  //           ],
  //           "address": {
  //             "street": "Koramangala",
  //             "city": "Bangalore",
  //             "state": "Karnataka",
  //             "pincode": "560095",
  //             "mobile": "9876543212"
  //           },
  //           "location": {
  //             "type": "Point",
  //             "coordinates": [77.6269, 12.9352]
  //           },
  //           "is_sponsored": false,
  //           "avg_rating": 4.3,
  //           "review_count": 150,
  //           "is_profile_complete": true,
  //           "deliveryDate": 3,
  //           "startingPrice": 999,
  //           "distance": 0.75,
  //           "bank_account": null,
  //           "kyc_done": false,
  //           "created_at": "2023-01-01T00:00:00.000Z"
  //         },
  //         {
  //           "_id": "T004",
  //           "name": "Style Studio",
  //           "profile_pic": "https://images.unsplash.com/photo-1617127365659-c47fa864d8bc?w=400&h=300&fit=crop",
  //           "portfolio_images": [],
  //           "categories": [
  //             {
  //               "category_id": "d1",
  //               "sub_category_name": "Bridal Gown",
  //               "price": 1299,
  //               "delivery_time": "5 days",
  //               "display_images": []
  //             }
  //           ],
  //           "address": {
  //             "street": "Jayanagar",
  //             "city": "Bangalore",
  //             "state": "Karnataka",
  //             "pincode": "560011",
  //             "mobile": "9876543213"
  //           },
  //           "location": {
  //             "type": "Point",
  //             "coordinates": [77.5833, 12.9250]
  //           },
  //           "is_sponsored": false,
  //           "avg_rating": 4.5,
  //           "review_count": 320,
  //           "is_profile_complete": true,
  //           "deliveryDate": 5,
  //           "startingPrice": 1299,
  //           "distance": 1.2,
  //           "bank_account": null,
  //           "kyc_done": true,
  //           "created_at": "2023-01-01T00:00:00.000Z"
  //         },
  //         {
  //           "_id": "T005",
  //           "name": "Fashion Point",
  //           "profile_pic": "https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=400&h=300&fit=crop",
  //           "portfolio_images": [],
  //           "categories": [
  //             {
  //               "category_id": "m4",
  //               "sub_category_name": "Casual Shirts",
  //               "price": 599,
  //               "delivery_time": "6 days",
  //               "display_images": []
  //             }
  //           ],
  //           "address": {
  //             "street": "BTM Layout",
  //             "city": "Bangalore",
  //             "state": "Karnataka",
  //             "pincode": "560076",
  //             "mobile": "9876543214"
  //           },
  //           "location": {
  //             "type": "Point",
  //             "coordinates": [77.6101, 12.9165]
  //           },
  //           "is_sponsored": false,
  //           "avg_rating": 3.9,
  //           "review_count": 89,
  //           "is_profile_complete": true,
  //           "deliveryDate": 6,
  //           "startingPrice": 599,
  //           "distance": 2.1,
  //           "bank_account": null,
  //           "kyc_done": false,
  //           "created_at": "2023-01-01T00:00:00.000Z"
  //         },
  //         {
  //           "_id": "T006",
  //           "name": "Elite Stitching",
  //           "profile_pic": "https://images.unsplash.com/photo-1622470953794-aa9c70b0fb9d?w=400&h=300&fit=crop",
  //           "portfolio_images": [],
  //           "categories": [
  //             {
  //               "category_id": "m2",
  //               "sub_category_name": "Wedding Sherwani",
  //               "price": 1099,
  //               "delivery_time": "3 days",
  //               "display_images": []
  //             }
  //           ],
  //           "address": {
  //             "street": "HSR Layout",
  //             "city": "Bangalore",
  //             "state": "Karnataka",
  //             "pincode": "560102",
  //             "mobile": "9876543215"
  //           },
  //           "location": {
  //             "type": "Point",
  //             "coordinates": [77.6387, 12.9082]
  //           },
  //           "is_sponsored": false,
  //           "avg_rating": 4.7,
  //           "review_count": 450,
  //           "is_profile_complete": true,
  //           "deliveryDate": 3,
  //           "startingPrice": 1099,
  //           "distance": 0.8,
  //           "bank_account": null,
  //           "kyc_done": true,
  //           "created_at": "2023-01-01T00:00:00.000Z"
  //         }
  //       ]
  //     }
  //   };
  // }
}