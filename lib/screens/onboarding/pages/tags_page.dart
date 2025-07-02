import 'package:cohouse_match/widgets/multi_select_chip.dart';
import 'package:flutter/material.dart';

class TagsPage extends StatefulWidget {
  final VoidCallback onFinish;
  final Function(Map<String, dynamic>) onDataChanged;

  const TagsPage({super.key, required this.onFinish, required this.onDataChanged});

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  List<String> _personalityTags = [];
  List<String> _lifestyleDetails = [];
  final _formKey = GlobalKey<FormState>();

  bool _validateSelections() {
    if (_personalityTags.isEmpty || _lifestyleDetails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one option from each category')),
      );
      return false;
    }
    return true;
  }

  void _submitData() {
    if (_validateSelections()) {
      widget.onDataChanged({
        'personalityTags': _personalityTags,
        'lifestyleDetails': _lifestyleDetails
      });
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const Text(
              "What describes you best?",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const Text('Personality Tags:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Select at least one', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            MultiSelectChip(
              ['Introvert', 'Extrovert', 'Thinker', 'Feeler', 'Organized', 'Spontaneous'],
              initialSelection: _personalityTags,
              onSelectionChanged: (selectedList) {
                setState(() => _personalityTags = selectedList);
              },
            ),
            const SizedBox(height: 30),
            const Text('Lifestyle Details:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Select at least one', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            MultiSelectChip(
              ['Pet-friendly', 'Night Owl', 'Early Bird', 'Vegetarian', 'Vegan', 'Remote Worker', 'Student'],
              initialSelection: _lifestyleDetails,
              onSelectionChanged: (selectedList) {
                setState(() => _lifestyleDetails = selectedList);
              },
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _submitData,
                child: const Text('Complete Profile & Start Matching!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}