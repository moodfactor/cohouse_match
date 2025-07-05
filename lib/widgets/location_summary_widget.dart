import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cohouse_match/widgets/static_map_widget.dart';

class LocationSummaryWidget extends StatelessWidget {
  final GeoPoint? coordinates;
  final String? locationName;
  final double? distance;
  final bool showMap;
  final bool showDistance;
  final VoidCallback? onTap;

  const LocationSummaryWidget({
    super.key,
    required this.coordinates,
    this.locationName,
    this.distance,
    this.showMap = true,
    this.showDistance = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            if (showMap) ...[
              CompactMapWidget(
                coordinates: coordinates,
                locationText: locationName,
                size: 50,
                onTap: onTap,
              ),
              const SizedBox(width: 12),
            ],
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (locationName != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            locationName!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  
                  if (showDistance && distance != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.near_me,
                          size: 14,
                          color: Colors.blue[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${distance!.toStringAsFixed(1)} miles away',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  if (coordinates == null && locationName == null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Location not set',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }
}

// Minimal location indicator for tight spaces
class LocationIndicator extends StatelessWidget {
  final String? locationName;
  final double? distance;
  final IconData icon;
  final Color? color;

  const LocationIndicator({
    super.key,
    this.locationName,
    this.distance,
    this.icon = Icons.location_on,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? Colors.grey[600];
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: displayColor,
        ),
        const SizedBox(width: 4),
        if (distance != null)
          Text(
            '${distance!.toStringAsFixed(1)}mi',
            style: TextStyle(
              fontSize: 12,
              color: displayColor,
              fontWeight: FontWeight.w500,
            ),
          )
        else if (locationName != null)
          Flexible(
            child: Text(
              locationName!,
              style: TextStyle(
                fontSize: 12,
                color: displayColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          )
        else
          Text(
            'No location',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }
}