class BloodRequest {
  BloodRequest({
    required this.id,
    required this.patientName,
    required this.bloodGroup,
    required this.hospital,
    required this.location,
    required this.contactNumber,
    required this.neededDate,
    required this.units,
    required this.status,
    required this.isOwner,
    required this.canModerate,
    this.notes = '',
  });

  final int id;
  final String patientName;
  final String bloodGroup;
  final String hospital;
  final String location;
  final String contactNumber;
  final DateTime neededDate;
  final int units;
  final String status;
  final bool isOwner;
  final bool canModerate;
  final String notes;

  factory BloodRequest.fromJson(Map<String, dynamic> json) => BloodRequest(
    id: json['id'] as int,
    patientName: json['patient_name'] as String,
    bloodGroup: json['blood_group'] as String,
    hospital: json['hospital'] as String,
    location: [
      json['subdistrict'],
      json['district'],
      json['division'],
    ].whereType<String>().where((value) => value.isNotEmpty).join(', '),
    contactNumber: json['contact_number'] as String,
    neededDate: DateTime.parse(json['needed_date'] as String),
    units: json['units'] as int,
    status: json['status'] as String,
    isOwner: json['is_owner'] as bool? ?? false,
    canModerate: json['can_moderate'] as bool? ?? false,
    notes: json['notes'] as String? ?? '',
  );
}
