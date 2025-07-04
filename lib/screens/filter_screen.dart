// lib/screens/filter_screen.dart
import 'package:cohouse_match/models/filter_options.dart';
import 'package:cohouse_match/widgets/multi_select_chip.dart';
import 'package:flutter/material.dart';

class FilterScreen extends StatefulWidget {
  final FilterOptions initialFilters;

  const FilterScreen({
    super.key,
    required this.initialFilters,
  });

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late FilterOptions _currentFilters;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    // Use a copy of the initial filters to allow for local changes
    _currentFilters = widget.initialFilters;
    _locationController = TextEditingController(text: _currentFilters.location);
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _currentFilters = FilterOptions.defaultValues();
      _locationController.text = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters'),
        actions: [
          TextButton(
            onPressed: _clearFilters,
            child: const Text('Clear'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildRangeSlider(
            title: 'Budget Range',
            range: _currentFilters.budgetRange ?? const RangeValues(500, 3000),
            min: 100,
            max: 5000,
            divisions: 49,
            labelBuilder: (value) => '\$${value.round()}',
            onChanged: (values) {
              setState(() {
                _currentFilters.budgetRange = values;
              });
            },
          ),
          const SizedBox(height: 30),
          _buildRangeSlider(
            title: 'Age Range',
            range: _currentFilters.ageRange ?? const RangeValues(18, 60),
            min: 18,
            max: 80,
            divisions: 62,
            labelBuilder: (value) => '${value.round()}',
            onChanged: (values) {
              setState(() {
                _currentFilters.ageRange = values;
              });
            },
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _currentFilters.location = value;
            },
          ),
          const SizedBox(height: 30),
          DropdownButtonFormField<String>(
            value: _currentFilters.gender,
            decoration: const InputDecoration(
              labelText: 'Gender',
              border: OutlineInputBorder(),
            ),
            items: <String>['Male', 'Female', 'Other']
                .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
            onChanged: (String? newValue) {
              setState(() {
                _currentFilters.gender = newValue;
              });
            },
          ),
          const SizedBox(height: 30),
          const Text('Lifestyle Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          MultiSelectChip(
            ['Pet-friendly', 'Night Owl', 'Early Bird', 'Vegetarian', 'Vegan', 'Remote Worker', 'Student'],
            initialSelection: _currentFilters.lifestyleDetails,
            onSelectionChanged: (selectedList) {
              _currentFilters.lifestyleDetails = selectedList;
            },
          ),
          const SizedBox(height: 30),
          const Text('Personality Tags', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          MultiSelectChip(
            ['Introvert', 'Extrovert', 'Thinker', 'Feeler', 'Organized', 'Spontaneous'],
            initialSelection: _currentFilters.personalityTags,
            onSelectionChanged: (selectedList) {
              _currentFilters.personalityTags = selectedList;
            },
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Apply Filters'),
            onPressed: () {
              // Pop the screen and return the selected filters
              Navigator.of(context).pop(_currentFilters);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSlider({
    required String title,
    required RangeValues range,
    required double min,
    required double max,
    required int divisions,
    required String Function(double) labelBuilder,
    required Function(RangeValues) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        RangeSlider(
          values: range,
          min: min,
          max: max,
          divisions: divisions,
          labels: RangeLabels(
            labelBuilder(range.start),
            labelBuilder(range.end),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}