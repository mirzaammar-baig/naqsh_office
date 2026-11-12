import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naqsh_office/features/members/member.dart';

// Firestore mein members parhne/likhne ka kaam yahin hota hai.
// Path: societies/demo-city/members
class FirestoreMemberRepository {
  FirestoreMemberRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  static const String societyId = 'demo-city';

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _members =>
      _db.collection('societies').doc(societyId).collection('members');

  // Live list: Firestore mein jab bhi badlao ho, app khud update hoti hai.
  Stream<List<Member>> watchMembers() {
    return _members.snapshots().map((snapshot) {
      final members = [
        for (final doc in snapshot.docs) _memberFromMap(doc.id, doc.data()),
      ];
      members.sort((a, b) => a.memberNo.compareTo(b.memberNo));
      return members;
    });
  }

  // Naya member bhi aur edit bhi (id wahi to purana document badal jata hai).
  Future<void> saveMember(Member member) {
    return _members.doc(member.id).set(_memberToMap(member));
  }

  // Deactivate / Activate: sirf isActive badalta hai. Delete nahi hota.
  Future<void> setActive(String id, bool value) {
    return _members.doc(id).update({'isActive': value});
  }

  // ---------- Member <-> Map ----------

  Map<String, dynamic> _memberToMap(Member member) {
    return {
      'societyId': member.societyId,
      'memberNo': member.memberNo,
      'fullName': member.fullName,
      'relationType': member.relationType,
      'relationName': member.relationName,
      'cnic': member.cnic,
      'phone': member.phone,
      'email': member.email,
      'address': member.address,
      'city': member.city,
      'isOverseas': member.isOverseas,
      'isActive': member.isActive,
      'createdAt': Timestamp.fromDate(member.createdAt),
    };
  }

  Member _memberFromMap(String id, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    return Member(
      id: id,
      societyId: (data['societyId'] as String?) ?? societyId,
      memberNo: (data['memberNo'] as String?) ?? '',
      fullName: (data['fullName'] as String?) ?? '',
      relationType: (data['relationType'] as String?) ?? 'S/O',
      relationName: (data['relationName'] as String?) ?? '',
      cnic: (data['cnic'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      city: (data['city'] as String?) ?? '',
      isOverseas: (data['isOverseas'] as bool?) ?? false,
      isActive: (data['isActive'] as bool?) ?? true,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }
}