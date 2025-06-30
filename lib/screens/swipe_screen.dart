import 'package:cohouse_match/widgets/multi_select_chip.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cohouse_match/models/user.dart';
import 'package:cohouse_match/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cohouse_match/services/gemini_service.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  List<UserData> _usersToSwipe = [];
  int _currentIndex = 0;
  final GeminiService _geminiService = GeminiService(apiKey: 'YOUR_GEMINI_API_KEY'); // Replace with your actual API key
  UserData? _currentLoggedInUser;

  // Filter parameters
  double? _minBudget;
  double? _maxBudget;
  String? _locationFilter;
  List<String> _selectedLifestyleDetails = [];
  List<String> _selectedPersonalityTags = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final currentUser = Provider.of<User?>(context, listen: false);
    if (currentUser == null) return;

    // Fetch current logged-in user's data
    _currentLoggedInUser = await DatabaseService(uid: currentUser.uid).userData.first;

    Query query = FirebaseFirestore.instance.collection('users');

    // Apply filters
    if (_minBudget != null) {
      query = query.where('budget', isGreaterThanOrEqualTo: _minBudget);
    }
    if (_maxBudget != null) {
      query = query.where('budget', isLessThanOrEqualTo: _maxBudget);
    }
    if (_selectedLifestyleDetails.isNotEmpty) {
      query = query.where('lifestyleDetails', arrayContainsAny: _selectedLifestyleDetails);
    }
    if (_selectedPersonalityTags.isNotEmpty) {
      query = query.where('personalityTags', arrayContainsAny: _selectedPersonalityTags);
    }
    if (_locationFilter != null && _locationFilter!.isNotEmpty) {
      query = query.where('location', isEqualTo: _locationFilter);
    }

    QuerySnapshot snapshot = await query
        .where('uid', isNotEqualTo: currentUser.uid)
        .get();

    setState(() {
      _usersToSwipe = snapshot.docs
          .map((doc) => UserData.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      _currentIndex = 0; // Reset index when users are reloaded
    });
  }

  void _onSwipeLeft() {
    // Handle pass
    _nextUser();
  }

  void _onSwipeRight() async {
    final currentUser = Provider.of<User?>(context, listen: false);
    if (currentUser == null || _currentLoggedInUser == null) return;

    final swipedUser = _usersToSwipe[_currentIndex];

    // Create a match
    await DatabaseService().createMatch(currentUser.uid, swipedUser.uid);

    // Get match score from Gemini
    final matchScore = await _geminiService.getMatchScore(_currentLoggedInUser!, swipedUser);

    // Show match score in an AlertDialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Match Result'),
          content: Text(matchScore ?? 'Could not get match score.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    _nextUser();
  }

  void _nextUser() {
    setState(() {
      if (_currentIndex < _usersToSwipe.length - 1) {
        _currentIndex++;
      } else {
        // No more users to swipe, maybe show a message or load more
        print('No more users to swipe.');
      }
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Users'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextField(
                  decoration: const InputDecoration(labelText: 'Min Budget'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    _minBudget = double.tryParse(val);
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Max Budget'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    _maxBudget = double.tryParse(val);
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Location'),
                  onChanged: (val) {
                    _locationFilter = val;
                  },
                ),
                const SizedBox(height: 20),
                const Text('Lifestyle Details:'),
                MultiSelectChip(
                  ['Pet-friendly', 'Night Owl', 'Early Bird', 'Vegetarian', 'Vegan', 'Remote Worker', 'Student'],
                  initialSelection: _selectedLifestyleDetails,
                  onSelectionChanged: (selectedList) {
                    _selectedLifestyleDetails = selectedList;
                  },
                ),
                const SizedBox(height: 20),
                const Text('Personality Tags:'),
                MultiSelectChip(
                  ['Introvert', 'Extrovert', 'Thinker', 'Feeler', 'Organized', 'Spontaneous'],
                  initialSelection: _selectedPersonalityTags,
                  onSelectionChanged: (selectedList) {
                    _selectedPersonalityTags = selectedList;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Apply'),
              onPressed: () {
                _loadUsers(); // Reload users with new filters
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_usersToSwipe.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final UserData currentUserData = _usersToSwipe[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CohouseMatch'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Card(
            margin: const EdgeInsets.all(20.0),
            elevation: 5.0,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: Text(
                          currentUserData.name ?? 'No Name',
                          style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      currentUserData.bio ?? 'No bio available.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              FloatingActionButton(
                onPressed: _onSwipeLeft,
                backgroundColor: Colors.red,
                child: const Icon(Icons.close),
              ),
              FloatingActionButton(
                onPressed: _onSwipeRight,
                backgroundColor: Colors.green,
                child: const Icon(Icons.check),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

  