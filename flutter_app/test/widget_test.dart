import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokto_dorkar_app/core/theme.dart';
import 'package:rokto_dorkar_app/models/donor.dart';
import 'package:rokto_dorkar_app/widgets/donor_card.dart';

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

  testWidgets('donor card lays out on a narrow mobile screen', (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final donor = Donor(
      id: 1,
      name: 'Demo Donor With A Long Name',
      gender: 'female',
      age: 28,
      mobileNumber: '01000000001',
      bloodGroup: 'AB+',
      division: 'Chattogram',
      district: "Cox's Bazar",
      subdistrict: "Cox's Bazar Sadar",
      eligible: false,
      available: true,
      lastDonated: DateTime(2026, 9, 1),
      nextAvailableDate: DateTime(2026, 12, 30),
      distanceKm: 100,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(child: DonorCard(donor: donor)),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Call donor'), findsOneWidget);
  });
}
