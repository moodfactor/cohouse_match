import 'package:flutter/material.dart';
import 'package:cohouse_match/services/firebase_admin_service.dart'; // Import your service class

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final FirebaseAdminService _adminService = FirebaseAdminService();
  bool _isLoading = false;

  void _handleDeleteImages() async {
    setState(() {
      _isLoading = true;
    });
    await _adminService.deleteProfileImages();
    setState(() {
      _isLoading = false;
    });
    // Optionally show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Image deletion process initiated. Check console for details.')),
    );
  }

  void _handleUpdateProfiles() async {
    setState(() {
      _isLoading = true;
    });
    await _adminService.updateAllUserProfilesWithImages();
    setState(() {
      _isLoading = false;
    });
    // Optionally show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile update process initiated. Check console for details.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Tools'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _isLoading
                ? CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: _handleDeleteImages,
                        child: Text('Delete All Profile Images'),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _handleUpdateProfiles,
                        child: Text('Update All User Profiles (with new images)'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
