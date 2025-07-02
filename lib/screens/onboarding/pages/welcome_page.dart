import 'package:flutter/material.dart';

class WelcomePage extends StatefulWidget {
  final VoidCallback onNext;
  final Function(Map<String, dynamic>) onDataChanged;
  final GlobalKey<FormState> formKey;

  const WelcomePage({super.key, required this.onNext, required this.onDataChanged, required this.formKey});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();

    _nameController.addListener(() {
      widget.onDataChanged({'name': _nameController.text});
    });
    _ageController.addListener(() {
      widget.onDataChanged({'age': int.tryParse(_ageController.text)});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Welcome to CohouseMatch!",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Let's start with the basics to build your profile.",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const Spacer(),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Your Name'),
            validator: (val) => val!.isEmpty ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _ageController,
            decoration: const InputDecoration(labelText: 'Your Age'),
            keyboardType: TextInputType.number,
            validator: (val) => val!.isEmpty ? 'Please enter your age' : null,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (widget.formKey.currentState!.validate()) {
                  // No need to call save() anymore as data is collected via controllers
                  widget.onNext();
                }
              },
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }
}