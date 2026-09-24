import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';
import '../widgets/location_fields.dart';

class ManagementScreen extends StatelessWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthState>().role == 'admin';
    final tabs = <Tab>[
      const Tab(icon: Icon(Icons.person_add_alt), text: 'Add donor'),
      if (isAdmin)
        const Tab(icon: Icon(Icons.content_copy), text: 'Duplicates'),
      if (isAdmin) const Tab(icon: Icon(Icons.manage_accounts), text: 'Roles'),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          TabBar(isScrollable: isAdmin, tabs: tabs),
          Expanded(
            child: TabBarView(
              children: [
                const _ManualDonorForm(),
                if (isAdmin) const _DuplicateAlerts(),
                if (isAdmin) const _UserRoles(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualDonorForm extends StatefulWidget {
  const _ManualDonorForm();

  @override
  State<_ManualDonorForm> createState() => _ManualDonorFormState();
}

class _ManualDonorFormState extends State<_ManualDonorForm> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _age = TextEditingController();
  Map<String, dynamic> _locations = {};
  String? _gender, _bloodGroup, _division, _district, _subdistrict;
  DateTime? _lastDonated;
  bool _saving = false;
  bool _requestedLocations = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requestedLocations) {
      _requestedLocations = true;
      _loadLocations();
    }
  }

  Future<void> _loadLocations() async {
    final values = await context.read<ApiService>().locations();
    if (mounted) setState(() => _locations = values);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    if (_division == null || _district == null || _subdistrict == null) {
      _message('Choose the donor location.');
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<ApiService>().createManualDonor({
        'name': _name.text.trim(),
        'mobile_number': _phone.text.trim(),
        if (_age.text.trim().isNotEmpty) 'age': int.parse(_age.text),
        'gender': _gender,
        'blood_group': _bloodGroup,
        'division': _division,
        'district': _district,
        'subdistrict': _subdistrict,
        'lastdonate': _lastDonated == null
            ? null
            : DateFormat('yyyy-MM-dd').format(_lastDonated!),
        'is_available': true,
      });
      _key.currentState!.reset();
      _name.clear();
      _phone.clear();
      _age.clear();
      setState(() {
        _gender = _bloodGroup = _division = _district = _subdistrict = null;
        _lastDonated = null;
      });
      _message('Donor added.');
    } on ApiException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String value) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Form(
          key: _key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add a donor without an account',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text(
                'If this person registers later, their phone number will create an admin duplicate alert.',
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  hintText: '01XXXXXXXXX',
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _age,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age (optional)'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final age = int.tryParse(value);
                  return age == null || age < 18 || age > 65
                      ? '18–65 only'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _bloodGroup,
                      decoration: const InputDecoration(
                        labelText: 'Blood group',
                      ),
                      items: bloodGroups
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _bloodGroup = value),
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) => setState(() => _gender = value),
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_locations.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                LocationFields(
                  locations: _locations,
                  division: _division,
                  district: _district,
                  subdistrict: _subdistrict,
                  onDivisionChanged: (value) => setState(() {
                    _division = value;
                    _district = _subdistrict = null;
                  }),
                  onDistrictChanged: (value) => setState(() {
                    _district = value;
                    _subdistrict = null;
                  }),
                  onSubdistrictChanged: (value) =>
                      setState(() => _subdistrict = value),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime(1980),
                    lastDate: DateTime.now(),
                    initialDate: _lastDonated ?? DateTime.now(),
                  );
                  if (date != null) setState(() => _lastDonated = date);
                },
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  _lastDonated == null
                      ? 'Never donated'
                      : 'Last donated ${DateFormat.yMMMd().format(_lastDonated!)}',
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.person_add_alt),
                label: Text(_saving ? 'Adding…' : 'Add donor'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  String? _required(String? value) =>
      value?.trim().isEmpty ?? true ? 'Required' : null;
}

class _DuplicateAlerts extends StatefulWidget {
  const _DuplicateAlerts();

  @override
  State<_DuplicateAlerts> createState() => _DuplicateAlertsState();
}

class _DuplicateAlertsState extends State<_DuplicateAlerts> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() =>
      context.read<ApiService>().duplicateAlerts();

  Future<void> _resolve(int id, String resolution) async {
    await context.read<ApiService>().resolveDuplicate(id, resolution);
    setState(() => _future = _load());
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text(snapshot.error.toString()));
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final alerts = snapshot.data!;
      if (alerts.isEmpty) {
        return const Center(child: Text('No duplicate donors need review.'));
      }
      return RefreshIndicator(
        onRefresh: () async => setState(() => _future = _load()),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            final registered = Map<String, dynamic>.from(
              alert['registered_donor'] as Map,
            );
            final manual = Map<String, dynamic>.from(
              alert['manual_donor'] as Map,
            );
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Matching phone: ${alert['normalized_phone']}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Registered: ${registered['name']} (${registered['email']})',
                    ),
                    Text(
                      'Added manually: ${manual['name']} by ${manual['created_by_email'] ?? 'a moderator'}',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton.tonal(
                          onPressed: () =>
                              _resolve(alert['id'] as int, 'delete_manual'),
                          child: const Text('Delete manual record'),
                        ),
                        TextButton(
                          onPressed: () =>
                              _resolve(alert['id'] as int, 'dismiss'),
                          child: const Text('Not a duplicate'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

class _UserRoles extends StatefulWidget {
  const _UserRoles();

  @override
  State<_UserRoles> createState() => _UserRolesState();
}

class _UserRolesState extends State<_UserRoles> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() =>
      context.read<ApiService>().adminUsers();

  Future<void> _setRole(int id, String role) async {
    await context.read<ApiService>().updateUserRole(id, role);
    setState(() => _future = _load());
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text(snapshot.error.toString()));
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: snapshot.data!.map((user) {
          final role = user['role'] as String? ?? 'user';
          return Card(
            child: ListTile(
              title: Text(user['name']?.toString() ?? user['email'].toString()),
              subtitle: Text('${user['email']}\n${user['phone_number'] ?? ''}'),
              isThreeLine: true,
              trailing: role == 'admin'
                  ? const Chip(label: Text('ADMIN'))
                  : DropdownButton<String>(
                      value: role,
                      items: const [
                        DropdownMenuItem(value: 'user', child: Text('User')),
                        DropdownMenuItem(
                          value: 'moderator',
                          child: Text('Moderator'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) _setRole(user['id'] as int, value);
                      },
                    ),
            ),
          );
        }).toList(),
      );
    },
  );
}
