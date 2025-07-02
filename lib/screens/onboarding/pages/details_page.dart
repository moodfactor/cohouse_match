import 'package:flutter/material.dart';

class DetailsPage extends StatelessWidget {
  final VoidCallback onNext;
  final TextEditingController bioController;
  final TextEditingController locationController;
  final TextEditingController budgetController;
  final Function(String?) onGenderChanged;

  const DetailsPage({
    super.key,
    required this.onNext,
    required this.bioController,
    required this.locationController,
    required this.budgetController,
    required this.onGenderChanged,
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
          TextFormField(
            controller: locationController,
            decoration: const InputDecoration(labelText: 'Preferred Location (e.g., City, State)'),
            validator: (val) => (val == null || val.isEmpty) ? 'Please enter a location' : null,
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