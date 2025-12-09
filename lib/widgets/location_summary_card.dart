// lib/widgets/location_summary_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../utils/responsive_helper.dart';

class LocationSummaryCard extends StatelessWidget {
  const LocationSummaryCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return Consumer<LocationProvider>(
      builder: (context, provider, child) {
        final location = provider.selectedLocation;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(responsive.wp(4)),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: location == null
              ? Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Colors.grey[400],
                size: responsive.sp(24),
              ),
              SizedBox(width: responsive.wp(3)),
              Expanded(
                child: Text(
                  'Move map to select location',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: responsive.sp(14),
                  ),
                ),
              ),
            ],
          )
              : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on,
                color: Colors.red,
                size: responsive.sp(24),
              ),
              SizedBox(width: responsive.wp(3)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.shortAddress.isNotEmpty
                          ? location.shortAddress
                          : 'Selected Location',
                      style: TextStyle(
                        fontSize: responsive.sp(16),
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: responsive.hp(0.5)),
                    Text(
                      location.fullAddress,
                      style: TextStyle(
                        fontSize: responsive.sp(13),
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}