class UserData {
  final String uid;
  final String email;
  String? name;
  String? bio;
  String? photoUrl;
  List<String>? personalityTags;
  List<String>? lifestyleDetails;
  double? budget;
  String? location;
  String? gender;
  int? age;

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
    this.gender,
    this.age,
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
          : null,
      lifestyleDetails: data['lifestyleDetails'] != null
          ? List<String>.from(data['lifestyleDetails'])
          : null,
      budget: data['budget']?.toDouble(),
      location: data['location'],
      gender: data['gender'],
      age: data['age'],
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
      'gender': gender,
      'age': age,
    };
  }

  bool get isProfileComplete {
    return (name?.isNotEmpty ?? false) &&
           (bio?.isNotEmpty ?? false) &&
           (personalityTags?.isNotEmpty ?? false) &&
           (lifestyleDetails?.isNotEmpty ?? false) &&
           (budget != null) &&
           (location?.isNotEmpty ?? false) &&
           (gender?.isNotEmpty ?? false) &&
           (age != null);
  }
}