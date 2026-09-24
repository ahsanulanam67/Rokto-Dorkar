import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokto_dorkar_app/models/donor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundles the complete Bangladesh location catalog', () async {
    final text = await rootBundle.loadString(
      'assets/data/bangladesh_locations.json',
    );
    final locations = Map<String, dynamic>.from(jsonDecode(text) as Map);
    expect(locations.length, 8);
    expect(
      locations.values.fold<int>(
        0,
        (total, districts) =>
            total + (districts as Map<String, dynamic>).length,
      ),
      64,
    );
    expect(
      locations.values.fold<int>(
        0,
        (total, districts) =>
            total +
            (districts as Map<String, dynamic>).values.fold<int>(
              0,
              (subtotal, upazilas) => subtotal + (upazilas as List).length,
            ),
      ),
      500,
    );
  });

  test('parses donor eligibility and distance from the API', () {
    final donor = Donor.fromJson({
      'id': 7,
      'name': 'A donor',
      'gender': 'male',
      'mobile_number': '01700000000',
      'blood_group': 'O+',
      'division': 'Dhaka',
      'district': 'Dhaka',
      'subdistrict': 'Savar',
      'eligible_to_donate': true,
      'is_available': true,
      'distance_km': 4.25,
    });

    expect(donor.eligible, isTrue);
    expect(donor.distanceKm, 4.25);
    expect(donor.bloodGroup, 'O+');
    expect(donor.gender, 'male');
  });
}
