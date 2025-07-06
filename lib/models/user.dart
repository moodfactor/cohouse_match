import 'package:cloud_firestore/cloud_firestore.dart';
class UserData {
  final String uid;
  final String email;
  String? name;
  String? bio;
  String? photoUrl;
  List<String>? personalityTags;
  List<String>? lifestyleDetails;
  double? budget;
  String? location; // For display name e.g., "Brooklyn, NY"
  GeoPoint? coordinates; // For GeoPoint coordinates
  String? gender;
  int? age;
  List<String>? fcmTokens;
  bool? isOnline; // Add this line
  
  // Location Privacy Settings
  bool? showExactLocation; // Show exact location vs approximate area
  double? locationRadius; // Radius in miles for location privacy
  bool? showOnMap; // Whether to appear on map view
  bool? isAdmin; // Add this line

  UserData({
    required this.uid,
    required this.email,
    this.name,
    this.bio,
    this.photoUrl,
    this.personalityTags,
    this.lifestyleDetails,
    this.budget,
    this.location,
    this.coordinates,
    this.age,
    this.gender,
    this.fcmTokens,
    this.isOnline,
    this.showExactLocation,
    this.locationRadius,
    this.showOnMap,
    this.isAdmin, // <--- ADD THIS LINE
  });

  // Factory constructor to create a UserData object from a map (Firestore document)
  factory UserData.fromMap(Map<String, dynamic> data, String uid) {
    return UserData(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'],
      bio: data['bio'],
      photoUrl: data['photoUrl'],
      personalityTags: data['personalityTags'] != null
          ? List<String>.from(data['personalityTags'])
          : [],
      lifestyleDetails: data['lifestyleDetails'] != null
          ? List<String>.from(data['lifestyleDetails'])
          : [],
      budget: data['budget']?.toDouble(),
      location: data['location'],
      coordinates: data['coordinates'] as GeoPoint?,
      gender: data['gender'],
      age: data['age'],
      fcmTokens: data['fcmTokens'] != null
          ? List<String>.from(data['fcmTokens'])
          : [],
      isOnline: data['isOnline'],
      showExactLocation: data['showExactLocation'] ?? true,
      locationRadius: data['locationRadius']?.toDouble() ?? 5.0,
      showOnMap: data['showOnMap'] ?? true,
      isAdmin: data['isAdmin'] ?? false, // <--- ADD THIS LINE
    );
  }

  // Method to convert a UserData object to a map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'bio': bio,
      'photoUrl': photoUrl,
      'personalityTags': personalityTags,
      'lifestyleDetails': lifestyleDetails,
      'budget': budget,
      'location': location,
      'coordinates': coordinates, // For geohash and geopoint
      'gender': gender,
      'age': age,
      'fcmTokens': fcmTokens,
      'isOnline': isOnline,
      'showExactLocation': showExactLocation,
      'locationRadius': locationRadius,
      'showOnMap': showOnMap,
      'isAdmin': isAdmin, // <--- ADD THIS LINE
    };
  }

  bool get isProfileComplete {
    return (name?.isNotEmpty ?? false) &&
        (bio?.isNotEmpty ?? false) &&
        (photoUrl?.isNotEmpty ?? false) &&
        (personalityTags?.isNotEmpty ?? false) &&
        (lifestyleDetails?.isNotEmpty ?? false) &&
        (budget != null && budget! > 0) &&
        (location?.isNotEmpty ?? false) &&
        (coordinates != null) &&
        (gender?.isNotEmpty ?? false) &&
        (age != null && age! > 0);
  }
}
