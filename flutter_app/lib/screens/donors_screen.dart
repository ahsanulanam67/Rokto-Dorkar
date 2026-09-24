import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../models/donor.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';
import '../widgets/donor_card.dart';
import '../widgets/location_fields.dart';

class DonorsScreen extends StatefulWidget {
  const DonorsScreen({super.key});
  @override
  State<DonorsScreen> createState() => _DonorsScreenState();
}

class _DonorsScreenState extends State<DonorsScreen> {
  List<Donor> _donors = [];
  Map<String, dynamic> _locations = {};
  Map<String, dynamic> _filters = {'eligible_only': 'true'};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final api = context.read<ApiService>();
    try {
      final values = await Future.wait([api.locations(), api.donors(_filters)]);
      if (mounted) {
        setState(() {
          _locations = values[0] as Map<String, dynamic>;
          _donors = values[1] as List<Donor>;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await context.read<ApiService>().donors(_filters);
      if (mounted) {
        setState(() {
          _donors = result;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<Position?> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Turn on location services first.')),
        );
      }
      return null;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is needed for nearby donors.'),
          ),
        );
      }
      return null;
    }
    return Geolocator.getCurrentPosition();
  }

  Future<void> _toggleAvailability(Donor donor) async {
    try {
      await context.read<ApiService>().setDonorAvailability(
        donor.id,
        !donor.available,
      );
      await _load();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _showFilters() async {
    String? group = _filters['blood_group'] as String?;
    String? division = _filters['division'] as String?;
    String? district = _filters['district'] as String?;
    String? subdistrict = _filters['subdistrict'] as String?;
    bool eligible = _filters['eligible_only'] != 'false';
    int? radiusKm = (_filters['radius_km'] as num?)?.round();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Search filters',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: group,
                  decoration: const InputDecoration(labelText: 'Blood group'),
                  items: bloodGroups
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => setSheetState(() => group = value),
                ),
                const SizedBox(height: 12),
                LocationFields(
                  locations: _locations,
                  division: division,
                  district: district,
                  subdistrict: subdistrict,
                  allowAll: true,
                  onDivisionChanged: (value) => setSheetState(() {
                    division = value;
                    district = subdistrict = null;
                  }),
                  onDistrictChanged: (value) => setSheetState(() {
                    district = value;
                    subdistrict = null;
                  }),
                  onSubdistrictChanged: (value) =>
                      setSheetState(() => subdistrict = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: radiusKm ?? 0,
                  decoration: const InputDecoration(
                    labelText: 'Distance from me',
                    prefixIcon: Icon(Icons.near_me_outlined),
                    helperText: 'Uses your current location when selected',
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Any distance')),
                    DropdownMenuItem(value: 5, child: Text('Within 5 km')),
                    DropdownMenuItem(value: 10, child: Text('Within 10 km')),
                    DropdownMenuItem(value: 20, child: Text('Within 20 km')),
                    DropdownMenuItem(value: 30, child: Text('Within 30 km')),
                    DropdownMenuItem(value: 50, child: Text('Within 50 km')),
                    DropdownMenuItem(value: 100, child: Text('Within 100 km')),
                  ],
                  onChanged: (value) =>
                      setSheetState(() => radiusKm = value == 0 ? null : value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Only eligible and available donors'),
                  value: eligible,
                  onChanged: (value) => setSheetState(() => eligible = value),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () async {
                    final position = radiusKm == null
                        ? null
                        : await _currentPosition();
                    if (radiusKm != null && position == null) return;
                    _filters = <String, dynamic>{
                      'eligible_only': eligible.toString(),
                      'blood_group': ?group,
                      'division': ?division,
                      'district': ?district,
                      'subdistrict': ?subdistrict,
                      if (position != null) ...{
                        'latitude': position.latitude,
                        'longitude': position.longitude,
                        'radius_km': radiusKm,
                      },
                    };
                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                    await _load();
                  },
                  child: const Text('Search'),
                ),
                TextButton(
                  onPressed: () {
                    _filters = {'eligible_only': 'true'};
                    Navigator.pop(sheetContext);
                    _load();
                  },
                  child: const Text('Clear filters'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _load,
    child: CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _showFilters,
                    icon: const Icon(Icons.manage_search_rounded),
                    label: const Text('Search and filter donors'),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_loading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          SliverFillRemaining(
            child: _Message(
              icon: Icons.cloud_off,
              text: _error!,
              action: _load,
            ),
          )
        else if (_donors.isEmpty)
          SliverFillRemaining(
            child: _Message(
              icon: Icons.search_off,
              text: 'No eligible donors matched this search.',
              action: _showFilters,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            sliver: SliverList.separated(
              itemCount: _donors.length,
              itemBuilder: (_, index) => DonorCard(
                donor: _donors[index],
                onToggleAvailability: context.read<AuthState>().canModerate
                    ? () => _toggleAvailability(_donors[index])
                    : null,
              ),
              separatorBuilder: (_, _) => const SizedBox(height: 10),
            ),
          ),
      ],
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    required this.action,
  });
  final IconData icon;
  final String text;
  final VoidCallback action;
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      const SizedBox(height: 100),
      Icon(icon, size: 64),
      const SizedBox(height: 12),
      Text(text, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Center(
        child: TextButton(onPressed: action, child: const Text('Try again')),
      ),
    ],
  );
}
