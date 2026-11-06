import 'package:naqsh_office/features/members/member.dart';

class FakeMemberRepository {
  List<Member> getMembers() {
    const relationTypes = ['S/O', 'D/O', 'W/O'];
    final members = <Member>[];

    for (var i = 1; i <= 20; i++) {
      final number = 1000 + i; // 1001 se 1020
      final label = i.toString().padLeft(2, '0');
      final relationType = relationTypes[(i - 1) % 3];

      // M-1016 se M-1018 Overseas, M-1019 aur M-1020 Inactive.
      final isOverseas = i >= 16 && i <= 18;
      final isActive = i <= 18;

      members.add(
        Member(
          id: 'member-$number',
          societyId: 'demo-city',
          memberNo: 'M-$number',
          fullName: 'Demo Member $label',
          relationType: relationType,
          relationName: relationType == 'W/O'
              ? 'Demo Husband $label'
              : 'Demo Father $label',
          cnic: '00000000${number}1',
          phone: isOverseas ? '+9715000$number' : '0300000$number',
          email: i <= 3 ? 'member$label@example.com' : '',
          address: 'House $i, Demo City',
          city: isOverseas ? 'Dubai' : 'Sahiwal',
          isOverseas: isOverseas,
          isActive: isActive,
          createdAt: DateTime(2026, 10, 1).add(Duration(days: i)),
        ),
      );
    }

    return members;
  }
}