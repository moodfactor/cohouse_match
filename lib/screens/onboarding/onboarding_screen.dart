import 'package:cohouse_match/models/user.dart';
import 'package:cohouse_match/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final String? name = _nameController.text.trim().isEmpty ? null : _nameController.text.trim();
    final int? age = int.tryParse(_ageController.text.trim());
    final String? bio = _bioController.text.trim().isEmpty ? null : _bioController.text.trim();
    final String? location = _locationController.text.trim().isEmpty ? null : _locationController.text.trim();
    final double? budget = double.tryParse(_budgetController.text.trim());

    // Validate required fields before saving
    if (name == null) {
      _showErrorSnackbar('Please enter your name');
      return;
    }
    if (age == null || age <= 0) {
      _showErrorSnackbar('Please enter a valid age');
      return;
    }
    if (_photoUrl == null) {
      _showErrorSnackbar('Please upload a profile photo');
      return;
    }
    if (bio == null) {
      _showErrorSnackbar('Please tell us about yourself');
      return;
    }
    if (location == null) {
      _showErrorSnackbar('Please enter your location');
      return;
    }
    if (budget == null || budget <= 0) {
      _showErrorSnackbar('Please enter a valid budget');
      return;
    }
    if (_selectedGender == null) {
      _showErrorSnackbar('Please select your gender');
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
        widget.firebaseUser.email!,
        name,
        bio,
        _photoUrl,
        _personalityTags,
        _lifestyleDetails,
        budget,
        location,
        _selectedGender,
        age,
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