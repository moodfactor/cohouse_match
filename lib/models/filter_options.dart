// lib/models/filter_options.dart

import 'package:flutter/material.dart';

class FilterOptions {
  RangeValues? budgetRange;
  RangeValues? ageRange;
  String? location;
  String? gender;
  List<String> lifestyleDetails;
  List<String> personalityTags;
  double? maxDistance; // Maximum distance in miles
  bool? showOnlineOnly; // Show only online users

  FilterOptions({
    this.budgetRange,
    this.ageRange,
    this.location,
    this.gender,
    required this.lifestyleDetails,
    required this.personalityTags,
    this.maxDistance,
    this.showOnlineOnly,
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
      maxDistance: 25.0, // Default 25 miles
      showOnlineOnly: false,
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
      maxDistance: null,
      showOnlineOnly: false,
    );
  }
}