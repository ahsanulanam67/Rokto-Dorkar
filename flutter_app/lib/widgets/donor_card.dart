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
                child: Icon(_avatarIcon, size: 42, color: AppTheme.red),
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
          Row(
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 19,
                color: Color(0xFF6B4D4A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  donor.mobileNumber.isEmpty
                      ? 'Phone number unavailable'
                      : donor.mobileNumber,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (donor.mobileNumber.isNotEmpty)
                IconButton.filledTonal(
                  onPressed: _call,
                  icon: const Icon(Icons.call_outlined),
                  tooltip: 'Call donor',
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoBadge(
                icon: donor.eligible
                    ? Icons.check_circle_rounded
                    : Icons.schedule_rounded,
                text: donor.eligible
                    ? 'Ready to donate'
                    : 'Available ${donor.nextAvailableDate == null ? 'later' : DateFormat.MMMd().format(donor.nextAvailableDate!)}',
                foreground: donor.eligible
                    ? const Color(0xFF207A45)
                    : const Color(0xFF8A5A12),
                background: donor.eligible
                    ? const Color(0xFFEAF7EF)
                    : const Color(0xFFFFF4DF),
              ),
              _InfoBadge(
                icon: donor.lastDonated == null
                    ? Icons.volunteer_activism_outlined
                    : Icons.history_rounded,
                text: donor.lastDonated == null
                    ? 'Never donated'
                    : 'Last donated ${DateFormat.yMMMd().format(donor.lastDonated!)}',
                foreground: const Color(0xFF6B4D4A),
                background: const Color(0xFFFFF2F0),
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

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.text,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String text;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: foreground),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
