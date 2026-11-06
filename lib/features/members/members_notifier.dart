import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naqsh_office/features/members/fake_member_repository.dart';
import 'package:naqsh_office/features/members/member.dart';

// Data kahan se aata hai (abhi fake, baad mein Firestore).
final memberRepositoryProvider = Provider<FakeMemberRepository>((ref) {
  return FakeMemberRepository();
});

class MembersNotifier extends Notifier<List<Member>> {
  @override
  List<Member> build() {
    return ref.read(memberRepositoryProvider).getMembers();
  }

  // cnic dashes ke baghair 13 digits. exceptId edit ke waqt apna record chhorne ke liye.
  bool cnicExists(String cnic, {String? exceptId}) {
    return state.any((m) => m.cnic == cnic && m.id != exceptId);
  }

  // Agla Member No khud banta hai: M-1021, M-1022...
  String nextMemberNo() {
    var highest = 1000;
    for (final member in state) {
      final number = int.tryParse(member.memberNo.replaceAll('M-', ''));
      if (number != null && number > highest) {
        highest = number;
      }
    }
    return 'M-${highest + 1}';
  }

  void addMember(Member member) {
    state = [...state, member];
  }

  void updateMember(Member updated) {
    state = [
      for (final member in state)
        if (member.id == updated.id) updated else member,
    ];
  }

  void setActive(String id, bool value) {
    state = [
      for (final member in state)
        if (member.id == id) member.copyWith(isActive: value) else member,
    ];
  }
}

final membersProvider = NotifierProvider<MembersNotifier, List<Member>>(
  MembersNotifier.new,
);

// ---------- Filter ----------

enum MemberFilter {
  all('All'),
  active('Active'),
  inactive('Inactive'),
  overseas('Overseas');

  const MemberFilter(this.label);

  final String label;
}

class MemberSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) {
    state = value;
  }
}

final memberSearchProvider =
NotifierProvider<MemberSearchNotifier, String>(MemberSearchNotifier.new);

class MemberFilterNotifier extends Notifier<MemberFilter> {
  @override
  MemberFilter build() => MemberFilter.all;

  void setFilter(MemberFilter value) {
    state = value;
  }
}

final memberFilterProvider =
NotifierProvider<MemberFilterNotifier, MemberFilter>(
  MemberFilterNotifier.new,
);

// Search aur filter lagne ke baad bachne wale members.
final filteredMembersProvider = Provider<List<Member>>((ref) {
  final members = ref.watch(membersProvider);
  final query = ref.watch(memberSearchProvider).trim().toLowerCase();
  final filter = ref.watch(memberFilterProvider);

  // Poora CNIC (13 digits) dashes ke saath ya baghair likha ja sakta hai.
  final queryDigits = query.replaceAll(RegExp(r'\D'), '');

  return members.where((member) {
    final matchesFilter = switch (filter) {
      MemberFilter.all => true,
      MemberFilter.active => member.isActive,
      MemberFilter.inactive => !member.isActive,
      MemberFilter.overseas => member.isOverseas,
    };

    final matchesSearch = query.isEmpty ||
        member.memberNo.toLowerCase().contains(query) ||
        member.fullName.toLowerCase().contains(query) ||
        member.phone.contains(query) ||
        (queryDigits.length == 13 && member.cnic == queryDigits);

    return matchesFilter && matchesSearch;
  }).toList();
});

// Dashboard ke liye.
final totalMembersProvider = Provider<int>((ref) {
  return ref.watch(membersProvider).length;
});

final activeMembersProvider = Provider<int>((ref) {
  return ref.watch(membersProvider).where((m) => m.isActive).length;
});