import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
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
  String? _bloodGroup, _gender, _division, _district, _subdistrict, _imageUrl;
  String _role = 'user';
  DateTime? _lastDonated;
  double? _latitude, _longitude;
  XFile? _image;
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
          _imageUrl = profile['image_url'] as String?;
          _lastDonated = DateTime.tryParse(
            profile['lastdonate']?.toString() ?? '',
          );
          _latitude = (profile['latitude'] as num?)?.toDouble();
          _longitude = (profile['longitude'] as num?)?.toDouble();
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

  Future<void> _useLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
    });
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
        if (_latitude != null) 'latitude': _latitude,
        if (_longitude != null) 'longitude': _longitude,
      }, image: _image);
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
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 58,
                        backgroundColor: const Color(0xFFFFDFDC),
                        backgroundImage: _imageUrl == null
                            ? null
                            : NetworkImage(_imageUrl!),
                        child: _imageUrl == null
                            ? const Icon(Icons.person, size: 58)
                            : null,
                      ),
                      Positioned(
                        right: -6,
                        bottom: -6,
                        child: IconButton.filled(
                          onPressed: () async {
                            final picked = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 82,
                              maxWidth: 1200,
                            );
                            if (picked != null) setState(() => _image = picked);
                          },
                          icon: const Icon(Icons.camera_alt_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_image != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Selected: ${_image!.name}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                Center(child: Chip(label: Text(_role.toUpperCase()))),
                const SizedBox(height: 24),
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
                  contentPadding: EdgeInsets.zero,
                  value: _available,
                  onChanged: (value) => setState(() => _available = value),
                  title: const Text('Available to donate'),
                  subtitle: const Text(
                    'Turn this off temporarily when unavailable',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _useLocation,
                  icon: const Icon(Icons.my_location),
                  label: Text(
                    _latitude == null
                        ? 'Use my precise location'
                        : 'Precise location added',
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
