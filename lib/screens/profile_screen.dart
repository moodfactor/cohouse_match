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
  final TextEditingController locationController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

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
    return const AssetImage('assets/default_profile.png');
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick image: $e');
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
      _showErrorSnackbar('Failed to upload image: $e');
      return null;
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _updateProfile(String uid, String email) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Parse form values
      final name = nameController.text.trim();
      final bio = bioController.text.trim();
      final budget = double.tryParse(budgetController.text.trim());
      final location = locationController.text.trim();
      final age = int.tryParse(ageController.text.trim());

      // Validate parsed values
      if (age == null || age <= 0) {
        _showErrorSnackbar('Please enter a valid age');
        return;
      }
      if (budget == null || budget <= 0) {
        _showErrorSnackbar('Please enter a valid budget');
        return;
      }
      if (_gender == null) {
        _showErrorSnackbar('Please select a gender');
        return;
      }

      // Upload image if changed
      String? newPhotoUrl;
      if (_imageFile != null) {
        newPhotoUrl = await _uploadImage(uid);
      }

      // Update database
      await DatabaseService(uid: uid).updateUserData(
        email,
        name,
        bio,
        newPhotoUrl ?? _photoUrl,
        _personalityTags,
        _lifestyleDetails,
        budget,
        location,
        _gender!,
        age,
      );

      // Update local state
      if (newPhotoUrl != null) {
        setState(() {
          _photoUrl = newPhotoUrl;
          _imageFile = null;
        });
      }

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
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading user data...'),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<UserData?>(
      stream: DatabaseService(uid: user.uid).userData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Initialize form data only once from the stream
        if (snapshot.hasData && snapshot.data != null && !_isInitialized) {
          final userData = snapshot.data!;
          _photoUrl = userData.photoUrl;
          _personalityTags = userData.personalityTags ?? [];
          _lifestyleDetails = userData.lifestyleDetails ?? [];
          _gender = userData.gender;

          // Update controllers
          nameController.text = userData.name ?? '';
          bioController.text = userData.bio ?? '';
          budgetController.text = userData.budget?.toString() ?? '';
          locationController.text = userData.location ?? '';
          ageController.text = userData.age?.toString() ?? '';

          _isInitialized = true;
        }

        return _buildProfileForm(user.uid, user.email!);
      },
    );
  }

  Widget _buildProfileForm(String uid, String email) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                // Profile Image Section
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 58,
                            backgroundColor: Colors.grey[100],
                            backgroundImage: _getProfileImageProvider(),
                            child: _imageFile == null &&
                                    (_photoUrl == null || _photoUrl!.isEmpty)
                                ? Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey[400],
                                  )
                                : null,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Tap to change photo',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                const SizedBox(height: 32),

                // Form Fields
                _buildTextField(
                  controller: nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (val) => val?.isEmpty == true ? 'Name is required' : null,
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: bioController,
                  label: 'Bio',
                  icon: Icons.edit_note,
                  maxLines: 3,
                  hint: 'Tell others about yourself...',
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: ageController,
                        label: 'Age',
                        icon: Icons.cake_outlined,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val?.isEmpty == true) return 'Age is required';
                          final age = int.tryParse(val!);
                          if (age == null || age <= 0 || age > 120) {
                            return 'Enter a valid age';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: budgetController,
                  label: 'Budget (\$)',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val?.isEmpty == true) return 'Budget is required';
                    final budget = double.tryParse(val!);
                    if (budget == null || budget <= 0) {
                      return 'Enter a valid budget';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: locationController,
                  label: 'Location',
                  icon: Icons.location_on_outlined,
                  validator: (val) => val?.isEmpty == true ? 'Location is required' : null,
                ),
                const SizedBox(height: 32),

                // Personality Tags
                _buildSectionHeader('Personality Tags'),
                const SizedBox(height: 12),
                MultiSelectChip(
                  ['Introvert', 'Extrovert', 'Thinker', 'Feeler', 'Organized', 'Spontaneous'],
                  initialSelection: _personalityTags,
                  onSelectionChanged: (selectedList) {
                    setState(() {
                      _personalityTags = selectedList;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Lifestyle Details
                _buildSectionHeader('Lifestyle Details'),
                const SizedBox(height: 12),
                MultiSelectChip(
                  ['Pet-friendly', 'Night Owl', 'Early Bird', 'Vegetarian', 'Vegan', 'Remote Worker', 'Student'],
                  initialSelection: _lifestyleDetails,
                  onSelectionChanged: (selectedList) {
                    setState(() {
                      _lifestyleDetails = selectedList;
                    });
                  },
                ),
                const SizedBox(height: 40),

                // Update Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _updateProfile(uid, email),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Update Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _gender,
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: ['Male', 'Female', 'Other', 'Prefer not to say']
          .map((String value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              ))
          .toList(),
      onChanged: (String? newValue) {
        setState(() {
          _gender = newValue;
        });
      },
      validator: (val) => val == null ? 'Please select a gender' : null,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
    );
  }
}