// lib/screens/swipe_screen.dart
import 'package:cohouse_match/models/filter_options.dart';
import 'package:cohouse_match/screens/filter_screen.dart';
import 'package:cohouse_match/widgets/card_skeleton_loader.dart';
import 'package:cohouse_match/widgets/empty_state_widget.dart';
import 'package:cohouse_match/widgets/multi_select_chip.dart';
import 'package:cohouse_match/widgets/static_map_widget.dart';
import 'package:flutter/material.dart';
import 'package:cohouse_match/models/user.dart';
import 'package:cohouse_match/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cohouse_match/services/gemini_service.dart';
import 'package:cohouse_match/services/api_keys.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:logging/logging.dart';

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
  final _log = Logger('SwipeScreen');

  // Holds the current filter state for the screen
  FilterOptions _activeFilters = FilterOptions.noFilters();

  // Holds the filter values for the filter dialog
  double? _minBudget;
  double? _maxBudget;
  String? _locationFilter;
  String? _selectedGender;
  int? _minAge;
  int? _maxAge;
  List<String> _selectedLifestyleDetails = [];
  List<String> _selectedPersonalityTags = [];

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

      _currentLoggedInUser = await DatabaseService(
        uid: currentUser.uid,
      ).userData.first;

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      List<UserData> allUsers = snapshot.docs
          .map(
            (doc) =>
                UserData.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();

      // Apply filters from the _activeFilters object
      List<UserData> filteredUsers = allUsers.where((user) {
        if (user.uid == currentUser.uid) return false;

        // Budget Filter
        if (_activeFilters.budgetRange != null) {
          if (user.budget == null ||
              user.budget! < _activeFilters.budgetRange!.start ||
              user.budget! > _activeFilters.budgetRange!.end) {
            return false;
          }
        }

        // Age Filter
        if (_activeFilters.ageRange != null) {
          if (user.age == null ||
              user.age! < _activeFilters.ageRange!.start ||
              user.age! > _activeFilters.ageRange!.end) {
            return false;
          }
        }

        // Location Filter
        if (_activeFilters.location != null &&
            _activeFilters.location!.isNotEmpty) {
          if (user.location == null ||
              !user.location!.toLowerCase().contains(
                _activeFilters.location!.toLowerCase(),
              )) {
            return false;
          }
        }

        // Gender Filter
        if (_activeFilters.gender != null &&
            user.gender != _activeFilters.gender) {
          return false;
        }

        // Tags Filters
        if (_activeFilters.lifestyleDetails.isNotEmpty &&
            !_activeFilters.lifestyleDetails.any(
              (item) => user.lifestyleDetails?.contains(item) ?? false,
            )) {
          return false;
        }
        if (_activeFilters.personalityTags.isNotEmpty &&
            !_activeFilters.personalityTags.any(
              (item) => user.personalityTags?.contains(item) ?? false,
            )) {
          return false;
        }

        return true;
      }).toList();

      setState(() {
        _usersToSwipe = filteredUsers;
      });
    } catch (e) {
      _log.severe('Error loading users', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading users: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Navigates to the FilterScreen and awaits the results.
  Future<void> _navigateToFilterScreen() async {
    final result = await Navigator.push<FilterOptions>(
      context,
      MaterialPageRoute(
        builder: (context) => FilterScreen(initialFilters: _activeFilters),
      ),
    );

    // If the user applied filters (didn't just back out), update the state and reload.
    if (result != null) {
      setState(() {
        _activeFilters = result;
      });
      _loadUsers();
    }
  }

  Future<bool> _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) async {
    final swipedUser = _usersToSwipe[previousIndex];

    if (direction == CardSwiperDirection.right) {
      await _handleMatch(swipedUser);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Passed on ${swipedUser.name}')));
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

      // Show enhanced match analysis dialog
      if (mounted) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            final score = matchResult['score'] ?? 0;
            final summary = matchResult['summary'] ?? 'No analysis available';
            final strengths = List<String>.from(matchResult['strengths'] ?? []);
            final concerns = List<String>.from(matchResult['concerns'] ?? []);
            final budgetMatch = matchResult['budgetMatch'] ?? 0;
            final lifestyleMatch = matchResult['lifestyleMatch'] ?? 0;
            final personalityMatch = matchResult['personalityMatch'] ?? 0;
            
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Matched with ${swipedUser.name}!')),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overall score
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getScoreColor(score).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getScoreColor(score)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$score%',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _getScoreColor(score),
                            ),
                          ),
                          Text(
                            'Compatibility Score',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            summary,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Category scores
                    Row(
                      children: [
                        Expanded(child: _buildScoreChip('Budget', budgetMatch)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildScoreChip('Lifestyle', lifestyleMatch)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildScoreChip('Personality', personalityMatch)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Strengths
                    if (strengths.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                          const SizedBox(width: 8),
                          const Text('Strengths', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...strengths.map((strength) => Padding(
                        padding: const EdgeInsets.only(left: 28, bottom: 4),
                        child: Text('• $strength'),
                      )),
                      const SizedBox(height: 12),
                    ],
                    
                    // Concerns
                    if (concerns.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
                          const SizedBox(width: 8),
                          const Text('Things to Consider', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...concerns.map((concern) => Padding(
                        padding: const EdgeInsets.only(left: 28, bottom: 4),
                        child: Text('• $concern'),
                      )),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Start Chatting'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    // TODO: Navigate to chat
                  },
                ),
                ElevatedButton(
                  child: const Text('Awesome!'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      _log.severe('Error processing match', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error processing match: $e')));
      }
    }
  }

  // Removed unused _nextUser method

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
                setState(() {
                  _activeFilters = FilterOptions(
                    budgetRange: _minBudget != null && _maxBudget != null
                        ? RangeValues(_minBudget!, _maxBudget!)
                        : null,
                    ageRange: _minAge != null && _maxAge != null
                        ? RangeValues(_minAge!.toDouble(), _maxAge!.toDouble())
                        : null,
                    location: _locationFilter,
                    gender: _selectedGender,
                    lifestyleDetails: _selectedLifestyleDetails,
                    personalityTags: _selectedPersonalityTags,
                  );
                });
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
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _navigateToFilterScreen,
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: _showCreateGroupMatchDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const CardSkeletonLoader()
          : _usersToSwipe.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.search_off_rounded,
              title: "No Users Found",
              subtitle:
                  "Try adjusting your search filters or check back later for new people!",
            )
          : Column(
              children: [
                Expanded(
                  child: CardSwiper(
                    controller: _swiperController,
                    cardsCount: _usersToSwipe.length,
                    onSwipe: _onSwipe,
                    padding: const EdgeInsets.all(24.0),
                    numberOfCardsDisplayed: _usersToSwipe.length < 2 ? 1 : 2,
                    cardBuilder:
                        (context, index, percentThresholdX, percentThresholdY) {
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
                        onPressed: () =>
                            _swiperController.swipe(CardSwiperDirection.left),
                        backgroundColor: Colors.white,
                        child: const Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                      FloatingActionButton(
                        heroTag: 'swipe_right_button',
                        onPressed: () =>
                            _swiperController.swipe(CardSwiperDirection.right),
                        backgroundColor: Colors.white,
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.green,
                          size: 30,
                        ),
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
                const SizedBox(height: 12),
                
                // Location map preview
                if (userData.coordinates != null) ...[
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: StaticMapWidget(
                        coordinates: userData.coordinates,
                        width: double.infinity,
                        height: 80,
                        zoom: 15,
                        showLocationIcon: false,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                
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
  
  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
  
  Widget _buildScoreChip(String label, int score) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: _getScoreColor(score).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getScoreColor(score).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$score%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getScoreColor(score),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
