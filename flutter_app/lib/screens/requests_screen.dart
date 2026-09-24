import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../models/blood_request.dart';
import '../services/api_service.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});
  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  List<BloodRequest> _items = [];
  bool _loading = true, _mine = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final values = await context.read<ApiService>().requests(mine: _mine);
      if (mounted) {
        setState(() {
          _items = values;
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

  Future<void> _create() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _RequestForm(),
    );
    if (result == null || !mounted) return;
    try {
      await context.read<ApiService>().createRequest(result);
      await _load();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _fulfill(BloodRequest item) async {
    await context.read<ApiService>().setRequestStatus(item.id, 'fulfilled');
    await _load();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Open requests')),
                    ButtonSegment(value: true, label: Text('My requests')),
                  ],
                  selected: {_mine},
                  onSelectionChanged: (value) {
                    _mine = value.first;
                    _load();
                  },
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_items.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('No blood requests here yet.')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                sliver: SliverList.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final item = _items[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  child: Text(
                                    item.bloodGroup,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.patientName,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${item.units} unit${item.units == 1 ? '' : 's'} • ${DateFormat.yMMMd().format(item.neededDate)}',
                                      ),
                                    ],
                                  ),
                                ),
                                Chip(label: Text(item.status)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.hospital,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(item.location),
                            if (item.notes.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(item.notes),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.tonalIcon(
                                    onPressed: () => launchUrl(
                                      Uri(
                                        scheme: 'tel',
                                        path: item.contactNumber,
                                      ),
                                    ),
                                    icon: const Icon(Icons.call),
                                    label: const Text('Contact'),
                                  ),
                                ),
                                if ((item.isOwner || item.canModerate) &&
                                    item.status == 'open') ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _fulfill(item),
                                      child: const Text('Mark fulfilled'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      Positioned(
        right: 18,
        bottom: 18,
        child: FloatingActionButton.extended(
          onPressed: _create,
          icon: const Icon(Icons.add),
          label: const Text('Request blood'),
        ),
      ),
    ],
  );
}

class _RequestForm extends StatefulWidget {
  const _RequestForm();
  @override
  State<_RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends State<_RequestForm> {
  final _key = GlobalKey<FormState>();
  final _patient = TextEditingController(),
      _hospital = TextEditingController(),
      _division = TextEditingController(),
      _district = TextEditingController(),
      _subdistrict = TextEditingController(),
      _contact = TextEditingController(),
      _notes = TextEditingController();
  String? _group;
  DateTime _date = DateTime.now();
  int _units = 1;

  @override
  void dispose() {
    for (final controller in [
      _patient,
      _hospital,
      _division,
      _district,
      _subdistrict,
      _contact,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      (value?.trim().isEmpty ?? true) ? 'Required' : null;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: _key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Request blood',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _patient,
              decoration: const InputDecoration(labelText: 'Patient name'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _group,
                    decoration: const InputDecoration(labelText: 'Blood group'),
                    items: bloodGroups
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _group = value),
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _units,
                    decoration: const InputDecoration(labelText: 'Units'),
                    items: List.generate(
                      10,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text('${i + 1}'),
                      ),
                    ),
                    onChanged: (value) => setState(() => _units = value ?? 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _hospital,
              decoration: const InputDecoration(labelText: 'Hospital'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _division,
              decoration: const InputDecoration(labelText: 'Division'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _district,
              decoration: const InputDecoration(labelText: 'District'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _subdistrict,
              decoration: const InputDecoration(
                labelText: 'Upazila / subdistrict',
              ),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _contact,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Contact number'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final value = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDate: _date,
                );
                if (value != null) setState(() => _date = value);
              },
              icon: const Icon(Icons.calendar_month),
              label: Text('Needed ${DateFormat.yMMMd().format(_date)}'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                if (!_key.currentState!.validate()) return;
                Navigator.pop(context, {
                  'patient_name': _patient.text.trim(),
                  'blood_group': _group,
                  'hospital': _hospital.text.trim(),
                  'division': _division.text.trim(),
                  'district': _district.text.trim(),
                  'subdistrict': _subdistrict.text.trim(),
                  'contact_number': _contact.text.trim(),
                  'needed_date': DateFormat('yyyy-MM-dd').format(_date),
                  'units': _units,
                  'notes': _notes.text.trim(),
                });
              },
              child: const Text('Publish request'),
            ),
          ],
        ),
      ),
    ),
  );
}
