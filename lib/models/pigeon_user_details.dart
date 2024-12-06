class PigeonUserDetails {
  final String? id;
  final String? name;
  final String? email;
  final String? address;
  final String? city;
  final String? phone;

  PigeonUserDetails({
    this.id,
    this.name,
    this.email,
    this.address,
    this.city,
    this.phone,
  });

  factory PigeonUserDetails.fromMap(String id, Map<String, dynamic> map) {
    return PigeonUserDetails(
      id: id,
      name: map['name'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      phone: map['phone'] as String?,
    );
  }
}
