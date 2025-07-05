import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cohouse_match/models/review.dart';
import 'package:cohouse_match/models/user.dart';
import 'package:cohouse_match/services/database_service.dart';
import 'package:cohouse_match/services/location_service.dart';
import 'package:cohouse_match/widgets/static_map_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewProfileScreen extends StatefulWidget {
  final String userId;
  const ViewProfileScreen({super.key, required this.userId});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  final DatabaseService _db = DatabaseService();

  // State for the 'Add Review' dialog
  double _currentRating = 3.0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the current logged-in user to pass their details for review authoring
    final currentUser = Provider.of<User?>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<UserData?>(
        stream: _db.userDataFromUid(widget.userId),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData) {
            return const Center(child: Text("User not found."));
          }
          final user = userSnapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(0),
            children: [
              _buildProfileHeader(user),
              const SizedBox(height: 20),
              _buildInfoSection(user),
              const SizedBox(height: 20),
              _buildLocationSection(user),
              const Divider(height: 40, thickness: 1, indent: 20, endIndent: 20),
              _buildReviewsSection(widget.userId),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // You shouldn't be able to review yourself
          if (currentUser?.uid == widget.userId) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("You cannot write a review for yourself.")),
            );
            return;
          }
          _showAddReviewDialog(context, currentUser);
        },
        icon: const Icon(Icons.rate_review),
        label: const Text('Add Review'),
      ),
    );
  }

  Widget _buildProfileHeader(UserData user) {
    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                ? NetworkImage(user.photoUrl!)
                : null,
            child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                ? const Icon(Icons.person, size: 60, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            '${user.name ?? "User"}, ${user.age ?? ""}',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (user.location != null)
            Text(
              user.location!,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          const SizedBox(height: 12),
          if (user.bio != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                user.bio!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(UserData user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoTile(Icons.attach_money, 'Budget', '\$${user.budget?.toStringAsFixed(0) ?? 'N/A'} / month'),
          const SizedBox(height: 20),
          _buildTagsSection('Personality', user.personalityTags),
          const SizedBox(height: 20),
          _buildTagsSection('Lifestyle', user.lifestyleDetails),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 30),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            Text(subtitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        )
      ],
    );
  }

  Widget _buildTagsSection(String title, List<String>? tags) {
    if (tags == null || tags.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: tags.map((tag) => Chip(
            label: Text(tag),
            backgroundColor: Colors.blue.shade50,
            labelStyle: TextStyle(color: Colors.blue.shade800),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationSection(UserData user) {
    final displayLocation = LocationService.getDisplayLocation(user);
    if (displayLocation == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          StaticMapWidget(
            coordinates: displayLocation,
            width: double.infinity,
            height: 200,
            zoom: 13,
            borderRadius: BorderRadius.circular(12),
          ),
          if (user.location != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    user.location!,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsSection(String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text('Reviews', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<Review>>(
          stream: _db.getReviews(userId),
          builder: (context, reviewSnapshot) {
            if (reviewSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!reviewSnapshot.hasData || reviewSnapshot.data!.isEmpty) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("No reviews yet."),
              ));
            }
            final reviews = reviewSnapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (context, index) => _buildReviewTile(reviews[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewTile(Review review) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(review.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                ],
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(review.content),
        ],
      ),
    );
  }

  void _showAddReviewDialog(BuildContext context, User? currentUser) {
    // We need the logged-in user's data to know their name
    final dbService = DatabaseService(uid: currentUser!.uid);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder( // Use StatefulBuilder to manage dialog-specific state
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Write a Review'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Rating: ${_currentRating.toStringAsFixed(1)}'),
                    Slider(
                      value: _currentRating,
                      min: 1,
                      max: 5,
                      divisions: 8,
                      label: _currentRating.toStringAsFixed(1),
                      onChanged: (double value) {
                        setDialogState(() {
                          _currentRating = value;
                        });
                      },
                    ),
                    TextField(
                      controller: _reviewController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: "Share your experience...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  child: const Text('Submit'),
                  onPressed: () async {
                    if (_reviewController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please write some content for your review.")),
                      );
                      return;
                    }

                    // Get the author's name from their UserData
                    UserData? authorData = await dbService.userData.first;

                    final newReview = Review(
                      id: '', // Firestore will generate
                      authorId: currentUser.uid,
                      authorName: authorData?.name ?? 'Anonymous', // Use logged-in user's name
                      content: _reviewController.text.trim(),
                      rating: _currentRating,
                      timestamp: Timestamp.now(),
                    );
                    
                    await _db.addReview(widget.userId, newReview);
                    
                    // Reset fields and close dialog
                    _reviewController.clear();
                    setDialogState(() => _currentRating = 3.0);
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Review submitted!")),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}