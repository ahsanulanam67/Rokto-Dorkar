import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../models/donor.dart';

class DonorCard extends StatelessWidget {
  const DonorCard({super.key, required this.donor, this.onToggleAvailability});
  final Donor donor;
  final Future<void> Function()? onToggleAvailability;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Blood group badge
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppTheme.gradientHeader,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.red.withAlpha(60),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  donor.bloodGroup,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: -0.5,
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
                    if (donor.age != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Age ${donor.age}',
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppTheme.muted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            [
                              donor.subdistrict,
                              donor.district,
                            ].where((v) => v.isNotEmpty).join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (donor.distanceKm != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0EE),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFCDD2)),
                      ),
                      child: Text(
                        '${donor.distanceKm} km',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.red,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: donor.eligible
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFF57C00),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Status badges row
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
                    ? const Color(0xFF1B6B3A)
                    : const Color(0xFF7A4F10),
                background: donor.eligible
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFF8E1),
              ),
              _InfoBadge(
                icon: donor.lastDonated == null
                    ? Icons.volunteer_activism_outlined
                    : Icons.history_rounded,
                text: donor.lastDonated == null
                    ? 'Never donated'
                    : 'Last: ${DateFormat.MMMd().format(donor.lastDonated!)}',
                foreground: const Color(0xFF6B4D4A),
                background: const Color(0xFFFFF2F0),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Contact row
          Row(
            children: [
              Expanded(
                child: donor.mobileNumber.isEmpty
                    ? const Text(
                        'Phone number unavailable',
                        style: TextStyle(color: AppTheme.muted, fontSize: 13),
                      )
                    : Tooltip(
                        message: 'Call donor',
                        child: FilledButton.icon(
                          onPressed: _call,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            backgroundColor: AppTheme.red,
                          ),
                          icon: const Icon(Icons.call_rounded, size: 18),
                          label: Text(
                            donor.mobileNumber,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
              ),
              if (onToggleAvailability != null) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onToggleAvailability,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: Icon(
                    donor.available
                        ? Icons.person_off_outlined
                        : Icons.person_add_alt,
                    size: 18,
                  ),
                  label: Text(donor.available ? 'Hide' : 'Restore'),
                ),
              ],
            ],
          ),
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
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: foreground),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
