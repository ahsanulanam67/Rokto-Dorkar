import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../core/theme.dart';
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
                  itemBuilder: (_, index) =>
                      _RequestCard(item: _items[index], onFulfill: _fulfill),
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

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.item, required this.onFulfill});
  final BloodRequest item;
  final Future<void> Function(BloodRequest) onFulfill;

  // today = critical (red), tomorrow = urgent (orange), later = normal
  _UrgencyLevel get _urgency {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final needed = DateTime(item.neededDate.year, item.neededDate.month, item.neededDate.day);
    final diff = needed.difference(today).inDays;
    if (diff <= 0) return _UrgencyLevel.critical;
    if (diff == 1) return _UrgencyLevel.urgent;
    return _UrgencyLevel.normal;
  }

  @override
  Widget build(BuildContext context) {
    final u = _urgency;
    final isFulfilled = item.status == 'fulfilled';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: BorderSide(color: u.accentColor, width: 4),
          top: BorderSide(color: const Color(0xFFF0DADA)),
          right: BorderSide(color: const Color(0xFFF0DADA)),
          bottom: BorderSide(color: const Color(0xFFF0DADA)),
        ),
      ),
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
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: isFulfilled
                        ? const LinearGradient(colors: [Color(0xFF9E9E9E), Color(0xFF757575)])
                        : AppTheme.gradientHeader,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.bloodGroup,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.patientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item.units} unit${item.units == 1 ? '' : 's'}  ·  ${item.hospital}',
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status + urgency badges
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isFulfilled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: u.badgeBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          u.label,
                          style: TextStyle(
                            color: u.accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Fulfilled',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Location + date row
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.muted),
                const SizedBox(width: 4),
                Text(
                  DateFormat.MMMd().format(item.neededDate),
                  style: TextStyle(
                    color: u.accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (item.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.notes,
                style: const TextStyle(color: AppTheme.muted, fontSize: 13),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => launchUrl(Uri(scheme: 'tel', path: item.contactNumber)),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      backgroundColor: isFulfilled
                          ? const Color(0xFF9E9E9E)
                          : AppTheme.red,
                    ),
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: const Text('Contact'),
                  ),
                ),
                if ((item.isOwner || item.canModerate) && item.status == 'open') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onFulfill(item),
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
  }
}

enum _UrgencyLevel { critical, urgent, normal }

extension _UrgencyStyle on _UrgencyLevel {
  Color get accentColor => switch (this) {
    _UrgencyLevel.critical => const Color(0xFFC62828),
    _UrgencyLevel.urgent   => const Color(0xFFE65100),
    _UrgencyLevel.normal   => const Color(0xFF1565C0),
  };
  Color get badgeBg => switch (this) {
    _UrgencyLevel.critical => const Color(0xFFFFEBEE),
    _UrgencyLevel.urgent   => const Color(0xFFFFF3E0),
    _UrgencyLevel.normal   => const Color(0xFFE3F2FD),
  };
  String get label => switch (this) {
    _UrgencyLevel.critical => 'Critical',
    _UrgencyLevel.urgent   => 'Urgent',
    _UrgencyLevel.normal   => 'Open',
  };
}
