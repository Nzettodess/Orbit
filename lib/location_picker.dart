import 'package:flutter/material.dart';
import 'package:csc_picker_plus/csc_picker_plus.dart';

class LocationPicker extends StatefulWidget {
  final Function(String country, String? state) onLocationSelected;

  const LocationPicker({super.key, required this.onLocationSelected});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  String? countryValue;
  String? stateValue;
  String? cityValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Set Your Location",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          CSCPickerPlus(
            showCities: false,
            onCountryChanged: (value) {
              setState(() {
                countryValue = value;
              });
            },
            onStateChanged: (value) {
              setState(() {
                stateValue = value;
              });
            },
            onCityChanged: (value) {
              setState(() {
                cityValue = value;
              });
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (countryValue != null) {
                widget.onLocationSelected(countryValue!, stateValue);
                Navigator.pop(context);
              }
            },
            child: const Text("Save Location"),
          ),
        ],
      ),
    );
  }
}
