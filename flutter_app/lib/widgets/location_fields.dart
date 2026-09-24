import 'package:flutter/material.dart';

class LocationFields extends StatelessWidget {
  const LocationFields({
    super.key,
    required this.locations,
    required this.division,
    required this.district,
    required this.subdistrict,
    required this.onDivisionChanged,
    required this.onDistrictChanged,
    required this.onSubdistrictChanged,
    this.allowAll = false,
  });

  final Map<String, dynamic> locations;
  final String? division, district, subdistrict;
  final ValueChanged<String?> onDivisionChanged,
      onDistrictChanged,
      onSubdistrictChanged;
  final bool allowAll;

  @override
  Widget build(BuildContext context) {
    final divisions = locations.keys
        .where((value) => value.trim().isNotEmpty)
        .toList();
    if (allowAll) divisions.insert(0, 'ALL');
    final validDivision = divisions.contains(division) ? division : null;
    final districtMap = validDivision == null || validDivision == 'ALL'
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(locations[validDivision] as Map);
    final districts = districtMap.keys
        .where((value) => value.trim().isNotEmpty)
        .toList();
    if (allowAll) districts.insert(0, 'ALL');
    final validDistrict = districts.contains(district) ? district : null;
    final subdistricts = validDistrict == null || validDistrict == 'ALL'
        ? <String>[]
        : List<String>.from(districtMap[validDistrict] as List)
              .where((value) => value.trim().isNotEmpty)
              .toList();
    if (allowAll) subdistricts.insert(0, 'ALL');
    final validSubdistrict = subdistricts.contains(subdistrict)
        ? subdistrict
        : null;
    return Column(
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('division-$validDivision-${divisions.length}'),
          initialValue: validDivision,
          decoration: const InputDecoration(labelText: 'Division'),
          items: [
            ...divisions.map(
              (value) => DropdownMenuItem(value: value, child: Text(value)),
            ),
          ],
          onChanged: onDivisionChanged,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('district-$validDistrict-${districts.length}'),
          initialValue: validDistrict,
          decoration: const InputDecoration(labelText: 'District'),
          items: [
            ...districts.map(
              (value) => DropdownMenuItem(value: value, child: Text(value)),
            ),
          ],
          onChanged: validDivision == null || validDivision == 'ALL'
              ? null
              : onDistrictChanged,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('subdistrict-$validSubdistrict-${subdistricts.length}'),
          initialValue: validSubdistrict,
          decoration: const InputDecoration(labelText: 'Upazila / subdistrict'),
          items: [
            ...subdistricts.map(
              (value) => DropdownMenuItem(value: value, child: Text(value)),
            ),
          ],
          onChanged: validDistrict == null || validDistrict == 'ALL'
              ? null
              : onSubdistrictChanged,
        ),
      ],
    );
  }
}
