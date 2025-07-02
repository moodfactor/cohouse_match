import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhotoPage extends StatefulWidget {
  final VoidCallback onNext;
  final Function(Map<String, dynamic>) onDataChanged;

  const PhotoPage({super.key, required this.onNext, required this.onDataChanged});

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  XFile? _imageXFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageXFile = pickedFile;
      });
    }
  }

  Future<void> _uploadAndProceed() async {
    if (_imageXFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a photo to continue.")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final storageRef = FirebaseStorage.instance.ref().child('profile_images/${user.uid}.jpg');
      
      // Handle file upload differently for web and mobile
      if (kIsWeb) {
        final bytes = await _imageXFile!.readAsBytes();
        await storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        await storageRef.putFile(File(_imageXFile!.path));
      }

      final downloadUrl = await storageRef.getDownloadURL();
      
      widget.onDataChanged({'photoUrl': downloadUrl});
      widget.onNext();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Conditional image provider
    ImageProvider? backgroundImageProvider;
    if (_imageXFile != null) {
      if (kIsWeb) {
        backgroundImageProvider = NetworkImage(_imageXFile!.path);
      } else {
        backgroundImageProvider = FileImage(File(_imageXFile!.path));
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text(
            "A great photo gets more matches!",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: Colors.grey[200],
              backgroundImage: backgroundImageProvider,
              child: _imageXFile == null
                  ? Icon(Icons.camera_alt, size: 60, color: Colors.grey[600])
                  : null,
            ),
          ),
          const Spacer(),
          if (_isUploading)
            const CircularProgressIndicator()
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _uploadAndProceed,
                child: const Text('Looks Good! Next'),
              ),
            ),
        ],
      ),
    );
  }
}