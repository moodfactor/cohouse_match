import 'package:flutter/material.dart';
import 'package:cohouse_match/screens/location_picker_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DetailsPage extends StatelessWidget {
  final VoidCallback onNext;
  final TextEditingController bioController;
  final TextEditingController locationController;
  final TextEditingController budgetController;
  final Function(String?) onGenderChanged;
  final Function(String address, GeoPoint coordinates) onLocationSelected;

  const DetailsPage({
    super.key,
    required this.onNext,
    required this.bioController,
    required this.locationController,
    required this.budgetController,
    required this.onGenderChanged,
    required this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView( // Using ListView to prevent overflow
        children: [
          const Text(
            "Tell everyone a bit more.",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: bioController,
            decoration: const InputDecoration(labelText: 'Your Bio', hintText: 'What are you passionate about? What makes you a great housemate?'),
            maxLines: 4,
            validator: (val) => (val == null || val.isEmpty) ? 'Please enter a bio' : null,
          ),
          const SizedBox(height: 20),
          // Location input using ListTile to navigate to LocationPickerScreen
          ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(locationController.text.isEmpty
                ? 'Select your location'
                : locationController.text),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
              );
              if (result != null && result is Map<String, dynamic>) {
                final String address = result['address'];
                final LatLng coords = result['coordinates'];
                onLocationSelected(address, GeoPoint(coords.latitude, coords.longitude));
                locationController.text = address; // Update the text controller for display
              }
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: budgetController,
            decoration: const InputDecoration(labelText: 'Monthly Budget (\$)'),
            keyboardType: TextInputType.number,
            validator: (val) {
              if (val == null || val.isEmpty) return 'Please enter a budget';
              if (double.tryParse(val) == null) return 'Please enter a valid number';
              return null;
            },
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Gender'),
            items: <String>['Male', 'Female', 'Other']
                .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
            onChanged: onGenderChanged,
            validator: (val) => (val == null) ? 'Please select a gender' : null,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Almost Done!'),
            ),
          ),
        ],
      ),
    );
  }
}