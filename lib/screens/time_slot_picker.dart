// components/time_slot_picker.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeSlotPicker extends StatefulWidget {
  final String? initialDate;
  final String? initialTime;
  final Function(String date, String time) onConfirm;

  const TimeSlotPicker({
    Key? key,
    this.initialDate,
    this.initialTime,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<TimeSlotPicker> createState() => _TimeSlotPickerState();
}

class _TimeSlotPickerState extends State<TimeSlotPicker> {
  String? selectedDate;
  String? selectedTime;
  List<DateOption> availableDates = [];
  Map<String, List<TimeSlot>> timeSlots = {};

  @override
  void initState() {
    super.initState();
    _generateAvailableDates();
    _generateTimeSlots();

    // Set initial selections
    if (widget.initialDate != null && widget.initialTime != null) {
      selectedDate = _findMatchingDateValue(widget.initialDate!);
      selectedTime = widget.initialTime;
    } else {
      // NEW: Set default to today and first available time slot
      if (availableDates.isNotEmpty) {
        selectedDate = availableDates[0].value;

        // Get first available time slot for today
        final todaySlots = timeSlots[selectedDate] ?? [];
        final firstAvailableSlot = todaySlots.firstWhere(
              (slot) => slot.isAvailable,
          orElse: () => todaySlots.isNotEmpty ? todaySlots[0] : TimeSlot(time: '', period: '', isAvailable: false),
        );

        if (firstAvailableSlot.time.isNotEmpty) {
          selectedTime = firstAvailableSlot.time;
        }
      }
    }
  }

  String? _findMatchingDateValue(String dateLabel) {
    // Try to find exact match first
    for (var dateOption in availableDates) {
      if (dateOption.label == dateLabel) {
        return dateOption.value;
      }
    }

    // If not found, return today's value
    return availableDates.isNotEmpty ? availableDates[0].value : null;
  }

  void _generateAvailableDates() {
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      String label;

      if (i == 0) {
        label = 'Today, ${DateFormat('EEE').format(date)}';
      } else if (i == 1) {
        label = 'Tomorrow, ${DateFormat('EEE').format(date)}';
      } else {
        label = DateFormat('EEE, d MMM').format(date);
      }

      availableDates.add(DateOption(
        label: label,
        date: date,
        value: DateFormat('yyyy-MM-dd').format(date),
      ));
    }

    // Select first date by default if no initial date
    if (selectedDate == null && availableDates.isNotEmpty) {
      selectedDate = availableDates[0].value;
    }
  }

  void _generateTimeSlots() {
    // Generate time slots for all dates
    for (var dateOption in availableDates) {
      timeSlots[dateOption.value] = _generateSlotsForDate(dateOption.date);
    }
  }

  List<TimeSlot> _generateSlotsForDate(DateTime date) {
    List<TimeSlot> slots = [];
    final now = DateTime.now();
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(now);

    // Morning slots: 10:00 AM - 11:30 AM
    for (int hour = 10; hour <= 11; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        if (hour == 11 && minute == 30) continue; // Stop at 11:30 AM

        final time = DateTime(date.year, date.month, date.day, hour, minute);
        final isAvailable = !isToday || time.isAfter(now.add(Duration(hours: 1)));

        slots.add(TimeSlot(
          time: DateFormat('h:mm a').format(time),
          period: 'Morning',
          isAvailable: isAvailable,
        ));
      }
    }

    // Afternoon slots: 12:00 PM - 5:30 PM
    for (int hour = 12; hour <= 17; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        if (hour == 17 && minute == 30) continue; // Stop at 5:00 PM

        final time = DateTime(date.year, date.month, date.day, hour, minute);
        final isAvailable = !isToday || time.isAfter(now.add(Duration(hours: 1)));

        slots.add(TimeSlot(
          time: DateFormat('h:mm a').format(time),
          period: 'After noon',
          isAvailable: isAvailable,
        ));
      }
    }

    // Evening slots: 6:00 PM - 8:00 PM
    for (int hour = 18; hour <= 20; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        if (hour == 20 && minute == 30) continue; // Stop at 8:00 PM

        final time = DateTime(date.year, date.month, date.day, hour, minute);
        final isAvailable = !isToday || time.isAfter(now.add(Duration(hours: 1)));

        slots.add(TimeSlot(
          time: DateFormat('h:mm a').format(time),
          period: 'Evening',
          isAvailable: isAvailable,
        ));
      }
    }

    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final selectedSlots = timeSlots[selectedDate] ?? [];
    final morningSlots = selectedSlots.where((s) => s.period == 'Morning').toList();
    final afternoonSlots = selectedSlots.where((s) => s.period == 'After noon').toList();
    final eveningSlots = selectedSlots.where((s) => s.period == 'Evening').toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Select Pickup Slot',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date selector (Left side)
                Container(
                  width: MediaQuery.of(context).size.width * 0.35,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: availableDates.length,
                    itemBuilder: (context, index) {
                      final dateOption = availableDates[index];
                      final isSelected = selectedDate == dateOption.value;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedDate = dateOption.value;
                            // Don't clear time selection when changing date
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: isSelected
                                    ? Colors.red.shade400
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Text(
                            dateOption.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? Colors.red.shade400
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Time slots (Right side)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Morning slots
                        if (morningSlots.isNotEmpty) ...[
                          Text(
                            'Morning',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTimeSlotGrid(morningSlots),
                          const SizedBox(height: 24),
                        ],

                        // Afternoon slots
                        if (afternoonSlots.isNotEmpty) ...[
                          Text(
                            'After noon',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTimeSlotGrid(afternoonSlots),
                          const SizedBox(height: 24),
                        ],

                        // Evening slots
                        if (eveningSlots.isNotEmpty) ...[
                          Text(
                            'Evening',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTimeSlotGrid(eveningSlots),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Footer with selected info and confirm button
          Container(
            padding: const EdgeInsets.all(16),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedDate != null && selectedTime != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getSelectedDateLabel(),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selectedTime!,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedDate != null && selectedTime != null
                          ? () {
                        widget.onConfirm(
                          _getSelectedDateLabel(),
                          selectedTime!,
                        );
                        Navigator.pop(context);
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm Slot',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotGrid(List<TimeSlot> slots) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final isSelected = selectedTime == slot.time;

        return InkWell(
          onTap: slot.isAvailable
              ? () {
            setState(() {
              selectedTime = slot.time;
            });
          }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: !slot.isAvailable
                  ? Colors.grey.shade100
                  : isSelected
                  ? Colors.red.shade400
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: !slot.isAvailable
                    ? Colors.grey.shade300
                    : isSelected
                    ? Colors.red.shade400
                    : Colors.grey.shade300,
              ),
            ),
            child: Text(
              slot.time,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: !slot.isAvailable
                    ? Colors.grey.shade400
                    : isSelected
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getSelectedDateLabel() {
    final dateOption = availableDates.firstWhere(
          (d) => d.value == selectedDate,
      orElse: () => availableDates[0],
    );
    return dateOption.label;
  }
}

class DateOption {
  final String label;
  final DateTime date;
  final String value;

  DateOption({
    required this.label,
    required this.date,
    required this.value,
  });
}

class TimeSlot {
  final String time;
  final String period;
  final bool isAvailable;

  TimeSlot({
    required this.time,
    required this.period,
    required this.isAvailable,
  });
}