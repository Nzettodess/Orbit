import 'package:flutter/material.dart';
import '../theme.dart';
import 'searchable_location_input.dart';
import 'location_data.dart';

class DefaultLocationPicker extends StatefulWidget {
  final Function(String country, String? state) onLocationSelected;
  final String? defaultCountry;
  final String? defaultState;

  const DefaultLocationPicker({
    super.key,
    required this.onLocationSelected,
    this.defaultCountry,
    this.defaultState,
  });

  @override
  State<DefaultLocationPicker> createState() => _DefaultLocationPickerState();
}

class _DefaultLocationPickerState extends State<DefaultLocationPicker> {
  String? countryValue;
  String? stateValue;

  @override
  void initState() {
    super.initState();
    countryValue = widget.defaultCountry != null 
        ? LocationData.cleanText(widget.defaultCountry!) 
        : null;
    stateValue = widget.defaultState != null 
        ? LocationData.cleanText(widget.defaultState!) 
        : null;
  }

  @override
  void didUpdateWidget(covariant DefaultLocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.defaultCountry != oldWidget.defaultCountry) {
      setState(() {
        countryValue = widget.defaultCountry != null 
            ? LocationData.cleanText(widget.defaultCountry!) 
            : null;
      });
    }
    if (widget.defaultState != oldWidget.defaultState) {
      setState(() {
        stateValue = widget.defaultState != null 
            ? LocationData.cleanText(widget.defaultState!) 
            : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Set Default Location",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "This will be your home location",
            style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 20),
          
          // Searchable & Free-Text Location Input
          SearchableLocationInput(
            initialCountry: countryValue,
            initialState: stateValue,
            onCountryChanged: (value) {
              setState(() {
                countryValue = value.trim().isNotEmpty ? value.trim() : null;
              });
            },
            onStateChanged: (value) {
              setState(() {
                stateValue = (value != null && value.trim().isNotEmpty) ? value.trim() : null;
              });
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (countryValue != null && countryValue!.isNotEmpty) {
                  widget.onLocationSelected(countryValue!, stateValue);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter or select a country/location")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getButtonBackground(context),
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Save Default Location"),
            ),
          ),
        ],
      ),
    );
  }
}
