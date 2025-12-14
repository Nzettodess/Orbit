import 'package:flutter/material.dart';
import 'package:csc_picker_plus/csc_picker_plus.dart';
import '../theme.dart';

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
  String? cityValue;

  @override
  void initState() {
    super.initState();
    countryValue = widget.defaultCountry;
    stateValue = widget.defaultState;
  }

  // Map country names to CscCountry enum values
  CscCountry? _getCountryEnum(String? countryName) {
    if (countryName == null) return null;
    
    final countryMap = {
      'United States': CscCountry.United_States,
      'United Kingdom': CscCountry.United_Kingdom,
      'Canada': CscCountry.Canada,
      'Australia': CscCountry.Australia,
      'New Zealand': CscCountry.New_Zealand,
      'Singapore': CscCountry.Singapore,
      'Malaysia': CscCountry.Malaysia,
      'Indonesia': CscCountry.Indonesia,
      'Thailand': CscCountry.Thailand,
      'Philippines': CscCountry.Philippines,
      'Vietnam': CscCountry.Vietnam,
      'Japan': CscCountry.Japan,
      'China': CscCountry.China,
      'Hong Kong': CscCountry.China,
      'Taiwan': CscCountry.Taiwan,
      'India': CscCountry.India,
      'Germany': CscCountry.Germany,
      'France': CscCountry.France,
      'Italy': CscCountry.Italy,
      'Spain': CscCountry.Spain,
      'Netherlands': CscCountry.Belgium,
      'Belgium': CscCountry.Belgium,
      'Switzerland': CscCountry.Switzerland,
      'Austria': CscCountry.Austria,
      'Sweden': CscCountry.Sweden,
      'Norway': CscCountry.Norway,
      'Denmark': CscCountry.Denmark,
      'Finland': CscCountry.Finland,
      'Poland': CscCountry.Poland,
      'Ireland': CscCountry.Ireland,
      'Portugal': CscCountry.Portugal,
      'Greece': CscCountry.Greece,
      'Brazil': CscCountry.Brazil,
      'Mexico': CscCountry.Mexico,
      'Argentina': CscCountry.Argentina,
      'Chile': CscCountry.Chile,
      'Colombia': CscCountry.Colombia,
      'South Africa': CscCountry.South_Africa,
      'Egypt': CscCountry.Egypt,
      'Nigeria': CscCountry.Nigeria,
      'Russia': CscCountry.Russia,
      'Turkey': CscCountry.Turkey,
      'Saudi Arabia': CscCountry.Saudi_Arabia,
      'United Arab Emirates': CscCountry.United_Arab_Emirates,
      'Israel': CscCountry.Israel,
    };
    
    return countryMap[countryName];
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
          
          // Location Selection
          CSCPickerPlus(
            showCities: false,
            defaultCountry: _getCountryEnum(countryValue) ?? CscCountry.United_States,
            dropdownDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            disabledDropdownDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            selectedItemStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
            dropdownHeadingStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            dropdownItemStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
            dropdownDialogRadius: 12,
            searchBarRadius: 12,
            onCountryChanged: (value) {
              // Strip emojis from CSCPickerPlus values
              final cleaned = value?.replaceAll(RegExp(r'[\u{1F1E6}-\u{1F1FF}]|\p{Emoji_Presentation}|\p{Emoji}\uFE0F', unicode: true), '').trim();
              setState(() {
                countryValue = cleaned;
              });
            },
            onStateChanged: (value) {
              // Strip emojis from CSCPickerPlus values
              final cleaned = value?.replaceAll(RegExp(r'[\u{1F1E6}-\u{1F1FF}]|\p{Emoji_Presentation}|\p{Emoji}\uFE0F', unicode: true), '').trim();
              setState(() {
                stateValue = cleaned;
              });
            },
            onCityChanged: (value) {
              setState(() {
                cityValue = value;
              });
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (countryValue != null) {
                  widget.onLocationSelected(countryValue!, stateValue);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select a country")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getButtonBackground(context),
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text("Save Default Location"),
            ),
          ),
        ],
      ),
    );
  }
}
