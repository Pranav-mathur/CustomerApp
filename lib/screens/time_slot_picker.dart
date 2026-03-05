// components/time_slot_picker.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/tailor_service.dart';

class TimeSlotPicker extends StatefulWidget {
  final String? initialDate;
  final String? initialTime;
  final String tailorId; // Required to fetch availability from API
  final Function(String date, String time) onConfirm;

  const TimeSlotPicker({
    Key? key,
    this.initialDate,
    this.initialTime,
    required this.tailorId,
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

  bool _isLoading = true;
  String? _errorMessage;

  final TailorService _tailorService = TailorService();

  @override
  void initState() {
    super.initState();
    _fetchAvailability();
  }

  // ── API fetch & parse ─────────────────────────────────────────────────────

  Future<void> _fetchAvailability() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _tailorService.getTailorAvailability(widget.tailorId);
      _parseAvailability(data);
    } catch (e) {
      debugPrint('❌ TimeSlotPicker fetch error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to load available slots. Please try again.';
        });
      }
    }
  }

  void _parseAvailability(Map<String, dynamic> data) {
    final List<dynamic> availability = data['availability'] ?? [];

    final List<DateOption> dates = [];
    final Map<String, List<TimeSlot>> slots = {};

    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    for (final dayEntry in availability) {
      final String dateStr = dayEntry['date'] ?? '';
      final String apiDayLabel = dayEntry['day'] ?? dateStr;
      final List<dynamic> rawSlots = dayEntry['slots'] ?? [];

      if (dateStr.isEmpty) continue;

      dates.add(DateOption(
        label: _buildDateLabel(dateStr, todayStr, apiDayLabel),
        value: dateStr,
        date: DateTime.tryParse(dateStr) ?? DateTime.now(),
      ));

      slots[dateStr] = rawSlots
          .map(_apiSlotToTimeSlot)
          .where((s) => s != null)
          .cast<TimeSlot>()
          .toList();
    }

    if (!mounted) return;

    setState(() {
      availableDates = dates;
      timeSlots = slots;
      _isLoading = false;
    });

    _applyInitialSelection();
  }

  TimeSlot? _apiSlotToTimeSlot(dynamic s) {
    final String time = s['time'] ?? '';
    final int hour = (s['hour'] as num?)?.toInt() ?? -1;
    final String status = s['status'] ?? 'unavailable';

    if (time.isEmpty) return null;

    // Exclude hours 0–4 (midnight to early morning) — not shown in the picker
    if (hour >= 0 && hour < 5) return null;

    return TimeSlot(
      time: time,
      period: _periodForHour(hour),
      isAvailable: status == 'available',
    );
  }

  /// Maps hour (5–23) to period sections in chronological order:
  /// Morning: 5 AM – 11 AM, Afternoon: 12 PM – 5 PM, Evening: 6 PM – 11 PM
  String _periodForHour(int hour) {
    if (hour >= 5 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 18) return 'After noon';
    return 'Evening'; // 18–23
  }

  /// Produces human-readable labels identical to the original local generator.
  String _buildDateLabel(String dateStr, String todayStr, String apiDayLabel) {
    try {
      final date = DateTime.parse(dateStr);
      final today = DateTime.parse(todayStr);
      final diff = date.difference(today).inDays;

      if (diff == 0) return 'Today, ${DateFormat('EEE').format(date)}';
      if (diff == 1) return 'Tomorrow, ${DateFormat('EEE').format(date)}';
      return DateFormat('EEE, d MMM').format(date);
    } catch (_) {
      return apiDayLabel;
    }
  }

  void _applyInitialSelection() {
    if (availableDates.isEmpty) return;

    if (widget.initialDate != null && widget.initialTime != null) {
      final match = availableDates.firstWhere(
            (d) => d.label == widget.initialDate,
        orElse: () => availableDates[0],
      );
      setState(() {
        selectedDate = match.value;
        selectedTime = widget.initialTime;
      });
    } else {
      final firstDate = availableDates[0];
      final firstSlots = timeSlots[firstDate.value] ?? [];
      final firstAvailable = firstSlots.firstWhere(
            (s) => s.isAvailable,
        orElse: () => TimeSlot(time: '', period: 'Morning', isAvailable: false),
      );
      setState(() {
        selectedDate = firstDate.value;
        selectedTime =
        firstAvailable.time.isNotEmpty ? firstAvailable.time : null;
      });
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _getSelectedDateLabel() {
    final dateOption = availableDates.firstWhere(
          (d) => d.value == selectedDate,
      orElse: () => availableDates[0],
    );
    return dateOption.label;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
              border:
              Border(bottom: BorderSide(color: Colors.grey.shade200)),
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
          Expanded(child: _buildBody(context)),

          // Footer
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.redAccent),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style:
                TextStyle(fontSize: 15, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchAvailability,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Retry',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (availableDates.isEmpty) {
      return Center(
        child: Text(
          'No slots available at the moment.',
          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
        ),
      );
    }

    final selectedSlots = timeSlots[selectedDate] ?? [];
    final morningSlots =
    selectedSlots.where((s) => s.period == 'Morning').toList();
    final afternoonSlots =
    selectedSlots.where((s) => s.period == 'After noon').toList();
    final eveningSlots =
    selectedSlots.where((s) => s.period == 'Evening').toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date selector (left panel)
        Container(
          width: MediaQuery.of(context).size.width * 0.35,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border:
            Border(right: BorderSide(color: Colors.grey.shade200)),
          ),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: availableDates.length,
            itemBuilder: (context, index) {
              final dateOption = availableDates[index];
              final isSelected = selectedDate == dateOption.value;

              return InkWell(
                onTap: () =>
                    setState(() => selectedDate = dateOption.value),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 20),
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
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
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

        // Time slots (right panel)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (morningSlots.isNotEmpty) ...[
                  _buildPeriodLabel('Morning'),
                  const SizedBox(height: 12),
                  _buildTimeSlotGrid(morningSlots),
                  const SizedBox(height: 24),
                ],
                if (afternoonSlots.isNotEmpty) ...[
                  _buildPeriodLabel('After noon'),
                  const SizedBox(height: 12),
                  _buildTimeSlotGrid(afternoonSlots),
                  const SizedBox(height: 24),
                ],
                if (eveningSlots.isNotEmpty) ...[
                  _buildPeriodLabel('Evening'),
                  const SizedBox(height: 12),
                  _buildTimeSlotGrid(eveningSlots),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
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
              ? () => setState(() => selectedTime = slot.time)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
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
                fontWeight:
                isSelected ? FontWeight.bold : FontWeight.w500,
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

  Widget _buildFooter(BuildContext context) {
    return Container(
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
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Text(
                      _getSelectedDateLabel(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time,
                        size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Text(
                      selectedTime!,
                      style: const TextStyle(
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
    );
  }
}

// ── Data models (interface unchanged) ─────────────────────────────────────────

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