import 'package:flutter/material.dart';
import 'package:cohouse_match/models/user.dart';
import 'package:cohouse_match/widgets/static_map_widget.dart';
import 'package:cohouse_match/services/location_service.dart';

class UserCardWithMap extends StatelessWidget {
  final UserData user;
  final VoidCallback? onTap;
  final VoidCallback? onMapTap;

  const UserCardWithMap({
    super.key,
    required this.user,
    this.onTap,
    this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile photo
              CircleAvatar(
                radius: 30,
                backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
                child: user.photoUrl == null
                  ? const Icon(Icons.person, size: 30)
                  : null,
              ),
              const SizedBox(width: 16),
              
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? 'Unknown',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (user.age != null)
                      Text(
                        '${user.age} years old',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    if (user.budget != null)
                      Text(
                        '\$${user.budget!.toStringAsFixed(0)}/month',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (user.location != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.location!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Compact map
              CompactMapWidget(
                coordinates: LocationService.getDisplayLocation(user),
                locationText: user.location,
                size: 70,
                onTap: onMapTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}