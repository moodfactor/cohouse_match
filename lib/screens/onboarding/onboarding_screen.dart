import 'package:cohouse_match/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cohouse_match/screens/onboarding/pages/welcome_page.dart';
import 'package:cohouse_match/screens/onboarding/pages/photo_page.dart';
import 'package:cohouse_match/screens/onboarding/pages/details_page.dart';
import 'package:cohouse_match/screens/onboarding/pages/tags_page.dart';

class OnboardingScreen extends StatefulWidget {
  final User firebaseUser;
  
  const OnboardingScreen({
    super.key,
    required this.firebaseUser,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  int _currentPage = 0;

  // Controllers for WelcomePage
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  // Controllers for DetailsPage
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  String? _selectedGender;
  GeoPoint? _locationCoordinates;

  // Data for PhotoPage and TagsPage
  String? _photoUrl;
  List<String> _personalityTags = [];
  List<String> _lifestyleDetails = [];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_formKey.currentState!.validate()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Collect all data directly from controllers and state variables
    final String trimmedName = _nameController.text.trim();
    final String? name = trimmedName.isEmpty ? null : trimmedName;
    final int? age = int.tryParse(_ageController.text.trim());
    final String? bio = _bioController.text.trim().isEmpty ? null : _bioController.text.trim();
    final String? location = _locationController.text.trim().isEmpty ? null : _locationController.text.trim();
    final double? budget = double.tryParse(_budgetController.text.trim());

    // Validate required fields before saving
    if (_photoUrl == null) {
      _showErrorSnackbar('Please upload a profile photo');
      return;
    }
    if (_locationCoordinates == null) {
      _showErrorSnackbar('Please set your location on the map');
      return;
    }
    if (_personalityTags.isEmpty) {
      _showErrorSnackbar('Please select at least one personality tag');
      return;
    }
    if (_lifestyleDetails.isEmpty) {
      _showErrorSnackbar('Please select at least one lifestyle detail');
      return;
    }

    try {
      await DatabaseService(uid: widget.firebaseUser.uid).updateUserData(
        email: widget.firebaseUser.email!,
        name: name,
        bio: bio,
        photoUrl: _photoUrl,
        personalityTags: _personalityTags,
        lifestyleDetails: _lifestyleDetails,
        budget: budget,
        location: location,
        coordinates: _locationCoordinates,
        gender: _selectedGender,
        age: age,
      );
      // The Wrapper will automatically detect the completed profile and navigate to HomeWrapper
    } catch (e) {
      _showErrorSnackbar('Error saving profile: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      WelcomePage(
        nameController: _nameController,
        ageController: _ageController,
        onNext: _nextPage,
      ),
      PhotoPage(
        onNext: _nextPage,
        onDataChanged: (data) => setState(() => _photoUrl = data['photoUrl']),
      ),
      DetailsPage(
        bioController: _bioController,
        locationController: _locationController,
        budgetController: _budgetController,
        onGenderChanged: (gender) => setState(() => _selectedGender = gender),
        onLocationSelected: (address, coordinates) {
          setState(() {
            _locationController.text = address;
            _locationCoordinates = coordinates;
          });
        },
        onNext: _nextPage,
      ),
      TagsPage(
        onFinish: _finishOnboarding,
        onPersonalityTagsChanged: (tags) => setState(() => _personalityTags = tags),
        onLifestyleDetailsChanged: (details) => setState(() => _lifestyleDetails = details),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Progress Indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Step ${_currentPage + 1} of ${pages.length}',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Disable swiping
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: pages,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}