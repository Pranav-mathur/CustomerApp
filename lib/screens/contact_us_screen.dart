// screens/contact_us_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'contact@carsadarzi.com',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: '+807744312468',
    );
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchMaps() async {
    final Uri mapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=HoneyKomb+by+Bhive+17th+Main+Road+HSR+Sector+2+Bengaluru+560109');
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Copied to clipboard"),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87, size: w * 0.065),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Contact Us",
          style: TextStyle(
            color: Colors.black,
            fontSize: w * 0.052,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),

      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: h * 0.015),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            SizedBox(height: h * 0.01),

            // OFFICE CARD
            _contactCard(
              context: context,
              w: w,
              title: "Office",
              icon: Icons.location_on_outlined,
              subtitle:
              "HoneyKomb by Bhive,\n17th Main Road, HSR Sector 2\nBengaluru - 560109",
              onTap: _launchMaps,
            ),

            SizedBox(height: h * 0.015),

            // EMAIL CARD
            _contactCard(
              context: context,
              w: w,
              title: "Email Address",
              icon: Icons.email_outlined,
              subtitle: "contact@carsadarzi.com",
              onTap: _launchEmail,
            ),

            SizedBox(height: h * 0.015),

            // PHONE CARD
            _contactCard(
              context: context,
              w: w,
              title: "Phone Number",
              icon: Icons.phone_outlined,
              subtitle: "+80 77443 12468",
              onTap: _launchPhone,
            ),

          ],
        ),
      ),
    );
  }

  Widget _contactCard({
    required BuildContext context,
    required double w,
    required String title,
    required IconData icon,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: w * 0.04,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: w * 0.03),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon,
                    color: Colors.grey.shade700, size: w * 0.07),

                SizedBox(width: w * 0.035),

                Expanded(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: w * 0.039,
                      color: Colors.black,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
