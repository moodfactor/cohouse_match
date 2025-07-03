// lib/screens/swipe_screen.dart
import 'package:cohouse_match/widgets/card_skeleton_loader.dart';
import 'package:cohouse_match/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:cohouse_match/models/user.dart';
import 'package:cohouse_match/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cohouse_match/services/gemini_service.dart';
import 'package:cohouse_match/services/api_keys.dart'; // Make sure you have this file
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cohouse_match/widgets/multi_select_chip.dart'; // Keep for filter dialog

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
 List<UserData> _usersToSwipe = [];
  final CardSwiperController _swiperController = CardSwiperController();
  final GeminiService _geminiService = GeminiService(apiKey: geminiApiKey);
  UserData? _currentLoggedInUser;
  bool _isLoading = true;

  int _currentIndex = 0; // Track the current index for swiping
  

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
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      _currentLoggedInUser = await DatabaseService(uid: currentUser.uid).userData.first;

      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').get();
      List<UserData> allUsers = snapshot.docs.map((doc) => UserData.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

      List<UserData> filteredUsers = allUsers.where((user) {
        if (user.uid == currentUser.uid) return false;
        if (_minBudget != null && user.budget != null && user.budget! < _minBudget!) return false;
        if (_maxBudget != null && user.budget != null && user.budget! > _maxBudget!) return false;
        if (_locationFilter != null && _locationFilter!.isNotEmpty && user.location != _locationFilter) return false;
        if (_selectedLifestyleDetails.isNotEmpty && !_selectedLifestyleDetails.any((item) => user.lifestyleDetails?.contains(item) ?? false)) return false;
        if (_selectedPersonalityTags.isNotEmpty && !_selectedPersonalityTags.any((item) => user.personalityTags?.contains(item) ?? false)) return false;
        if (_selectedGender != null && user.gender != _selectedGender) return false;
        if (_minAge != null && user.age != null && user.age! < _minAge!) return false;
        if (_maxAge != null && user.age != null && user.age! > _maxAge!) return false;
        return true;
      }).toList();

      setState(() {
        _usersToSwipe = filteredUsers;
      });
    } catch (e) {
      print('Error loading users: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading users: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) async {
    final swipedUser = _usersToSwipe[previousIndex];

    if (direction == CardSwiperDirection.right) {
      await _handleMatch(swipedUser);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Passed on ${swipedUser.name}')));
      }
    }
    return true;
  }

  Future<void> _handleMatch(UserData swipedUser) async {
    final currentUser = Provider.of<User?>(context, listen: false);
    if (currentUser == null || _currentLoggedInUser == null) return;

    // Show a loading indicator while processing match
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Matching with ${swipedUser.name}...')),
      );
    }

    try {
      // Create a match in Firestore
      await DatabaseService().createMatch(currentUser.uid, swipedUser.uid);

      // Get match score from Gemini
      final matchResult = await _geminiService.getMatchScore(
        _currentLoggedInUser!,
        swipedUser,
      );

      // Handle potential null or invalid response
      if (matchResult == null) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Match Result'),
                content: const Text('Could not get match score from Gemini.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            },
          );
        }
        return;
      }

      // Show match score and explanation in an AlertDialog
      if (mounted) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('You Matched with ${swipedUser.name}!'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Gemini's Compatibility Analysis:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text('Score: ${matchResult['score'] ?? 'N/A'} / 100'),
                    const SizedBox(height: 10),
                    Text(
                      matchResult['explanation'] ??
                          'Could not get match explanation.',
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Awesome!'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error processing match: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error processing match: $e')));
      }
    }
  }

  void _nextUser() {
    setState(() {
      if (_usersToSwipe.isEmpty) return;

      if (_currentIndex < _usersToSwipe.length - 1) {
        _currentIndex++;
      } else {
        // No more users to swipe, show message and reload
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No more users to swipe. Adjust your filters or try again later.',
              ),
            ),
          );
        }
        _loadUsers(); // Try to load more users
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
                    const SnackBar(
                      content: Text(
                        'Select at least two members for a group match.',
                      ),
                    ),
                  );
                  return;
                }

                List<String> groupMembersUids = selectedUsers
                    .map((user) => user.uid)
                    .toList();
                groupMembersUids.add(
                  currentUser.uid,
                ); // Add current user to the group

                // Create a group match
                await DatabaseService().createMatch(
                  currentUser.uid,
                  selectedUsers[0].uid,
                  groupMembers: groupMembersUids,
                );

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
                      })
                      .toList(),
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
                    'Student',
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
                    'Spontaneous',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('CohouseMatch'),
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterDialog),
          IconButton(icon: const Icon(Icons.group_add), onPressed: _showCreateGroupMatchDialog),
        ],
      ),
      body: _isLoading
          ? const CardSkeletonLoader()
          : _usersToSwipe.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.search_off_rounded,
                  title: "No Users Found",
                  subtitle: "Try adjusting your search filters or check back later for new people!",
                )
              : Column(
                  children: [
                    Expanded(
                      child: CardSwiper(
                        controller: _swiperController,
                        cardsCount: _usersToSwipe.length,
                        onSwipe: _onSwipe,
                        padding: const EdgeInsets.all(24.0),
                        cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                          // **** FIX 1: Corrected typo here ****
                          final user = _usersToSwipe[index]; 
                          return _buildUserCard(user);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40.0, top: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FloatingActionButton(
                            heroTag: 'swipe_left_button',
                            // **** FIX 2: Corrected controller method ****
                            onPressed: () => _swiperController.swipe(CardSwiperDirection.left),
                            backgroundColor: Colors.white,
                            child: const Icon(Icons.close, color: Colors.red, size: 30),
                          ),
                          FloatingActionButton(
                            heroTag: 'swipe_right_button',
                            // **** FIX 3: Corrected controller method ****
                            onPressed: () => _swiperController.swipe(CardSwiperDirection.right),
                            backgroundColor: Colors.white,
                            child: const Icon(Icons.favorite, color: Colors.green, size: 30),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildUserCard(UserData userData) {
    // Handle potential null values
    final name = userData.name ?? 'Unknown';
    final age = userData.age?.toString() ?? '';
    final bio = userData.bio;
    final location = userData.location;
    final budget = userData.budget;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.hardEdge, // This is important to contain the image
      child: Stack(
        children: [
          // Background Image
          if (userData.photoUrl != null && userData.photoUrl!.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                userData.photoUrl!,
                fit: BoxFit.cover,
                // Loading and error builders for a better UX
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.person, size: 150, color: Colors.grey),
              ),
            )
          else
            const Center(
              child: Icon(Icons.person, size: 150, color: Colors.grey),
            ),

          // Gradient overlay for text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),

          // User Info
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name, $age',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                if (bio != null && bio.isNotEmpty)
                  Text(
                    bio,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6.0,
                  runSpacing: 6.0,
                  children: [
                    if (location != null)
                      _buildInfoChip(Icons.location_on, location),
                    if (budget != null)
                      _buildInfoChip(
                        Icons.attach_money,
                        '\$${budget.toStringAsFixed(0)}/mo',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
