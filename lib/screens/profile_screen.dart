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
  List<String>? _personalityTags;
  List<String>? _lifestyleDetails;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
      }
    });
  }

  Future<String?> _uploadImage(String uid) async {
    if (_imageFile == null) return null;

    try {
      final storageRef = FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
      await storageRef.putFile(_imageFile!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    return StreamBuilder<UserData>(
      stream: DatabaseService(uid: user!.uid).userData,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          UserData? userData = snapshot.data;
          _name = _name ?? userData?.name;
          _bio = _bio ?? userData?.bio;
          _photoUrl = _photoUrl ?? userData?.photoUrl;
          _personalityTags = _personalityTags ?? userData?.personalityTags;
          _lifestyleDetails = _lifestyleDetails ?? userData?.lifestyleDetails;

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
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (_photoUrl != null ? NetworkImage(_photoUrl!) : null) as ImageProvider<Object>?,
                          child: _imageFile == null && _photoUrl == null
                              ? Icon(Icons.camera_alt, size: 40, color: Colors.grey[600])
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    TextFormField(
                      initialValue: _name,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (val) =>
                          val!.isEmpty ? 'Please enter a name' : null,
                      onChanged: (val) => setState(() => _name = val),
                    ),
                    const SizedBox(height: 20.0),
                    TextFormField(
                      initialValue: _bio,
                      decoration: const InputDecoration(labelText: 'Bio'),
                      maxLines: 3,
                      onChanged: (val) => setState(() => _bio = val),
                    ),
                    const SizedBox(height: 20.0),
                    const Text('Personality Tags:'),
                    MultiSelectChip(
                      ['Introvert', 'Extrovert', 'Thinker', 'Feeler', 'Organized', 'Spontaneous'],
                      initialSelection: _personalityTags,
                      onSelectionChanged: (selectedList) {
                        setState(() {
                          _personalityTags = selectedList;
                        });
                      },
                    ),
                    const SizedBox(height: 20.0),
                    const Text('Lifestyle Details:'),
                    MultiSelectChip(
                      ['Pet-friendly', 'Night Owl', 'Early Bird', 'Vegetarian', 'Vegan', 'Remote Worker', 'Student'],
                      initialSelection: _lifestyleDetails,
                      onSelectionChanged: (selectedList) {
                        setState(() {
                          _lifestyleDetails = selectedList;
                        });
                      },
                    ),
                    const SizedBox(height: 20.0),
                    ElevatedButton(
                      child: const Text('Update Profile'),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          String? newPhotoUrl = await _uploadImage(user.uid);
                          await DatabaseService(uid: user.uid).updateUserData(
                            user.email!,
                            _name,
                            _bio,
                            newPhotoUrl ?? _photoUrl,
                            _personalityTags,
                            _lifestyleDetails,
                            null, // budget
                            null, // location
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile Updated')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}