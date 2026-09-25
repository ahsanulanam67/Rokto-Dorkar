class Donor {
  Donor({
    required this.id,
    required this.name,
    required this.gender,
    required this.mobileNumber,
    required this.bloodGroup,
    required this.division,
    required this.district,
    required this.subdistrict,
    required this.eligible,
    required this.available,
    this.age,
    this.lastDonated,
    this.nextAvailableDate,
    this.distanceKm,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String name;
  final String? gender;
  final int? age;
  final String mobileNumber;
  final String bloodGroup;
  final String division;
  final String district;
  final String subdistrict;
  final DateTime? lastDonated;
  final DateTime? nextAvailableDate;
  final double? distanceKm;
  final double? latitude;
  final double? longitude;
  final bool eligible;
  final bool available;

  factory Donor.fromJson(Map<String, dynamic> json) => Donor(
    id: json['id'] as int,
    name: json['name'] as String? ?? 'Anonymous donor',
    gender: json['gender'] as String?,
    age: json['age'] as int?,
    mobileNumber:
        json['mobile_number'] as String? ??
        json['phone_number'] as String? ??
        '',
    bloodGroup: json['blood_group'] as String? ?? '—',
    division: json['division'] as String? ?? '',
    district: json['district'] as String? ?? '',
    subdistrict: json['subdistrict'] as String? ?? '',
    lastDonated: DateTime.tryParse(json['lastdonate'] as String? ?? ''),
    nextAvailableDate: DateTime.tryParse(
      json['next_available_date'] as String? ?? '',
    ),
    distanceKm: (json['distance_km'] as num?)?.toDouble(),
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    eligible: json['eligible_to_donate'] as bool? ?? false,
    available: json['is_available'] as bool? ?? true,
  );
}
