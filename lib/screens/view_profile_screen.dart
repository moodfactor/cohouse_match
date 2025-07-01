// lib/screens/view_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:cohouse_match/models/user.dart';
import 'package:cohouse_match/models/review.dart';
import 'package:cohouse_match/services/database_service.dart';

class ViewProfileScreen extends StatelessWidget {
  final String userId;
  const ViewProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return Scaffold(
      appBar: AppBar(),
      body: StreamBuilder<UserData?>(
        stream: db.userDataFromUid(userId),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = userSnapshot.data!;

          return ListView(
            children: [
              // User profile header (photo, name, bio etc.)
              _buildProfileHeader(user),
              const Divider(height: 30, thickness: 1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Reviews',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              // Stream of reviews
              StreamBuilder<List<Review>>(
                stream: db.getReviews(userId),
                builder: (context, reviewSnapshot) {
                  if (!reviewSnapshot.hasData) {
                    return const Center(child: Text("No reviews yet."));
                  }
                  final reviews = reviewSnapshot.data!;
                  return Column(
                    children: reviews
                        .map((review) => _buildReviewTile(review))
                        .toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
      // TODO: Add a floating action button to add a review
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add review screen
          Navigator.pushNamed(context, '/addReview', arguments: userId);
        },
        tooltip: 'Add Review',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProfileHeader(UserData user) {
    // Build a nice profile header with photo, name, bio, tags, etc.
    // This can be reused from your swipe card or profile screen logic.
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: user.photoUrl != null
                ? NetworkImage(user.photoUrl!)
                : null,
            child: user.photoUrl == null
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            user.name ?? '',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          // ... more user details
          if (user.bio != null)
            Text(user.bio!, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            children:
                user.personalityTags
                    ?.map((tag) => Chip(label: Text(tag)))
                    .toList() ??
                [],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            children:
                user.lifestyleDetails
                    ?.map((detail) => Chip(label: Text(detail)))
                    .toList() ??
                [],
          ),
          const SizedBox(height: 10),
          Text(
            'Budget: ${user.budget?.toStringAsFixed(2) ?? 'N/A'}',
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            'Location: ${user.location ?? 'N/A'}',
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            'Age: ${user.age?.toString() ?? 'N/A'}',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTile(Review review) {
    return ListTile(
      title: Text(review.authorName),
      subtitle: Text(review.content),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(review.rating.toStringAsFixed(1)),
          const Icon(Icons.star, color: Colors.amber, size: 16),
        ],
      ),
    );
  }
}
