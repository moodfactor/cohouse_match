import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cohouse_match/services/database_service.dart';
import 'package:cohouse_match/models/user.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cohouse_match/widgets/multi_select_chip.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _bio;
  String? _photoUrl;
  List<String> _personalityTags = [];
  List<String> _lifestyleDetails = [];
  double? _budget;
  String? _location;
  String? _gender;
  int? _age;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isInitialized = false; // Flag to prevent re-initialization

  // Controllers for form fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Controllers are initialized empty and populated by the StreamBuilder once.
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    budgetController.dispose();
    locationController.dispose();
    ageController.dispose();
    super.dispose();
  }

  ImageProvider _getProfileImageProvider() {
    if (_imageFile != null) {
      if (kIsWeb) {
        return NetworkImage(_imageFile!.path);
      } else {
        return FileImage(File(_imageFile!.path));
      }
    }
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      return NetworkImage(_photoUrl!);
    }
    // Make sure you have a default profile image in your assets folder
    return const AssetImage('assets/default_profile.png');
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<String?> _uploadImage(String uid) async {
    if (_imageFile == null) return null;

    try {
      final storageRef =
          FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
      if (kIsWeb) {
        await storageRef.putData(await _imageFile!.readAsBytes());
      } else {
        await storageRef.putFile(File(_imageFile!.path));
      }
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    if (user == null) {
      return const Center(child: CircularProgressIndicator()); // Or a login prompt
    }

    return StreamBuilder<UserData?>(
      stream: DatabaseService(uid: user.uid).userData,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // Initialize form data only once from the stream
        if (snapshot.hasData && snapshot.data != null && !_isInitialized) {
          UserData userData = snapshot.data!;
          _name = userData.name;
          _bio = userData.bio;
          _photoUrl = userData.photoUrl;
          _personalityTags = userData.personalityTags ?? [];
          _lifestyleDetails = userData.lifestyleDetails ?? [];
          _budget = userData.budget;
          _location = userData.location;
          _gender = userData.gender;
          _age = userData.age;

          // Update controllers
          nameController.text = _name ?? '';
          bioController.text = _bio ?? '';
          budgetController.text = _budget?.toString() ?? '';
          locationController.text = _location ?? '';
          ageController.text = _age?.toString() ?? '';

          _isInitialized = true;
        }

        return _buildProfileForm(user.uid, user);
      },
    );
  }

  Widget _buildProfileForm(String uid, User user) {
    // Controllers are now managed in the StreamBuilder, no need to set them here.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _getProfileImageProvider(),
                    child: _imageFile == null &&
                            (_photoUrl == null || _photoUrl!.isEmpty)
                        ? Icon(Icons.camera_alt,
                            size: 40, color: Colors.grey[600])
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (val) =>
                    val!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: bioController,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 3,
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    val!.isEmpty ? 'Please enter your age' : null,
              ),
              const SizedBox(height: 20.0),
              DropdownButtonFormField<String>(
                value: _gender,
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
                    _gender = newValue;
                  });
                },
                validator: (val) => val == null ? 'Please select a gender' : null,
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: budgetController,
                decoration: const InputDecoration(labelText: 'Budget'),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    val!.isEmpty ? 'Please enter a budget' : null,
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (val) =>
                    val!.isEmpty ? 'Please enter a location' : null,
              ),
              const SizedBox(height: 20.0),
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
                initialSelection: _personalityTags,
                onSelectionChanged: (selectedList) {
                  _personalityTags = selectedList;
                },
              ),
              const SizedBox(height: 20.0),
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
                initialSelection: _lifestyleDetails,
                onSelectionChanged: (selectedList) {
                  _lifestyleDetails = selectedList;
                },
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                child: const Text('Update Profile'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _name = nameController.text;
                    _bio = bioController.text;
                    _budget = double.tryParse(budgetController.text);
                    _location = locationController.text;
                    _age = int.tryParse(ageController.text);

                    String? newPhotoUrl = await _uploadImage(uid);
                    await DatabaseService(uid: uid).updateUserData(
                      user.email!,
                      _name,
                      _bio,
                      newPhotoUrl ?? _photoUrl,
                      _personalityTags,
                      _lifestyleDetails,
                      _budget,
                      _location,
                      _gender,
                      _age,
                    );

                    if (mounted) {
                      if (newPhotoUrl != null) {
                        setState(() {
                          _photoUrl = newPhotoUrl;
                          _imageFile = null;
                        });
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile Updated')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}


