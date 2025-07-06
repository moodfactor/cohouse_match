import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cohouse_match/models/user.dart';

class LocationService {
  // Calculate distance between two points using Haversine formula
  static double calculateDistance(
    double lat1, double lon1, 
    double lat2, double lon2
  ) {
    const double earthRadius = 3959; // Earth's radius in miles
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
  
  // Filter users by distance from a given location
  static List<UserData> filterUsersByDistance(
    List<UserData> users,
    double centerLat,
    double centerLon,
    double maxDistanceMiles
  ) {
    return users.where((user) {
      if (user.coordinates == null) return false;
      
      double distance = calculateDistance(
        centerLat, centerLon,
        user.coordinates!.latitude, user.coordinates!.longitude
      );
      
      return distance <= maxDistanceMiles;
    }).toList();
  }
  
  // Get approximate location for privacy (adds random offset)
  static GeoPoint getApproximateLocation(GeoPoint exactLocation, double radiusMiles) {
    // Convert miles to degrees (rough approximation)
    double radiusDegrees = radiusMiles / 69.0; // 1 degree ≈ 69 miles
    
    // Generate random offset within the radius
    Random random = Random();
    double angle = random.nextDouble() * 2 * pi;
    double distance = random.nextDouble() * radiusDegrees;
    
    double offsetLat = distance * cos(angle);
    double offsetLon = distance * sin(angle);
    
    return GeoPoint(
      exactLocation.latitude + offsetLat,
      exactLocation.longitude + offsetLon
    );
  }
  
  // Get display location based on privacy settings
  static GeoPoint? getDisplayLocation(UserData user) {
    if (user.coordinates == null) return null;
    
    if (user.showExactLocation == true) {
      return user.coordinates;
    } else {
      double radius = user.locationRadius ?? 5.0;
      return getApproximateLocation(user.coordinates!, radius);
    }
  }
  
  // Generate static map URL for profile display
  static String getStaticMapUrl(
    double lat, 
    double lon, 
    {int width = 300, int height = 200, int zoom = 13}
  ) {
    const String apiKey = 'AIzaSyBcFW1YmFgcQC7an_-okdJSPgaOvR_CI4M';
    return 'https://maps.googleapis.com/maps/api/staticmap?'
        'center=$lat,$lon&'
        'zoom=$zoom&'
        'size=${width}x$height&'
        'markers=color:red%7C$lat,$lon&'
        'key=$apiKey';
  }
  
  // Get users within a certain radius (for map view)
  static Future<List<UserData>> getUsersInRadius(
    double centerLat,
    double centerLon,
    double radiusMiles,
    String currentUserId
  ) async {
    try {
      // Get all users from Firestore
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('showOnMap', isEqualTo: true)
          .get();
      
      List<UserData> users = [];
      
      for (var doc in snapshot.docs) {
        if (doc.id == currentUserId) continue; // Skip current user
        
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        UserData user = UserData.fromMap(data, doc.id);
        
        if (user.coordinates != null) {
          double distance = calculateDistance(
            centerLat, centerLon,
            user.coordinates!.latitude, user.coordinates!.longitude
          );
          
          if (distance <= radiusMiles) {
            users.add(user);
          }
        }
      }
      
      return users;
    } catch (e) {
      return [];
    }
  }
  
  // Sort users by distance from a point
  static List<UserData> sortUsersByDistance(
    List<UserData> users,
    double centerLat,
    double centerLon
  ) {
    users.sort((a, b) {
      if (a.coordinates == null && b.coordinates == null) return 0;
      if (a.coordinates == null) return 1;
      if (b.coordinates == null) return -1;
      
      double distanceA = calculateDistance(
        centerLat, centerLon,
        a.coordinates!.latitude, a.coordinates!.longitude
      );
      
      double distanceB = calculateDistance(
        centerLat, centerLon,
        b.coordinates!.latitude, b.coordinates!.longitude
      );
      
      return distanceA.compareTo(distanceB);
    });
    
    return users;
  }
}
