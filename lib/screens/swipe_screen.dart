import 'package:cohouse_match/services/api_keys.dart';
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
  final GeminiService _geminiService = GeminiService(apiKey: geminiApiKey);
  UserData? _currentLoggedInUser;
  bool _isLoading = true;

  // Filter parameters
  double? _minBudget;
  double? _maxBudget;
  String? _locationFilter;
  List<String> _selectedLifestyleDetails = [];
  List<String> _selectedPersonalityTags = [];
  String? _selectedGender;
  int? _minAge;
  int? _maxAge;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = Provider.of<User?>(context, listen: false);
      if (currentUser == null) {
        return;
      }

      _currentLoggedInUser =
          await DatabaseService(uid: currentUser.uid).userData.first;

      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      List<UserData> allUsers = snapshot.docs
          .map((doc) =>
              UserData.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Client-side filtering
      List<UserData> filteredUsers = allUsers.where((user) {
        if (user.uid == currentUser.uid) {
          return false;
        }
        if (_minBudget != null && user.budget != null && user.budget! < _minBudget!) {
          return false;
        }
        if (_maxBudget != null && user.budget != null && user.budget! > _maxBudget!) {
          return false;
        }
        if (_locationFilter != null &&
            _locationFilter!.isNotEmpty &&
            user.location != _locationFilter) {
          return false;
        }
        if (_selectedLifestyleDetails.isNotEmpty &&
            !_selectedLifestyleDetails
                .any((item) => user.lifestyleDetails?.contains(item) ?? false)) {
          return false;
        }
        if (_selectedPersonalityTags.isNotEmpty &&
            !_selectedPersonalityTags
                .any((item) => user.personalityTags?.contains(item) ?? false)) {
          return false;
        }
        if (_selectedGender != null && user.gender != _selectedGender) {
          return false;
        }
        if (_minAge != null && user.age != null && user.age! < _minAge!) {
          return false;
        }
        if (_maxAge != null && user.age != null && user.age! > _maxAge!) {
          return false;
        }
        return true;
      }).toList();

      setState(() {
        _usersToSwipe = filteredUsers;
        _currentIndex = 0;
      });
    } catch (e) {
      print('Error loading users: $e');
      // Optionally, show an error message to the user
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
    final matchResult =
        await _geminiService.getMatchScore(_currentLoggedInUser!, swipedUser);

    // Show match score and explanation in an AlertDialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Match Result'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Score: ${matchResult?['score'] ?? 'N/A'}'),
                const SizedBox(height: 10),
                Text(matchResult?['explanation'] ?? 'Could not get match explanation.'),
              ],
            ),
          ),
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

  void _showCreateGroupMatchDialog() {
    final currentUser = Provider.of<User?>(context, listen: false);
    if (currentUser == null) return;

    List<UserData> selectedUsers = [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Group Match'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const Text('Select members for the group match:'),
                // Display users to select for group match
                // For simplicity, using a basic list with checkboxes.
                // A more robust solution would involve a dedicated multi-select widget.
                ..._usersToSwipe.map((user) {
                  return CheckboxListTile(
                    title: Text(user.name ?? 'No Name'),
                    value: selectedUsers.contains(user),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedUsers.add(user);
                        } else {
                          selectedUsers.remove(user);
                        }
                      });
                    },
                  );
                }),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Create'),
              onPressed: () async {
                if (selectedUsers.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select at least two members for a group match.')),
                  );
                  return;
                }

                List<String> groupMembersUids = selectedUsers.map((user) => user.uid).toList();
                groupMembersUids.add(currentUser.uid); // Add current user to the group

                // Create a group match
                await DatabaseService().createMatch(currentUser.uid, selectedUsers[0].uid, groupMembers: groupMembersUids);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group Match Created!')),
                );
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
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: <String>['Male', 'Female', 'Other']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGender = newValue;
                    });
                  },
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: const InputDecoration(labelText: 'Min Age'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    _minAge = int.tryParse(val);
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Max Age'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    _maxAge = int.tryParse(val);
                  },
                ),
                const SizedBox(height: 20),
                const Text('Lifestyle Details:'),
                MultiSelectChip(
                  [
                    'Pet-friendly',
                    'Night Owl',
                    'Early Bird',
                    'Vegetarian',
                    'Vegan',
                    'Remote Worker',
                    'Student'
                  ],
                  initialSelection: _selectedLifestyleDetails,
                  onSelectionChanged: (selectedList) {
                    _selectedLifestyleDetails = selectedList;
                  },
                ),
                const SizedBox(height: 20),
                const Text('Personality Tags:'),
                MultiSelectChip(
                  [
                    'Introvert',
                    'Extrovert',
                    'Thinker',
                    'Feeler',
                    'Organized',
                    'Spontaneous'
                  ],
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_usersToSwipe.isEmpty) {
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
        body: const Center(
          child: Text('No users found matching your criteria.'),
        ),
      );
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
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: _showCreateGroupMatchDialog,
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
                        child: (currentUserData.photoUrl != null &&
                                currentUserData.photoUrl!.isNotEmpty &&
                                currentUserData.photoUrl! != 'https://example.com/bob.jpg')
                            ? Image.network(
                                currentUserData.photoUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : Icon(
                                Icons.person, // Placeholder icon
                                size: 100.0,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUserData.name ?? 'No Name',
                          style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          currentUserData.bio ?? 'No bio available.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16.0),
                        ),
                        const SizedBox(height: 8.0),
                        if (currentUserData.location != null && currentUserData.location!.isNotEmpty)
                          Text('Location: ${currentUserData.location}'),
                        if (currentUserData.budget != null)
                          Text('Budget: \${currentUserData.budget?.toStringAsFixed(0)}'),
                        if (currentUserData.personalityTags != null && currentUserData.personalityTags!.isNotEmpty)
                          Text('Personality: ${currentUserData.personalityTags!.join(', ')}'),
                        if (currentUserData.lifestyleDetails != null && currentUserData.lifestyleDetails!.isNotEmpty)
                          Text('Lifestyle: ${currentUserData.lifestyleDetails!.join(', ')}'),
                      ],
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


  