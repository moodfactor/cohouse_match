import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  final TextEditingController nameController;
  final TextEditingController ageController;

  const WelcomePage({
    super.key,
    required this.onNext,
    required this.nameController,
    required this.ageController,
  });

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
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Your Name'),
            validator: (val) => val!.isEmpty ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: ageController,
            decoration: const InputDecoration(labelText: 'Your Age'),
            keyboardType: TextInputType.number,
            validator: (val) => val!.isEmpty ? 'Please enter your age' : null,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }
}