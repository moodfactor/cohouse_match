import 'package:cohouse_match/screens/location_picker_screen.dart';
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
import 'package:cohouse_match/widgets/static_map_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _photoUrl;
  List<String> _personalityTags = [];
  List<String> _lifestyleDetails = [];
  String? _gender;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isInitialized = false;
  bool _isLoading = false;

  // Controllers for form fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  // State variables for location
  String? _locationName;
  GeoPoint? _locationCoordinates;

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    budgetController.dispose();
    ageController.dispose();
    super.dispose();
  }

  ImageProvider _getProfileImageProvider() {
    if (_imageFile != null) {
      return kIsWeb ? NetworkImage(_imageFile!.path) : FileImage(File(_imageFile!.path));
    }
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      return NetworkImage(_photoUrl!);
    }
    // Return a transparent image or a placeholder that works with CircleAvatar's child
    return const AssetImage('assets/images/transparent.png'); 
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
      if (pickedFile != null) {
        setState(() => _imageFile = pickedFile);
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick image: $e');
    }
  }

  Future<String?> _uploadImage(String uid) async {
    if (_imageFile == null) return null;
    try {
      final storageRef = FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
      if (kIsWeb) {
        await storageRef.putData(await _imageFile!.readAsBytes());
      } else {
        await storageRef.putFile(File(_imageFile!.path));
      }
      return await storageRef.getDownloadURL();
    } catch (e) {
      _showErrorSnackbar('Failed to upload image: $e');
      return null;
    }
  }

  Future<void> _openLocationPicker() async {
    // Hide keyboard if it's open
    FocusScope.of(context).unfocus();
    
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
    );

    if (result != null && result.containsKey('address') && result.containsKey('coordinates')) {
      final LatLng coords = result['coordinates'];
      setState(() {
        _locationName = result['address'];
        _locationCoordinates = GeoPoint(coords.latitude, coords.longitude);
      });
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _updateProfile(String uid, String email) async {
    if (!_formKey.currentState!.validate()) return;
    if (_locationCoordinates == null) {
      _showErrorSnackbar("Please set your location on the map.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? newPhotoUrl;
      if (_imageFile != null) {
        newPhotoUrl = await _uploadImage(uid);
      }

      await DatabaseService(uid: uid).updateUserData(
        email: email,
        name: nameController.text,
        bio: bioController.text,
        photoUrl: newPhotoUrl ?? _photoUrl,
        personalityTags: _personalityTags,
        lifestyleDetails: _lifestyleDetails,
        budget: double.tryParse(budgetController.text),
        location: _locationName,
        coordinates: _locationCoordinates,
        gender: _gender,
        age: int.tryParse(ageController.text),
      );

      _isInitialized = false;
      _showSuccessSnackbar('Profile updated successfully!');
    } catch (e) {
      _showErrorSnackbar('Failed to update profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<UserData?>(
      stream: DatabaseService(uid: user.uid).userData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !_isInitialized) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        }

        if (snapshot.hasData && snapshot.data != null && !_isInitialized) {
          final userData = snapshot.data!;
          _photoUrl = userData.photoUrl;
          _personalityTags = userData.personalityTags ?? [];
          _lifestyleDetails = userData.lifestyleDetails ?? [];
          _gender = userData.gender;
          _locationName = userData.location;
          _locationCoordinates = userData.coordinates;

          nameController.text = userData.name ?? '';
          bioController.text = userData.bio ?? '';
          budgetController.text = userData.budget?.toStringAsFixed(0) ?? '';
          ageController.text = userData.age?.toString() ?? '';

          _isInitialized = true;
        }

        return _buildProfileForm(user.uid, user.email!);
      },
    );
  }

  Widget _buildProfileForm(String uid, String email) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _getProfileImageProvider(),
                          child: _imageFile == null && (_photoUrl == null || _photoUrl!.isEmpty)
                              ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                              : null,
                        ),
                      ),
                      Positioned(bottom: 0, right: 0, child: Icon(Icons.camera_alt, color: Theme.of(context).primaryColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildTextField(controller: nameController, label: 'Full Name', icon: Icons.person_outline, validator: (val) => val?.isEmpty == true ? 'Name is required' : null),
                const SizedBox(height: 20),
                _buildTextField(controller: bioController, label: 'Bio', icon: Icons.edit_note, maxLines: 3, hint: 'Tell others about yourself...'),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildTextField(controller: ageController, label: 'Age', icon: Icons.cake_outlined, keyboardType: TextInputType.number, validator: (val) => (val?.isEmpty ?? true) ? 'Required' : null)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDropdown()),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTextField(controller: budgetController, label: 'Budget (\$)', icon: Icons.attach_money, keyboardType: TextInputType.number, validator: (val) => (val?.isEmpty ?? true) ? 'Required' : null),
                const SizedBox(height: 20),
                
                // --- LOCATION SECTION WITH STATIC MAP ---
                _buildSectionHeader("Your Area"),
                const SizedBox(height: 12),
                InteractiveStaticMapWidget(
                  coordinates: _locationCoordinates,
                  locationName: _locationName,
                  width: double.infinity,
                  height: 200,
                  zoom: 14,
                  onTap: _openLocationPicker,
                ),
                if (_locationName != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _locationName!,
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _openLocationPicker,
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                  ),
                ],
                // --- END OF LOCATION SECTION ---

                const SizedBox(height: 32),
                _buildSectionHeader('Personality Tags'),
                const SizedBox(height: 12),
                MultiSelectChip(
                  ['Introvert', 'Extrovert', 'Thinker', 'Feeler', 'Organized', 'Spontaneous'],
                  initialSelection: _personalityTags,
                  onSelectionChanged: (selectedList) => setState(() => _personalityTags = selectedList),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Lifestyle Details'),
                const SizedBox(height: 12),
                MultiSelectChip(
                  ['Pet-friendly', 'Night Owl', 'Early Bird', 'Vegetarian', 'Vegan', 'Remote Worker', 'Student'],
                  initialSelection: _lifestyleDetails,
                  onSelectionChanged: (selectedList) => setState(() => _lifestyleDetails = selectedList),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _updateProfile(uid, email),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Update Profile'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator, String? hint}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label, hintText: hint, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
        filled: true, fillColor: Colors.grey.shade50,
      ),
      maxLines: maxLines, keyboardType: keyboardType, validator: validator,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _gender,
      decoration: InputDecoration(
        labelText: 'Gender', prefixIcon: const Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
        filled: true, fillColor: Colors.grey.shade50,
      ),
      items: ['Male', 'Female', 'Other', 'Prefer not to say'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
      onChanged: (String? newValue) => setState(() => _gender = newValue),
      validator: (val) => val == null ? 'Please select a gender' : null,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600));
  }
}