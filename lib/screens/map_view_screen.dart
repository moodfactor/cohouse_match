import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cohouse_match/models/user.dart';
import 'package:cohouse_match/services/location_service.dart';
import 'package:cohouse_match/services/auth_service.dart';
import 'package:cohouse_match/services/database_service.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  GoogleMapController? _mapController;
  LatLng _currentLocation = const LatLng(37.7749, -122.4194); // Default to San Francisco
  Set<Marker> _markers = {};
  List<UserData> _nearbyUsers = [];
  bool _isLoading = true;
  double _currentRadius = 25.0; // Default 25 miles
  UserData? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      // Get current user data
      final authService = AuthService();
      final currentUserId = authService.getCurrentUser()?.uid;
      if (currentUserId != null) {
        final databaseService = DatabaseService(uid: currentUserId);
        final userData = await databaseService.getUserData();
        if (userData != null) {
          _currentUser = UserData.fromMap(userData, currentUserId);
        }
      }

      // Get current location
      await _getCurrentLocation();
      
      // Load nearby users
      await _loadNearbyUsers();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if user has saved location
      if (_currentUser?.coordinates != null) {
        _currentLocation = LatLng(
          _currentUser!.coordinates!.latitude,
          _currentUser!.coordinates!.longitude,
        );
        return;
      }

      // Otherwise get device location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        _currentLocation = LatLng(position.latitude, position.longitude);
      }
    } catch (e) {
    }
  }

  Future<void> _loadNearbyUsers() async {
    try {
      final authService = AuthService();
      final currentUserId = authService.getCurrentUser()?.uid ?? '';
      
      List<UserData> users = await LocationService.getUsersInRadius(
        _currentLocation.latitude,
        _currentLocation.longitude,
        _currentRadius,
        currentUserId,
      );
      
      setState(() {
        _nearbyUsers = users;
        _createMarkers();
      });
    } catch (e) {
    }
  }

  void _createMarkers() {
    Set<Marker> markers = {};
    
    // Add current user marker
    if (_currentUser != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_user'),
          position: _currentLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'You',
            snippet: _currentUser!.name ?? 'Your location',
          ),
        ),
      );
    }
    
    // Add nearby users markers
    for (UserData user in _nearbyUsers) {
      if (user.coordinates != null) {
        // Use display location for privacy
        final displayLocation = LocationService.getDisplayLocation(user);
        if (displayLocation != null) {
          markers.add(
            Marker(
              markerId: MarkerId(user.uid),
              position: LatLng(displayLocation.latitude, displayLocation.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              infoWindow: InfoWindow(
                title: user.name ?? 'User',
                snippet: user.location ?? 'Potential match',
              ),
              onTap: () => _showUserBottomSheet(user),
              consumeTapEvents: true,
            ),
          );
        }
      }
    }
    
    setState(() {
      _markers = markers;
    });
  }

  void _showUserBottomSheet(UserData user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile photo and basic info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                          child: user.photoUrl == null
                            ? const Icon(Icons.person, size: 40)
                            : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name ?? 'Unknown',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (user.age != null)
                                Text(
                                  '${user.age} years old',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              if (user.location != null)
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        user.location!,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Distance info
                    if (user.coordinates != null && _currentUser?.coordinates != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.near_me, color: Colors.blue[600]),
                            const SizedBox(width: 8),
                            Text(
                              '${_calculateDistance(user).toStringAsFixed(1)} miles away',
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Bio
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      Text(
                        'About',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.bio!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Budget
                    if (user.budget != null) ...[
                      Row(
                        children: [
                          Icon(Icons.attach_money, color: Colors.green[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Budget: \${user.budget!.toStringAsFixed(0)}/month',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Tags
                    if (user.personalityTags != null && user.personalityTags!.isNotEmpty) ...[
                      Text(
                        'Personality',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: user.personalityTags!.map((tag) => Chip(
                          label: Text(tag, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.blue[50],
                          side: BorderSide(color: Colors.blue[200]!),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    if (user.lifestyleDetails != null && user.lifestyleDetails!.isNotEmpty) ...[
                      Text(
                        'Lifestyle',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: user.lifestyleDetails!.map((detail) => Chip(
                          label: Text(detail, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.green[50],
                          side: BorderSide(color: Colors.green[200]!),
                        )).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // TODO: Navigate to full profile view
                            },
                            icon: const Icon(Icons.person),
                            label: const Text('View Profile'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // TODO: Start conversation
                            },
                            icon: const Icon(Icons.message),
                            label: const Text('Message'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  double _calculateDistance(UserData user) {
    if (user.coordinates == null || _currentUser?.coordinates == null) return 0.0;
    
    return LocationService.calculateDistance(
      _currentUser!.coordinates!.latitude,
      _currentUser!.coordinates!.longitude,
      user.coordinates!.latitude,
      user.coordinates!.longitude,
    );
  }

  void _onRadiusChanged(double value) {
    setState(() {
      _currentRadius = value;
    });
    _loadNearbyUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.layers),
            onSelected: (value) {
              // Map type switching could be added here
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'normal',
                child: Row(
                  children: [
                    Icon(Icons.map),
                    SizedBox(width: 8),
                    Text('Normal'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'satellite',
                child: Row(
                  children: [
                    Icon(Icons.satellite),
                    SizedBox(width: 8),
                    Text('Satellite'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(_currentLocation, 14),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Radius slider and stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Search Radius: ${_currentRadius.toInt()} miles',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_nearbyUsers.length} matches',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _currentRadius,
                      min: 5,
                      max: 100,
                      divisions: 19,
                      onChanged: _onRadiusChanged,
                      activeColor: Theme.of(context).primaryColor,
                    ),
                    if (_nearbyUsers.isNotEmpty)
                      Text(
                        'Tap on markers to view profiles',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              // Map
              Expanded(
                child: GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation,
                    zoom: 12,
                  ),
                  markers: _markers,
                  myLocationEnabled: false, // We handle this manually
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),
            ],
          ),
    );
  }
}

