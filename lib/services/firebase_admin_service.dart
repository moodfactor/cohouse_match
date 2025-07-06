import 'package:cloud_functions/cloud_functions.dart';

class FirebaseAdminService {
  // Function to delete existing profile images
  Future<void> deleteProfileImages() async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('deleteProfileImages');
      final HttpsCallableResult result = await callable.call();
      print('Delete Images Function Result: ${result.data}');
      // You might want to show a user-friendly message here (e.g., a SnackBar)
    } on FirebaseFunctionsException catch (e) {
      print('Error calling deleteProfileImages: ${e.code} - ${e.message}');
      // Handle specific Firebase Functions errors
    } catch (e) {
      print('Unexpected error: $e');
      // Handle other potential errors
    }
  }

  // Function to update user profiles with new artificial data and images
  Future<void> updateAllUserProfilesWithImages() async {
    final List<String> imageUrls = [
      "https://firebasestorage.googleapis.com/v0/b/cohousematch.firebasestorage.app/o/profile_images%2F1600w-BFO0G6UynG0.webp?alt=media&token=7d0312cd-b5d4-442c-93ff-d3862999ad85",
      "https://firebasestorage.googleapis.com/v0/b/cohousematch.firebasestorage.app/o/profile_images%2F1600w-H6QrJKVmgAo.webp?alt=media&token=ac1ff4c7-6af6-435a-afbd-dc422d84b14f",
      "https://firebasestorage.googleapis.com/v0/b/cohousematch.firebasestorage.app/o/profile_images%2F1600w-V4WRnINjCx8.jpg?alt=media&token=dd3b3ef4-50cb-499e-a8e8-dde03e54dcf6",
      "https://firebasestorage.googleapis.com/v0/b/cohousematch.firebasestorage.app/o/profile_images%2F1600w-W2vpzYlfm1E.webp?alt=media&token=30d3c74c-19cf-4840-a278-45c516a5580a",
      "https://firebasestorage.googleapis.com/v0/b/cohousematch.firebasestorage.app/o/profile_images%2F1600w-bag4ZU9rgho.webp?alt=media&token=e1696300-59e3-4f1b-b93e-eb8aea746f86",
      "https://firebasestorage.googleapis.com/v0/b/cohousematch.firebasestorage.app/o/profile_images%2F1600w-bwB4uERax7Q.webp?alt=media&token=f7219972-4449-43fc-9270-4f66c1e57db8",
      "https://firebasestorage.googleapis.com/v0/b/cohousematch.firebasestorage.app/o/profile_images%2F1600w-iSTDKvMgaYU.webp?alt=media&token=0d4c3d19-c547-4f41-96ab-575a5d7aa879",
      "https://firebasestorage.googleapis.com/v0/b/cohousematch.firebasestorage.app/o/profile_images%2F1600w-q9FBl8fxOpY.webp?alt=media&token=d1ea6fbd-fc1c-42ee-8319-420d63bdbdde",
      "https://firebasestorage.googleapis.com/v0/b/cohousematch.firebasestorage.app/o/profile_images%2F1600w-sKsNI4VEFMo.webp?alt=media&token=3e4822b5-531a-40af-99ca-a5304e8424b1",
    ];

    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('updateAllUserProfiles');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'photoUrls': imageUrls,
      });
      print('Update Profiles Function Result: ${result.data}');
      // You might want to show a user-friendly message here (e.g., a SnackBar)
    } on FirebaseFunctionsException catch (e) {
      print('Error calling updateAllUserProfiles: ${e.code} - ${e.message}');
      // Handle specific Firebase Functions errors
    } catch (e) {
      print('Unexpected error: $e');
      // Handle other potential errors
    }
  }
}
