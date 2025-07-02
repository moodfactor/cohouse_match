import 'package:flutter/material.dart';

class DetailsPage extends StatefulWidget {
  final VoidCallback onNext;
  final Function(Map<String, dynamic>) onDataChanged;
  final GlobalKey<FormState> formKey;

  const DetailsPage({super.key, required this.onNext, required this.onDataChanged, required this.formKey});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _budgetController;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController();
    _locationController = TextEditingController();
    _budgetController = TextEditingController();

    _bioController.addListener(() {
      widget.onDataChanged({'bio': _bioController.text});
    });
    _locationController.addListener(() {
      widget.onDataChanged({'location': _locationController.text});
    });
    _budgetController.addListener(() {
      widget.onDataChanged({'budget': double.tryParse(_budgetController.text)});
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

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
            controller: _bioController,
            decoration: const InputDecoration(labelText: 'Your Bio', hintText: 'What are you passionate about? What makes you a great housemate?'),
            maxLines: 4,
            validator: (val) => (val == null || val.isEmpty) ? 'Please enter a bio' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'Preferred Location (e.g., City, State)'),
            validator: (val) => (val == null || val.isEmpty) ? 'Please enter a location' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _budgetController,
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
            value: _selectedGender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: <String>['Male', 'Female', 'Other']
                .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
            onChanged: (val) {
              setState(() => _selectedGender = val);
              widget.onDataChanged({'gender': val});
            },
            validator: (val) => (val == null) ? 'Please select a gender' : null,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (widget.formKey.currentState!.validate()) {
                  widget.onNext();
                }
              },
              child: const Text('Almost Done!'),
            ),
          ),
        ],
      ),
    );
  }
}