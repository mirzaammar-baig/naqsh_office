import 'dart:async';
import 'package:naqsh_office/features/auth/auth_repository.dart';
import 'package:naqsh_office/features/members/plot_booking.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naqsh_office/features/members/firestore_member_repository.dart';
import 'package:naqsh_office/features/members/member.dart';

// Data ab Firestore se aata hai.
final memberRepositoryProvider = Provider<FirestoreMemberRepository>((ref) {
  return FirestoreMemberRepository();
});

class MembersNotifier extends Notifier<List<Member>> {
  @override
  List<Member> build() {
    final repository = ref.read(memberRepositoryProvider);

    // Firestore mein members badlein to state khud update ho jati hai.
    final subscription = repository.watchMembers().listen((members) {
      state = members;
    });

    ref.onDispose(subscription.cancel);

    return const [];
  }

  // cnic dashes ke baghair 13 digits. exceptId edit ke waqt apna record chhorne ke liye.
  bool cnicExists(String cnic, {String? exceptId}) {
    return state.any((m) => m.cnic == cnic && m.id != exceptId);
  }

  // Agla Member No khud banta hai: M-1001, M-1002...
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

  Future<void> addMember(Member member) {
    return ref.read(memberRepositoryProvider).saveMember(member);
  }

  Future<void> updateMember(Member updated) {
    return ref.read(memberRepositoryProvider).saveMember(updated);
  }

  Future<void> setActive(String id, bool value) {
    return ref.read(memberRepositoryProvider).setActive(id, value);
  }
  // Earnest wale plots Booked, baaqi Hold. Receipt numbers wapas milte hain.
  Future<List<String>> addMemberWithPlots(
      Member member,
      List<PlotBooking> bookings,
      ) {
    return ref
        .read(memberRepositoryProvider)
        .addMemberWithPlots(
      member,
      bookings,
      by: AuthRepository().currentUser?.email ?? '',
    );
  }

  // Maujooda member ko plots do: earnest wale Booked, baaqi Hold.
  Future<List<String>> assignPlots(
      String memberId,
      List<PlotBooking> bookings, {
        int holdDays = 3,
      }) {
    return ref
        .read(memberRepositoryProvider)
        .assignPlots(
      memberId,
      bookings,
      by: AuthRepository().currentUser?.email ?? '',
      holdDays: holdDays,
    );
  }

  // Deactivate: member inactive aur uske plots wapas Available.
  Future<void> deactivateMember(String memberId) {
    return ref.read(memberRepositoryProvider).deactivateMember(memberId);
  }

  // Delete: member mit jata hai aur uske plots wapas Available.
  Future<void> deleteMember(String memberId) {
    return ref.read(memberRepositoryProvider).deleteMember(memberId);
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