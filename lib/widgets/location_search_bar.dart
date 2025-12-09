// lib/widgets/location_search_bar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../models/location_model.dart';
import '../utils/responsive_helper.dart';

class LocationSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(LocationData) onSearchResultSelected;

  const LocationSearchBar({
    Key? key,
    required this.controller,
    required this.onSearchResultSelected,
  }) : super(key: key);

  @override
  State<LocationSearchBar> createState() => _LocationSearchBarState();
}

class _LocationSearchBarState extends State<LocationSearchBar> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            style: TextStyle(fontSize: responsive.sp(14)),
            decoration: InputDecoration(
              hintText: 'Search location',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: responsive.sp(14),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey[600],
                size: responsive.sp(20),
              ),
              suffixIcon: widget.controller.text.isNotEmpty
                  ? IconButton(
                icon: Icon(
                  Icons.clear,
                  size: responsive.sp(20),
                ),
                onPressed: () {
                  widget.controller.clear();
                  context.read<LocationProvider>().clearSearchResults();
                },
              )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsive.wp(4),
                vertical: responsive.hp(1.5),
              ),
            ),
            onChanged: (value) {
              context.read<LocationProvider>().searchLocation(value);
              setState(() {});
            },
          ),
        ),

        // Search Results
        Consumer<LocationProvider>(
          builder: (context, provider, child) {
            if (provider.searchResults.isEmpty) {
              return const SizedBox.shrink();
            }

            return Container(
              margin: EdgeInsets.only(top: responsive.hp(1)),
              constraints: BoxConstraints(
                maxHeight: responsive.hp(30), // Max 30% of screen height
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: provider.searchResults.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey[200],
                ),
                itemBuilder: (context, index) {
                  final location = provider.searchResults[index];
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: responsive.wp(4),
                      vertical: responsive.hp(0.5),
                    ),
                    leading: Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: responsive.sp(24),
                    ),
                    title: Text(
                      location.shortAddress,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: responsive.sp(14),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      location.fullAddress,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: responsive.sp(12),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      provider.selectSearchResult(location);
                      widget.onSearchResultSelected(location);
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}