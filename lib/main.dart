import 'package:customer_app/screens/add_family_profile_screen.dart';
import 'package:customer_app/providers/family_profile_provider.dart';
import 'package:customer_app/providers/profile_provider.dart';
import 'package:customer_app/screens/book_appointment_screen.dart';
import 'package:customer_app/screens/login_screen.dart';
import 'package:customer_app/screens/otp_verification_screen.dart';
import 'package:customer_app/screens/profile_details_screen.dart';
import 'package:customer_app/screens/add_address_screen.dart';
import 'package:customer_app/screens/home_screen.dart';
import 'package:customer_app/screens/my_orders_screen.dart';
import 'package:customer_app/screens/order_details_screen.dart';
import 'package:customer_app/screens/profiles_list_screen.dart';
import 'package:customer_app/screens/splash_screen.dart';
import 'package:customer_app/screens/tailor_detail_screen.dart'; // ADD THIS IMPORT
import 'package:customer_app/models/order_models.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'models/book_appointment_models.dart';
import 'providers/auth_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProfileProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Casa Darzi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.latoTextTheme(),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/otp': (context) => const OtpVerificationScreen(phoneNumber: ''),
        '/profile-details': (context) => const ProfileDetailsScreen(),
        '/add-address': (context) => const AddAddressScreen(),
        '/home': (context) => const HomeScreen(),
        '/my-orders': (context) => const MyOrdersScreen(),
        '/profiles-list': (context) => const ProfilesListScreen(),
        // Tailor detail and order details routes handled by onGenerateRoute
      },
      onGenerateRoute: (settings) {
        // Handle order details route with arguments
        if (settings.name == '/order-details') {
          final order = settings.arguments as OrderModel;
          return MaterialPageRoute(
            builder: (context) => OrderDetailsScreen(order: order),
            settings: settings,
          );
        }

        // Handle tailor detail route with arguments
        if (settings.name == '/tailor-detail') {
          final tailorId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => TailorDetailScreen(tailorId: tailorId),
            settings: settings,
          );
        }

        if (settings.name == '/book-appointment') {
          final bookingData = settings.arguments as BookingData;
          return MaterialPageRoute(
            builder: (context) => BookAppointmentScreen(bookingData: bookingData),
            settings: settings,
          );
        }

        if (settings.name == '/add-family-profile') {
          final profileId = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) => AddFamilyProfileScreen(profileId: profileId),
            settings: settings,
          );
        }

        // if (settings.name == '/family-profiles-list') {
        //   return MaterialPageRoute(
        //     builder: (context) => const FamilyProfilesListScreen(),
        //     settings: settings,
        //   );
        // }

        return null;
      },
    );
  }
}