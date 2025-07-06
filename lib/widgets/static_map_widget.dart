import 'package:flutter/material.dart';
import 'package:cohouse_match/services/location_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StaticMapWidget extends StatelessWidget {
  final GeoPoint? coordinates;
  final double width;
  final double height;
  final int zoom;
  final bool showLocationIcon;
  final BorderRadius? borderRadius;
  final String? fallbackText;

  const StaticMapWidget({
    super.key,
    required this.coordinates,
    this.width = 300,
    this.height = 200,
    this.zoom = 13,
    this.showLocationIcon = true,
    this.borderRadius,
    this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    if (coordinates == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 40,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              fallbackText ?? 'Location not set',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final safeWidth = width.isFinite ? width.toInt() : 300;
    final safeHeight = height.isFinite ? height.toInt() : 200;
    
    final mapUrl = LocationService.getStaticMapUrl(
      coordinates!.latitude,
      coordinates!.longitude,
      width: safeWidth,
      height: safeHeight,
      zoom: zoom,
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.network(
              mapUrl,
              width: safeWidth.toDouble(),
              height: safeHeight.toDouble(),
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: safeWidth.toDouble(),
                  height: safeHeight.toDouble(),
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: safeWidth.toDouble(),
                  height: safeHeight.toDouble(),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: borderRadius ?? BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Map unavailable',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (showLocationIcon)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(230),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(51),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.red[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class InteractiveStaticMapWidget extends StatelessWidget {
  final GeoPoint? coordinates;
  final String? locationName;
  final double width;
  final double height;
  final int zoom;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const InteractiveStaticMapWidget({
    super.key,
    required this.coordinates,
    this.locationName,
    this.width = 300,
    this.height = 200,
    this.zoom = 13,
    this.onTap,
    this.borderRadius,
  });

  // Compact variant for profile cards
  const InteractiveStaticMapWidget.compact({
    super.key,
    required this.coordinates,
    this.locationName,
    this.onTap,
  }) : width = 120,
       height = 80,
       zoom = 12,
       borderRadius = const BorderRadius.all(Radius.circular(8));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          border: Border.all(
            color: onTap != null ? Theme.of(context).primaryColor.withAlpha(77) : Colors.grey[300]!,
            width: onTap != null ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            StaticMapWidget(
              coordinates: coordinates,
              width: width,
              height: height,
              zoom: zoom,
              borderRadius: borderRadius,
              fallbackText: locationName != null ? 'Tap to set location\n$locationName' : null,
            ),
            if (onTap != null)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(179),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_location,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          locationName ?? 'Tap to edit location',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Compact map widget for user cards and quick location display
class CompactMapWidget extends StatelessWidget {
  final GeoPoint? coordinates;
  final String? locationText;
  final double size;
  final int zoom;
  final VoidCallback? onTap;

  const CompactMapWidget({
    super.key,
    required this.coordinates,
    this.locationText,
    this.size = 60,
    this.zoom = 11,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: coordinates != null
            ? Stack(
                children: [
                  Image.network(
                    LocationService.getStaticMapUrl(
                      coordinates!.latitude,
                      coordinates!.longitude,
                      width: size.toInt(),
                      height: size.toInt(),
                      zoom: zoom,
                    ),
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.map,
                          size: size * 0.4,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  ),
                  if (onTap != null)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(230),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.open_in_new,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              )
            : Container(
                color: Colors.grey[100],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_off,
                      size: size * 0.3,
                      color: Colors.grey[400],
                    ),
                    if (locationText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          locationText!,
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}