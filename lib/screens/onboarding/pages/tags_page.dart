import 'package:cohouse_match/widgets/multi_select_chip.dart';
import 'package:flutter/material.dart';

class TagsPage extends StatelessWidget {
  final VoidCallback onFinish;
  final Function(List<String>) onPersonalityTagsChanged;
  final Function(List<String>) onLifestyleDetailsChanged;

  const TagsPage({
    super.key,
    required this.onFinish,
    required this.onPersonalityTagsChanged,
    required this.onLifestyleDetailsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          const Text(
            "What describes you best?",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          const Text('Personality Tags:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          MultiSelectChip(
            ['Introvert', 'Extrovert', 'Thinker', 'Feeler', 'Organized', 'Spontaneous'],
            onSelectionChanged: onPersonalityTagsChanged,
          ),
          const SizedBox(height: 30),
          const Text('Lifestyle Details:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          MultiSelectChip(
            ['Pet-friendly', 'Night Owl', 'Early Bird', 'Vegetarian', 'Vegan', 'Remote Worker', 'Student'],
            onSelectionChanged: onLifestyleDetailsChanged,
          ),
          const SizedBox(height: 50),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: onFinish,
              child: const Text('Complete Profile & Start Matching!'),
            ),
          ),
        ],
      ),
    );
  }
}