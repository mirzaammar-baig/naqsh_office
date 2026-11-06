import 'package:naqsh_office/core/utils/input_validators.dart';

class Member {
  const Member({
    required this.id,
    required this.societyId,
    required this.memberNo,
    required this.fullName,
    required this.relationType,
    required this.relationName,
    required this.cnic,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    required this.isOverseas,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String societyId;
  final String memberNo;
  final String fullName;
  final String relationType;
  final String relationName;

  // CNIC dashes ke baghair 13 digits mein save hota hai.
  final String cnic;
  final String phone;

  // Khali string ka matlab: email nahi di.
  final String email;
  final String address;
  final String city;
  final bool isOverseas;
  final bool isActive;
  final DateTime createdAt;

  // Screen par dikhane ke helpers.
  String get cnicText => formatCnic(cnic);

  // 0000000010011 ko *****-****001-1 banata hai (sirf aakhri 4 digits nazar aate hain).
  String get maskedCnic {
    if (cnic.length != 13) {
      return '*****-*******-*';
    }
    return '*****-****${cnic.substring(9, 12)}-${cnic.substring(12)}';
  }

  String get relationText => '$relationType $relationName';

  String get statusText => isActive ? 'Active' : 'Inactive';

  String get typeText => isOverseas ? 'Overseas' : 'Local';

  String get initial => fullName.isEmpty ? '?' : fullName[0].toUpperCase();

  // id, societyId, memberNo, cnic aur createdAt locked hain, is liye
  // copyWith mein nahi hain.
  Member copyWith({
    String? fullName,
    String? relationType,
    String? relationName,
    String? phone,
    String? email,
    String? address,
    String? city,
    bool? isOverseas,
    bool? isActive,
  }) {
    return Member(
      id: id,
      societyId: societyId,
      memberNo: memberNo,
      fullName: fullName ?? this.fullName,
      relationType: relationType ?? this.relationType,
      relationName: relationName ?? this.relationName,
      cnic: cnic,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      isOverseas: isOverseas ?? this.isOverseas,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}