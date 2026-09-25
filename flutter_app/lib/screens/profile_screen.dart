import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/location_fields.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _age = TextEditingController(),
      _contact = TextEditingController();
  Map<String, dynamic> _locations = {};
  String? _bloodGroup, _gender, _division, _district, _subdistrict;
  String _role = 'user';
  DateTime? _lastDonated;
  bool _available = true, _loading = true, _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = context.read<ApiService>();
      final values = await Future.wait([api.profile(), api.locations()]);
      final profile = values[0];
      _name.text = profile['name']?.toString() ?? '';
      _age.text = profile['age']?.toString() ?? '';
      _contact.text =
          profile['mobile_number']?.toString() ??
          profile['phone_number']?.toString() ??
          '';
      if (mounted) {
        setState(() {
          _locations = Map<String, dynamic>.from(values[1]);
          _bloodGroup = profile['blood_group'] as String?;
          _role = profile['role'] as String? ?? 'user';
          _gender = profile['gender'] as String?;
          _division = profile['division'] as String?;
          _district = profile['district'] as String?;
          _subdistrict = profile['subdistrict'] as String?;
          _lastDonated = DateTime.tryParse(
            profile['lastdonate']?.toString() ?? '',
          );
          _available = profile['is_available'] as bool? ?? true;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<ApiService>().saveProfile({
        'name': _name.text.trim(),
        'age': int.parse(_age.text),
        'mobile_number': _contact.text.trim(),
        'blood_group': _bloodGroup,
        'gender': _gender,
        'division': _division,
        'district': _district,
        'subdistrict': _subdistrict,
        'lastdonate': _lastDonated == null
            ? ''
            : DateFormat('yyyy-MM-dd').format(_lastDonated!),
        'is_available': _available,
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile saved')));
        await _load();
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.red, AppTheme.crimson],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        child: Icon(
                          _gender == 'male'
                              ? Icons.man_rounded
                              : _gender == 'female'
                              ? Icons.woman_rounded
                              : Icons.person_rounded,
                          size: 44,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _name.text.isEmpty
                                  ? 'Your donor profile'
                                  : _name.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _bloodGroup == null
                                  ? 'Complete your donor information'
                                  : 'Blood group $_bloodGroup',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _role.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const _SectionTitle(
                  icon: Icons.person_outline_rounded,
                  title: 'Personal details',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _age,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Age'),
                        validator: (value) {
                          final age = int.tryParse(value ?? '');
                          return age == null || age < 18 || age > 65
                              ? '18–65 only'
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: bloodGroups.contains(_bloodGroup)
                            ? _bloodGroup
                            : null,
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
                        onChanged: (value) =>
                            setState(() => _bloodGroup = value),
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue:
                      const ['male', 'female', 'other'].contains(_gender)
                      ? _gender
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(
                      value: 'other',
                      child: Text('Other / prefer not to say'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _gender = value),
                  validator: (value) => value == null ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contact,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 24),
                const _SectionTitle(
                  icon: Icons.volunteer_activism_outlined,
                  title: 'Donation status',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final value = await showDatePicker(
                      context: context,
                      firstDate: DateTime(1980),
                      lastDate: DateTime.now(),
                      initialDate: _lastDonated ?? DateTime.now(),
                    );
                    if (value != null) setState(() => _lastDonated = value);
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    _lastDonated == null
                        ? 'I have never donated'
                        : 'Last donated ${DateFormat.yMMMd().format(_lastDonated!)}',
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _lastDonated = null),
                  child: const Text('Clear donation date'),
                ),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  value: _available,
                  onChanged: (value) => setState(() => _available = value),
                  title: const Text('Available to donate'),
                  subtitle: const Text(
                    'Turn this off temporarily when unavailable',
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) =>
      (value?.trim().isEmpty ?? true) ? 'Required' : null;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: AppTheme.red),
      const SizedBox(width: 8),
      Text(
        title,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    ],
  );
}
