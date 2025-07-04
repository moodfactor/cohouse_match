// lib/models/filter_options.dart

import 'package:flutter/material.dart';

class FilterOptions {
  RangeValues? budgetRange;
  RangeValues? ageRange;
  String? location;
  String? gender;
  List<String> lifestyleDetails;
  List<String> personalityTags;

  FilterOptions({
    this.budgetRange,
    this.ageRange,
    this.location,
    this.gender,
    required this.lifestyleDetails,
    required this.personalityTags,
  });

  // A factory method to create default options
  factory FilterOptions.defaultValues() {
    return FilterOptions(
      budgetRange: const RangeValues(500, 3000),
      ageRange: const RangeValues(18, 60),
      location: '',
      gender: null,
      lifestyleDetails: [],
      personalityTags: [],
    );
  }

  // A factory method for no filters
  factory FilterOptions.noFilters() {
    return FilterOptions(
      budgetRange: null,
      ageRange: null,
      location: null,
      gender: null,
      lifestyleDetails: [],
      personalityTags: [],
    );
  }
}