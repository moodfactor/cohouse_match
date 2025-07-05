// lib/screens/location_picker_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _currentMapCenter = const LatLng(37.7749, -122.4194); // Default to San Francisco
  String _currentAddress = "Loading...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError("Location services are disabled.");
      setState(() => _isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError("Location permissions are denied.");
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showError("Location permissions are permanently denied, we cannot request permissions.");
      setState(() => _isLoading = false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentMapCenter = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      _getAddressFromLatLng(_currentMapCenter);
      _mapController?.animateCamera(CameraUpdate.newLatLng(_currentMapCenter));
    } catch (e) {
      _showError("Failed to get current location.");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    // Add a small delay to prevent rapid-fire geocoding requests
    await Future.delayed(const Duration(milliseconds: 500));
    
    try {
      print("Attempting geocoding for: ${position.latitude}, ${position.longitude}");
      
      // Validate coordinates first
      if (position.latitude.isNaN || position.longitude.isNaN ||
          position.latitude.abs() > 90 || position.longitude.abs() > 180) {
        setState(() {
          _currentAddress = "Invalid coordinates: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        });
        return;
      }
      
      List<Placemark>? placemarks;
      
      // Try geocoding with timeout and retry mechanism
      try {
        placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print("Geocoding timeout");
            return <Placemark>[];
          },
        );
      } catch (geocodingError) {
        print("Geocoding service error: $geocodingError");
        // Fallback to coordinate display
        setState(() {
          _currentAddress = "Coordinates: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        });
        return;
      }
      
      if (placemarks != null && placemarks.isNotEmpty) {
        print("Found ${placemarks.length} placemarks");
        
        // Try to find the best placemark with available data
        Placemark? bestPlace;
        String address = '';
        
        // Look through all placemarks to find the best one
        for (var placemark in placemarks) {
          String tempAddress = '';
          
          // Try different combinations of address components
          if (placemark.locality != null && placemark.locality!.trim().isNotEmpty) {
            tempAddress += placemark.locality!.trim();
          }
          
          if (placemark.administrativeArea != null && placemark.administrativeArea!.trim().isNotEmpty) {
            if (tempAddress.isNotEmpty) tempAddress += ', ';
            tempAddress += placemark.administrativeArea!.trim();
          }
          
          if (tempAddress.isEmpty && placemark.subAdministrativeArea != null && placemark.subAdministrativeArea!.trim().isNotEmpty) {
            tempAddress = placemark.subAdministrativeArea!.trim();
          }
          
          if (tempAddress.isEmpty && placemark.country != null && placemark.country!.trim().isNotEmpty) {
            tempAddress = placemark.country!.trim();
          }
          
          if (tempAddress.isEmpty && placemark.name != null && placemark.name!.trim().isNotEmpty) {
            tempAddress = placemark.name!.trim();
          }
          
          if (tempAddress.isEmpty && placemark.street != null && placemark.street!.trim().isNotEmpty) {
            tempAddress = placemark.street!.trim();
          }
          
          // If we found a good address, use it
          if (tempAddress.isNotEmpty && tempAddress != 'null' && tempAddress != 'undefined') {
            address = tempAddress;
            bestPlace = placemark;
            break;
          }
        }
        
        // If no good address found, use coordinates
        if (address.isEmpty) {
          address = "Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        }
        
        print("Final address: $address");
        setState(() {
          _currentAddress = address;
        });
      } else {
        print("No placemarks found");
        setState(() {
          _currentAddress = "Coordinates: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        });
      }
    } catch (e) {
      print("Geocoding error: $e");
      setState(() {
        _currentAddress = "Coordinates: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
      });
    }
  }
  
  void _showError(String message) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Your Area")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentMapCenter, zoom: 14),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) {
              _currentMapCenter = position.target;
            },
            onCameraIdle: () async {
              // Fetch address when map stops moving
              await _getAddressFromLatLng(_currentMapCenter);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),
          const Center(child: Icon(Icons.location_pin, color: Colors.red, size: 50)),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_currentAddress, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: const Text("Set This Location"),
                    onPressed: () {
                      print("Set This Location button pressed!");
                      // Return the selected location details
                      Navigator.of(context).pop({
                        'address': _currentAddress,
                        'coordinates': _currentMapCenter,
                      });
                    },
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}