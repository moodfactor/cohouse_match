// lib/screens/onboarding/onboarding_screen.dart
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

  // This map will hold the user's data as they fill it out
  final Map<String, dynamic> _userData = {};

  void _nextPage() {
    // Validate current page before proceeding
    if (_currentPage == 0) { // Welcome page
      if (!_formKey.currentState!.validate()) return;
      _formKey.currentState!.save();
    } else if (_currentPage == 2) { // Details page
      if (!_formKey.currentState!.validate()) return;
      _formKey.currentState!.save();
    }

    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    // Validate all forms before final submission
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    // Validate required fields
    if (!_userData.containsKey('name') || _userData['name'] == null) {
      _showErrorSnackbar('Please enter your name');
      return;
    }
    if (!_userData.containsKey('age') || _userData['age'] == null) {
      _showErrorSnackbar('Please enter your age');
      return;
    }
    if (!_userData.containsKey('photoUrl') || _userData['photoUrl'] == null) {
      _showErrorSnackbar('Please upload a profile photo');
      return;
    }
    if (!_userData.containsKey('bio') || _userData['bio'] == null) {
      _showErrorSnackbar('Please tell us about yourself');
      return;
    }
    if (!_userData.containsKey('location') || _userData['location'] == null) {
      _showErrorSnackbar('Please enter your location');
      return;
    }
    if (!_userData.containsKey('budget') || _userData['budget'] == null) {
      _showErrorSnackbar('Please enter your budget');
      return;
    }
    if (!_userData.containsKey('personalityTags') ||
        _userData['personalityTags'] == null ||
        _userData['personalityTags'].isEmpty) {
      _showErrorSnackbar('Please select at least one personality tag');
      return;
    }
    if (!_userData.containsKey('lifestyleDetails') ||
        _userData['lifestyleDetails'] == null ||
        _userData['lifestyleDetails'].isEmpty) {
      _showErrorSnackbar('Please select at least one lifestyle detail');
      return;
    }

    try {
      await DatabaseService(uid: widget.firebaseUser.uid).updateUserData(
        widget.firebaseUser.email!,
        _userData['name'],
        _userData['bio'],
        _userData['photoUrl'],
        List<String>.from(_userData['personalityTags']),
        List<String>.from(_userData['lifestyleDetails']),
        _userData['budget'] is int ? (_userData['budget'] as int).toDouble() : _userData['budget'],
        _userData['location'],
        _userData['gender'],
        _userData['age'],
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
        onNext: _nextPage,
        onDataChanged: (data) => _userData.addAll(data),
        formKey: _formKey
      ),
      PhotoPage(
        onNext: _nextPage,
        onDataChanged: (data) => _userData.addAll(data)
      ),
      DetailsPage(
        onNext: _nextPage,
        onDataChanged: (data) => _userData.addAll(data),
        formKey: _formKey
      ),
      TagsPage(
        onFinish: _finishOnboarding,
        onDataChanged: (data) => _userData.addAll(data)
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