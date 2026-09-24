import 'package:flutter_test/flutter_test.dart';
import 'package:rokto_dorkar_app/models/donor.dart';

void main() {
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
