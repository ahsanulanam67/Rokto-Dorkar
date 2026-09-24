import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../models/donor.dart';

class DonorCard extends StatelessWidget {
  const DonorCard({super.key, required this.donor, this.onToggleAvailability});
  final Donor donor;
  final Future<void> Function()? onToggleAvailability;

  IconData get _avatarIcon => switch (donor.gender) {
    'male' => Icons.man_rounded,
    'female' => Icons.woman_rounded,
    _ => Icons.person_rounded,
  };

  Future<void> _call() =>
      launchUrl(Uri(scheme: 'tel', path: donor.mobileNumber));
  Future<void> _map() {
    final query = donor.latitude != null
        ? '${donor.latitude},${donor.longitude}'
        : '${donor.subdistrict}, ${donor.district}, Bangladesh';
    return launchUrl(
      Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': query,
      }),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 31,
                backgroundColor: const Color(0xFFFFE1DE),
                child: ClipOval(
                  child: donor.imageUrl == null
                      ? Icon(_avatarIcon, size: 42, color: AppTheme.red)
                      : Image.network(
                          donor.imageUrl!,
                          width: 62,
                          height: 62,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              Icon(_avatarIcon, size: 42, color: AppTheme.red),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donor.name,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${donor.bloodGroup}${donor.age == null ? '' : '  •  Age ${donor.age}'}',
                      style: const TextStyle(
                        color: AppTheme.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      [
                        donor.subdistrict,
                        donor.district,
                      ].where((value) => value.isNotEmpty).join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (donor.distanceKm != null)
                Chip(label: Text('${donor.distanceKm} km')),
            ],
          ),
          const Divider(height: 26),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: Icon(
                  donor.eligible ? Icons.check_circle : Icons.schedule,
                  size: 18,
                ),
                label: Text(
                  donor.eligible
                      ? 'Eligible now'
                      : 'Available ${donor.nextAvailableDate == null ? 'later' : DateFormat.MMMd().format(donor.nextAvailableDate!)}',
                ),
              ),
              Chip(
                avatar: Icon(
                  donor.lastDonated == null
                      ? Icons.volunteer_activism_outlined
                      : Icons.history,
                  size: 18,
                ),
                label: Text(
                  donor.lastDonated == null
                      ? 'Never donated'
                      : 'Last donated ${DateFormat.yMMMd().format(donor.lastDonated!)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: donor.mobileNumber.isEmpty ? null : _call,
                  icon: const Icon(Icons.call),
                  label: const Text('Call donor'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: _map,
                icon: const Icon(Icons.map_outlined),
                tooltip: 'Open location',
              ),
            ],
          ),
          if (onToggleAvailability != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onToggleAvailability,
              icon: Icon(
                donor.available
                    ? Icons.person_off_outlined
                    : Icons.person_add_alt,
              ),
              label: Text(
                donor.available
                    ? 'Moderator: hide donor'
                    : 'Moderator: restore donor',
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
