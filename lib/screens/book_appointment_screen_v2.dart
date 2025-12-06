// screens/book_appointment_screen_v2.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/address_model.dart';
import '../models/updated_booking_models.dart';
import '../models/booking_request_model.dart';
import '../services/address_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../screens/time_slot_picker.dart';
import 'order_details_screen.dart';

class BookAppointmentScreenV2 extends StatefulWidget {
  final BookingDataV2 bookingData;

  const BookAppointmentScreenV2({
    Key? key,
    required this.bookingData,
  }) : super(key: key);

  @override
  State<BookAppointmentScreenV2> createState() => _BookAppointmentScreenV2State();
}

class _BookAppointmentScreenV2State extends State<BookAppointmentScreenV2> with WidgetsBindingObserver {
  late BookingDataV2 bookingData;
  final AddressService _addressService = AddressService();
  final ProfileService _profileService = ProfileService();
  final ImagePicker _picker = ImagePicker();

  static const String baseUrl = 'YOUR_API_BASE_URL';

  List<AddressModel> addresses = [];
  bool isLoadingAddresses = true;
  String? addressError;
  bool isProcessingPayment = false;
  bool isWaitingForPaymentReturn = false;
  String? pendingBookingId;

  // Fabric upload states
  List<String> _fabricReferenceImages = [];
  String _fabricDetails = '';
  bool _isUploadingFabricImage = false;
  final TextEditingController _fabricNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    bookingData = widget.bookingData;
    _loadAddresses();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fabricNotesController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && isWaitingForPaymentReturn) {
      _handlePaymentReturn();
    }
  }

  Future<void> _handlePaymentReturn() async {
    if (!mounted) return;

    setState(() {
      isWaitingForPaymentReturn = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade400),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Processing Payment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we confirm your payment...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 7));

    if (!mounted) return;

    Navigator.of(context).pop();

    if (pendingBookingId != null && pendingBookingId!.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OrderDetailsScreen(
            bookingId: pendingBookingId,
            showContinueButton: true,
          ),
        ),
      );
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _launchPaymentUrl(String url) async {
    try {
      final Uri paymentUri = Uri.parse(url);

      if (await canLaunchUrl(paymentUri)) {
        setState(() {
          isWaitingForPaymentReturn = true;
        });

        await launchUrl(
          paymentUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch payment URL');
      }
    } catch (e) {
      setState(() {
        isWaitingForPaymentReturn = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open payment link: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _createBookingAPI(Map<String, dynamic> bookingData) async {
    try {
      const String apiUrl = 'http://100.27.221.127:3000/api/v1/bookings';
      final AuthService authService = AuthService();
      final token = await authService.getToken();

      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      print(token);

      final url = Uri.parse(apiUrl);

      if (this.bookingData.selectedAddress != null) {
        final address = this.bookingData.selectedAddress!;
        bookingData['address'] = {
          'id': address.id,
          'label': address.label,
          'street': address.street,
          'city': address.city,
          'state': address.state,
          'pincode': address.pincode,
          'mobile': address.mobile,
          'isDefault': address.isDefault,
        };
      }

      print('Calling API: $url');
      print('Request Body: ${json.encode(bookingData)}');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(bookingData),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData;
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Invalid booking data';
        throw Exception(errorMessage);
      } else if (response.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Failed to create booking. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createBooking: $e');
      rethrow;
    }
  }

  Future<void> _loadAddresses() async {
    setState(() {
      isLoadingAddresses = true;
      addressError = null;
    });

    try {
      final fetchedAddresses = await _addressService.getAllAddresses();

      setState(() {
        if (fetchedAddresses != null) {
          addresses = fetchedAddresses;

          if (bookingData.selectedAddress == null && addresses.isNotEmpty) {
            final defaultAddress = addresses.firstWhere(
                  (addr) => addr.isDefault,
              orElse: () => addresses.first,
            );
            bookingData = bookingData.copyWith(selectedAddress: defaultAddress);
          }
        }
        isLoadingAddresses = false;
      });
    } catch (e) {
      setState(() {
        isLoadingAddresses = false;
        addressError = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load addresses: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadAddresses,
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadFabricImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isUploadingFabricImage = true;
        });

        try {
          final imageUrl = await _profileService.uploadProfileImage(File(image.path));

          setState(() {
            _fabricReferenceImages.add(imageUrl);
            _isUploadingFabricImage = false;
          });

          _showSuccessSnackBar('Image uploaded successfully!');
          debugPrint('✅ Fabric image uploaded: $imageUrl');
        } catch (e) {
          setState(() {
            _isUploadingFabricImage = false;
          });

          if (e.toString().contains('Unauthorized') ||
              e.toString().contains('Invalid token') ||
              e.toString().contains('Authentication token not found')) {
            _showErrorSnackBar('Session expired. Please login again.');
            return;
          }

          _showErrorSnackBar('Failed to upload image: ${e.toString()}');
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingFabricImage = false;
      });
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  void _removeFabricImage(int index) {
    setState(() {
      _fabricReferenceImages.removeAt(index);
    });
  }

  void _updateCategoryQuantity(String subCategoryId, int change) {
    setState(() {
      final categoryIndex = bookingData.categories
          .indexWhere((c) => c.subCategoryId == subCategoryId);

      if (categoryIndex != -1) {
        final currentQuantity = bookingData.categories[categoryIndex].quantity;
        final newQuantity = currentQuantity + change;

        if (newQuantity > 0) {
          bookingData.categories[categoryIndex] = bookingData.categories[categoryIndex]
              .copyWith(quantity: newQuantity);
        } else {
          bookingData.categories.removeAt(categoryIndex);
        }

        _recalculatePayment();
      }
    });
  }

  void _updateCategoryTag(String subCategoryId, String tag) {
    setState(() {
      final categoryIndex = bookingData.categories
          .indexWhere((c) => c.subCategoryId == subCategoryId);
      if (categoryIndex != -1) {
        bookingData.categories[categoryIndex].tag = tag;
      }
    });
  }

  void _updateCategoryReference(String subCategoryId, String reference) {
    setState(() {
      final categoryIndex = bookingData.categories
          .indexWhere((c) => c.subCategoryId == subCategoryId);
      if (categoryIndex != -1) {
        bookingData.categories[categoryIndex].reference = reference;
      }
    });
  }

  void _recalculatePayment() {
    final totalTailoring = bookingData.categories
        .fold<int>(0, (sum, category) => sum + category.totalPrice);

    setState(() {
      bookingData = bookingData.copyWith(
        paymentBreakup: PaymentBreakup.calculate(totalTailoring: totalTailoring),
      );
    });
  }

  void _updateDateTime(String date, String time) {
    final requestedDateTime = _parseDateTime(date, time);
    setState(() {
      bookingData = bookingData.copyWith(
        pickupDate: date,
        pickupTime: time,
        requestedDateTime: requestedDateTime,
      );
    });
  }

  DateTime _parseDateTime(String date, String time) {
    DateTime baseDate;
    final now = DateTime.now();

    if (date.toLowerCase().contains('today')) {
      baseDate = now;
    } else if (date.toLowerCase().contains('tomorrow')) {
      baseDate = now.add(const Duration(days: 1));
    } else {
      baseDate = now;
    }

    try {
      final timeParts = time.split(' ');
      final hourMin = timeParts[0].split(':');
      int hour = int.parse(hourMin[0]);
      final minute = int.parse(hourMin[1]);
      final isPM = timeParts.length > 1 && timeParts[1].toUpperCase() == 'PM';

      if (isPM && hour != 12) {
        hour += 12;
      } else if (!isPM && hour == 12) {
        hour = 0;
      }

      return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
    } catch (e) {
      return DateTime(baseDate.year, baseDate.month, baseDate.day, now.hour, now.minute);
    }
  }

  void _showAddFabricBottomSheet() {
    _fabricNotesController.text = _fabricDetails;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: const DecorationImage(
                          image: NetworkImage(
                            'https://images.unsplash.com/photo-1591195853828-11db59a44f6b',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Get Fabric',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fabric Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _fabricNotesController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Add if any notes',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                          ),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            _fabricDetails = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Reference Image',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_fabricReferenceImages.isNotEmpty) ...[
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _fabricReferenceImages.asMap().entries.map((entry) {
                            final index = entry.key;
                            final imageUrl = entry.value;
                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                    image: DecorationImage(
                                      image: NetworkImage(imageUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -8,
                                  right: -8,
                                  child: IconButton(
                                    icon: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade400,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    onPressed: () {
                                      setModalState(() {
                                        _removeFabricImage(index);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                      ],
                      InkWell(
                        onTap: _isUploadingFabricImage ? null : () async {
                          await _pickAndUploadFabricImage();
                          setModalState(() {});
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              style: BorderStyle.solid,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isUploadingFabricImage)
                                CircularProgressIndicator(
                                  color: Colors.red.shade400,
                                )
                              else
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 40,
                                  color: Colors.grey.shade600,
                                ),
                              const SizedBox(height: 12),
                              Text(
                                _isUploadingFabricImage
                                    ? 'Uploading...'
                                    : 'Upload Fabric Reference',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              if (!_isUploadingFabricImage) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Tap to upload image',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_fabricReferenceImages.isEmpty && _fabricDetails.trim().isEmpty) {
                          _showErrorSnackBar('Please add fabric details or upload at least one image');
                          return;
                        }

                        setState(() {
                          bookingData = bookingData.copyWith(
                            bringOwnFabric: false,
                          );
                        });
                        Navigator.pop(context);
                        _showSuccessSnackBar('Fabric details added successfully!');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Add Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  // NEW: Show time slot picker
  void _showTimeSlotPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TimeSlotPicker(
        initialDate: bookingData.pickupDate,
        initialTime: bookingData.pickupTime,
        onConfirm: (date, time) {
          _updateDateTime(date, time);
          _showSuccessSnackBar('Pickup time updated successfully!');
        },
      ),
    );
  }

  void _showAddressSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAddressSelectionSheet(),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (bookingData.categories.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
    }

    final hasFabricDetails = _fabricReferenceImages.isNotEmpty || _fabricDetails.trim().isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Book Appointment',
          style: TextStyle(
            color: Colors.black87,
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: screenWidth * 0.04),
                      _buildSectionTitle('Selected Services'),
                      _buildAddFabricCard(hasFabricDetails),
                      SizedBox(height: screenWidth * 0.03),
                      _buildSelectedServicesList(),
                      SizedBox(height: screenWidth * 0.06),
                      _buildSectionTitle('Preferred Pickup Time'),
                      _buildPickupTimeCard(),
                      SizedBox(height: screenWidth * 0.06),
                      _buildSectionTitle('Pickup Location'),
                      _buildPickupLocationCard(),
                      SizedBox(height: screenWidth * 0.06),
                      _buildSectionTitle('Payment Breakup'),
                      _buildPaymentBreakup(),
                      SizedBox(height: screenWidth * 0.25),
                    ],
                  ),
                ),
              ),
              _buildPaymentFooter(),
            ],
          ),
          if (isProcessingPayment)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Processing your booking...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenWidth * 0.02,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: screenWidth * 0.04,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildAddFabricCard(bool hasFabricDetails) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      decoration: BoxDecoration(
        color: hasFabricDetails ? Colors.green.shade700 : Colors.brown.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showAddFabricBottomSheet,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Row(
              children: [
                Container(
                  width: screenWidth * 0.15,
                  height: screenWidth * 0.15,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1591195853828-11db59a44f6b',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasFabricDetails ? 'Fabric Added' : 'Get Fabric',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.01),
                      Text(
                        hasFabricDetails
                            ? '${_fabricReferenceImages.length} image${_fabricReferenceImages.length != 1 ? 's' : ''} uploaded'
                            : 'we\'ll bring fabric with us',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenWidth * 0.02,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasFabricDetails ? Icons.edit : Icons.add,
                        size: screenWidth * 0.04,
                        color: Colors.white,
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Text(
                        hasFabricDetails ? 'Edit' : 'Add Fabric',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedServicesList() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: bookingData.categories.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          final category = bookingData.categories[index];
          return _buildServiceItem(category);
        },
      ),
    );
  }

  Widget _buildServiceItem(BookingCategoryExtended category) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: screenWidth * 0.18,
                height: screenWidth * 0.18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(category.image),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.serviceName,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    Text(
                      '${category.subCategoryName} · ₹${category.price}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.remove,
                        size: screenWidth * 0.045,
                        color: Colors.white,
                      ),
                      onPressed: () => _updateCategoryQuantity(category.subCategoryId, -1),
                      padding: EdgeInsets.all(screenWidth * 0.01),
                      constraints: BoxConstraints(
                        minWidth: screenWidth * 0.08,
                        minHeight: screenWidth * 0.08,
                      ),
                    ),
                    Container(
                      constraints: BoxConstraints(minWidth: screenWidth * 0.06),
                      child: Text(
                        '${category.quantity}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add,
                        size: screenWidth * 0.045,
                        color: Colors.white,
                      ),
                      onPressed: () => _updateCategoryQuantity(category.subCategoryId, 1),
                      padding: EdgeInsets.all(screenWidth * 0.01),
                      constraints: BoxConstraints(
                        minWidth: screenWidth * 0.08,
                        minHeight: screenWidth * 0.08,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.03),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showTagDialog(category),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: EdgeInsets.symmetric(vertical: screenWidth * 0.025),
                  ),
                  child: Text(
                    category.tag ?? 'Tag',
                    style: TextStyle(
                      fontSize: screenWidth * 0.032,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showReferenceDialog(category),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: EdgeInsets.symmetric(vertical: screenWidth * 0.025),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category.reference ?? 'Reference',
                        style: TextStyle(
                          fontSize: screenWidth * 0.032,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Icon(
                        Icons.info_outline,
                        size: screenWidth * 0.04,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickupTimeCard() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showTimeSlotPicker,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.access_time,
                    color: Colors.grey.shade700,
                    size: screenWidth * 0.06,
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bookingData.pickupDate,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.005),
                      Text(
                        bookingData.pickupTime,
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade600,
                  size: screenWidth * 0.06,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickupLocationCard() {
    final screenWidth = MediaQuery.of(context).size.width;

    if (isLoadingAddresses) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (addressError != null) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade400,
              size: screenWidth * 0.08,
            ),
            SizedBox(height: screenWidth * 0.02),
            Text(
              'Failed to load addresses',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: screenWidth * 0.035,
              ),
            ),
            SizedBox(height: screenWidth * 0.02),
            TextButton(
              onPressed: _loadAddresses,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final selectedAddress = bookingData.selectedAddress;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showAddressSelectionBottomSheet,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: Colors.grey.shade700,
                    size: screenWidth * 0.06,
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedAddress?.addressType ?? 'Select Location',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (selectedAddress != null) ...[
                        SizedBox(height: screenWidth * 0.01),
                        Text(
                          '${selectedAddress.street}, ${selectedAddress.city}',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade600,
                  size: screenWidth * 0.06,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentBreakup() {
    final screenWidth = MediaQuery.of(context).size.width;
    final breakup = bookingData.paymentBreakup;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          children: [
            _buildBreakupRow('Total Tailoring', '₹${breakup.totalTailoring}'),
            SizedBox(height: screenWidth * 0.03),
            _buildBreakupRow('Pickup Fee', '₹${breakup.pickupFee}'),
            SizedBox(height: screenWidth * 0.03),
            _buildBreakupRow('Tax', '₹${breakup.tax}'),
            if (breakup.discount > 0) ...[
              SizedBox(height: screenWidth * 0.03),
              _buildBreakupRow(
                'Discount',
                '-₹${breakup.discount}',
                isDiscount: true,
              ),
            ],
            SizedBox(height: screenWidth * 0.04),
            Divider(height: 1, color: Colors.grey.shade300),
            SizedBox(height: screenWidth * 0.04),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '₹${breakup.totalAmount}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakupRow(String label, String value, {bool isDiscount = false}) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.038,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: screenWidth * 0.038,
            fontWeight: FontWeight.w600,
            color: isDiscount ? Colors.green.shade700 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentFooter() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (bookingData.categories.isEmpty || isProcessingPayment)
                ? null
                : () => _processPayment(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: EdgeInsets.symmetric(vertical: screenWidth * 0.04),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isProcessingPayment
                  ? 'Processing...'
                  : 'Pay  ₹${bookingData.paymentBreakup.totalAmount}',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressSelectionSheet() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.06),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Pickup Location',
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.04),
          if (addresses.isEmpty)
            Center(
              child: Column(
                children: [
                  SizedBox(height: screenWidth * 0.06),
                  Icon(
                    Icons.location_off,
                    size: screenWidth * 0.16,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: screenWidth * 0.04),
                  Text(
                    'No addresses found',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.06),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: addresses.length,
                itemBuilder: (context, index) {
                  final address = addresses[index];
                  final isSelected = bookingData.selectedAddress?.id == address.id;

                  return Container(
                    margin: EdgeInsets.only(bottom: screenWidth * 0.03),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.red.shade400 : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () {
                        setState(() {
                          bookingData = bookingData.copyWith(selectedAddress: address);
                        });
                        Navigator.pop(context);
                      },
                      leading: Icon(
                        Icons.location_on,
                        color: isSelected ? Colors.red.shade400 : Colors.grey.shade600,
                      ),
                      title: Row(
                        children: [
                          Text(
                            address.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (address.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Default',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('${address.street}, ${address.city}, ${address.state} - ${address.pincode}'),
                          const SizedBox(height: 2),
                          Text(
                            address.mobile,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: Colors.red.shade400)
                          : null,
                    ),
                  );
                },
              ),
            ),
          SizedBox(height: screenWidth * 0.04),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/add-address').then((_) {
                _loadAddresses();
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Address'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  void _showTagDialog(BookingCategoryExtended category) {
    final controller = TextEditingController(text: category.tag);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., For work, Casual wear',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateCategoryTag(category.subCategoryId, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showReferenceDialog(BookingCategoryExtended category) {
    final controller = TextEditingController(text: category.reference);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Reference'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add a reference note for the tailor',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g., Like the collar in photo',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateCategoryReference(category.subCategoryId, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _processPayment() {
    if (bookingData.selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a pickup location'),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }

    print(bookingData.toBookingRequest(context).toJson()["profileId"]);

    if (bookingData.toBookingRequest(context).toJson()["profileId"] == null || bookingData.toBookingRequest(context).toJson()["profileId"] == "") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please create a Profile to complete Booking'),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }

    _showConfirmationDialog();
  }

  void _showConfirmationDialog() {
    final hasFabricDetails = _fabricReferenceImages.isNotEmpty || _fabricDetails.trim().isNotEmpty;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Confirm Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Amount: ₹${bookingData.paymentBreakup.totalAmount}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Services: ${bookingData.categories.length} items',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            if (hasFabricDetails)
              Text(
                'Fabric: ${_fabricReferenceImages.length} reference image${_fabricReferenceImages.length != 1 ? 's' : ''}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            Text(
              'Pickup: ${bookingData.pickupDate} ${bookingData.pickupTime}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            Text(
              'Location: ${bookingData.selectedAddress!.addressType}',
              style: TextStyle(color: Colors.grey.shade700),
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
              _confirmBooking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Proceed to Pay'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBooking() async {
    setState(() {
      isProcessingPayment = true;
    });

    try {
      final bookingRequest = bookingData.toBookingRequest(context);
      final requestJson = bookingRequest.toJson();

      if (_fabricReferenceImages.isNotEmpty) {
        requestJson['referenceImages'] = _fabricReferenceImages;
      }

      if (_fabricDetails.trim().isNotEmpty) {
        requestJson['fabricNotes'] = _fabricDetails.trim();
      }

      print('Booking Request JSON (with fabric details):');
      print(json.encode(requestJson));

      final response = await _createBookingAPI(requestJson);

      setState(() {
        isProcessingPayment = false;
      });

      if (response != null) {
        setState(() {
          _fabricReferenceImages.clear();
          _fabricDetails = '';
          _fabricNotesController.clear();
        });

        final String? paymentLink = response['paymentLink'];
        final String? bookingId = response['bookingId'];

        if (paymentLink != null && paymentLink.isNotEmpty) {
          pendingBookingId = bookingId;
          await _launchPaymentUrl(paymentLink);
        } else {
          throw Exception('Payment link not found in response');
        }
      } else {
        throw Exception('Failed to create booking');
      }
    } catch (e) {
      setState(() {
        isProcessingPayment = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _confirmBooking,
            ),
          ),
        );
      }
    }
  }
}