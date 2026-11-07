import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naqsh_office/core/theme/app_theme.dart';
import 'package:naqsh_office/core/widgets/filter_pill.dart';
import 'package:naqsh_office/features/members/members_notifier.dart';
import 'package:naqsh_office/features/members/widgets/member_card.dart';
import 'package:naqsh_office/features/members/member_detail_screen.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController(
      text: ref.read(memberSearchProvider),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void clearAllFilters() {
    searchController.clear();
    ref.read(memberSearchProvider.notifier).setQuery('');
    ref.read(memberFilterProvider.notifier).setFilter(MemberFilter.all);
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(filteredMembersProvider);
    final query = ref.watch(memberSearchProvider);
    final selectedFilter = ref.watch(memberFilterProvider);

    final hasFilters = query.isNotEmpty || selectedFilter != MemberFilter.all;

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        // Sticky search bar
        SliverAppBar(
          pinned: true,
          primary: false,
          automaticallyImplyLeading: false,
          toolbarHeight: 68,
          titleSpacing: 16,
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black38,
          scrolledUnderElevation: 3,
          title: TextField(
            controller: searchController,
            style: const TextStyle(fontSize: 16),
            onChanged: (value) {
              ref.read(memberSearchProvider.notifier).setQuery(value);
            },
            decoration: InputDecoration(
              hintText: 'Search name, member no, phone or CNIC',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  searchController.clear();
                  ref.read(memberSearchProvider.notifier).setQuery('');
                },
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),

        // Filter aur count
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    for (final filter in MemberFilter.values)
                      FilterPill(
                        label: filter.label,
                        selected: selectedFilter == filter,
                        onTap: () {
                          ref
                              .read(memberFilterProvider.notifier)
                              .setFilter(filter);
                        },
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        members.length == 1
                            ? '1 member'
                            : '${members.length} members',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    if (hasFilters)
                      TextButton(
                        onPressed: clearAllFilters,
                        child: const Text('Clear filters'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Khali ho to empty state, warna cards
        if (members.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 56,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No members found',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Try a different search or filter',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverList.separated(
              itemCount: members.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final member = members[index];
                return MemberCard(
                  member: member,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MemberDetailScreen(memberId: member.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}