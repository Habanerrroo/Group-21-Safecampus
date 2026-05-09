import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class LocationPicker extends StatefulWidget {
  final String? selectedLocation;
  final Function(String) onLocationSelected;

  const LocationPicker({
    super.key,
    this.selectedLocation,
    required this.onLocationSelected,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  String? _selectedLocation;
  
  // Predefined campus locations
  final List<String> _locations = [
    // Blocks
    'Block A',
    'Block B',
    'Block C',
    'Block D',
    'Block E',
    // Food Court
    'Food Court',
    // Boys Hostels
    'Boys Hostel 1',
    'Boys Hostel 2',
    'Boys Hostel 3',
    'Boys Hostel 4',
    // Girls Hostels
    'Girls Hostel 1',
    'Girls Hostel 2',
    'Girls Hostel 3',
    'Girls Hostel 4',
    // Sports Facilities
    'Basketball court 1',
    'Basketball court 2',
    'Football field',
    // Parking
    'Car park 1',
    'Car park 2',
    'Car park 3',
    'Car park 4',
    'Car park 5',
    // Other Locations
    'Love Garden',
    'Student centre',
    'Turkish village',
    'Mini mart',
  ];

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.selectedLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Location',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLocation,
              isExpanded: true,
              hint: Text(
                'Select a location...',
                style: GoogleFonts.inter(
                  color: AppColors.foregroundLight,
                ),
              ),
              dropdownColor: AppColors.surface,
              style: GoogleFonts.inter(color: Colors.white),
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.secondary),
              items: _locations.map((location) {
                return DropdownMenuItem<String>(
                  value: location,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 20,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            location,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedLocation = value);
                  widget.onLocationSelected(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

