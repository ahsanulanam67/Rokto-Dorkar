import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme.dart';
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
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Only eligible and available donors'),
                  value: eligible,
                  onChanged: (value) => setSheetState(() => eligible = value),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () async {
                    _filters = <String, dynamic>{
                      'eligible_only': eligible.toString(),
                      'blood_group': ?group,
                      'division': ?division,
                      'district': ?district,
                      'subdistrict': ?subdistrict,
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

  bool get _hasVisibleFilters =>
      _filters['blood_group'] != null || _selectedLocation != null;

  String? get _selectedLocation {
    final parts = [
      _filters['subdistrict'],
      _filters['district'],
      _filters['division'],
    ].whereType<String>().where((value) => value != 'ALL').toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  Future<void> _removeBloodFilter() async {
    _filters.remove('blood_group');
    await _load();
  }

  Future<void> _removeLocationFilter() async {
    _filters.remove('division');
    _filters.remove('district');
    _filters.remove('subdistrict');
    await _load();
  }

  Future<void> _clearVisibleFilters() async {
    _filters = {'eligible_only': _filters['eligible_only'] ?? 'true'};
    await _load();
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
        if (!_loading && _error == null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(
                    _donors.isEmpty
                        ? 'No donors found'
                        : '${_donors.length} donor${_donors.length == 1 ? '' : 's'} found',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _donors.isEmpty
                          ? Colors.grey
                          : AppTheme.red,
                    ),
                  ),
                  if (_filters['eligible_only'] != 'false') ...[
                    const SizedBox(width: 6),
                    const Text(
                      '· eligible only',
                      style: TextStyle(fontSize: 12, color: AppTheme.muted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (_hasVisibleFilters)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (_filters['blood_group'] case final String group)
                    InputChip(
                      avatar: const Icon(Icons.bloodtype_outlined, size: 18),
                      label: Text('Blood: $group'),
                      onDeleted: _removeBloodFilter,
                    ),
                  if (_selectedLocation case final String location)
                    InputChip(
                      avatar: const Icon(Icons.location_on_outlined, size: 18),
                      label: Text(location),
                      onDeleted: _removeLocationFilter,
                    ),
                  TextButton(
                    onPressed: _clearVisibleFilters,
                    child: const Text('Clear all'),
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
