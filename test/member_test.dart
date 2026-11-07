import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naqsh_office/features/members/fake_member_repository.dart';
import 'package:naqsh_office/features/members/members_notifier.dart';

void main() {
  group('Fake members', () {
    final members = FakeMemberRepository().getMembers();

    test('20 members: 18 active, 2 inactive, 3 overseas', () {
      expect(members.length, 20);
      expect(members.where((m) => m.isActive).length, 18);
      expect(members.where((m) => !m.isActive).length, 2);
      expect(members.where((m) => m.isOverseas).length, 3);
    });

    test('M-1001 has the expected data', () {
      final first = members.first;
      expect(first.memberNo, 'M-1001');
      expect(first.cnic, '0000000010011');
      expect(first.phone, '03000001001');
    });

    test('CNIC is masked and formatted correctly', () {
      final first = members.first;
      expect(first.maskedCnic, '*****-****001-1');
      expect(first.cnicText, '00000-0001001-1');
    });

    test('copyWith keeps Member No and CNIC', () {
      final updated = members.first.copyWith(fullName: 'New Name');
      expect(updated.fullName, 'New Name');
      expect(updated.memberNo, 'M-1001');
      expect(updated.cnic, '0000000010011');
    });
  });

  group('MembersNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('next Member No is M-1021', () {
      final notifier = container.read(membersProvider.notifier);
      expect(notifier.nextMemberNo(), 'M-1021');
    });

    test('cnicExists finds duplicates only', () {
      final notifier = container.read(membersProvider.notifier);
      expect(notifier.cnicExists('0000000010011'), isTrue);
      expect(notifier.cnicExists('0000000099991'), isFalse);
    });

    test('deactivating a member lowers the active count', () {
      expect(container.read(activeMembersProvider), 18);

      container.read(membersProvider.notifier).setActive('member-1001', false);

      expect(container.read(activeMembersProvider), 17);
      expect(container.read(totalMembersProvider), 20);
    });
  });
}