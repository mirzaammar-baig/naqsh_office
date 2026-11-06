import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naqsh_office/core/theme/app_theme.dart';
import 'package:naqsh_office/features/plots/plot_detail_screen.dart';
import 'package:naqsh_office/features/plots/plot_providers.dart';
import 'package:naqsh_office/features/plots/plot_status.dart';
import 'package:naqsh_office/features/plots/widgets/plot_card.dart';

class PlotsScreen extends ConsumerStatefulWidget {
  const PlotsScreen({super.key});

  @override
  ConsumerState<PlotsScreen> createState() => _PlotsScreenState();
}

class _PlotsScreenState extends ConsumerState<PlotsScreen> {
  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController(
      text: ref.read(searchQueryProvider),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void clearAllFilters() {
    searchController.clear();
    ref.read(searchQueryProvider.notifier).setQuery('');
    ref.read(blockFilterProvider.notifier).setBlock('All');
    ref.read(statusFilterProvider.notifier).setStatus(null);
  }

  @override
  Widget build(BuildContext context) {
    final plots = ref.watch(filteredPlotsProvider);
    final blocks = ref.watch(blocksProvider);
    final query = ref.watch(searchQueryProvider);
    final selectedBlock = ref.watch(blockFilterProvider);
    final selectedStatus = ref.watch(statusFilterProvider);

    final hasFilters =
        query.isNotEmpty || selectedBlock != 'All' || selectedStatus != null;

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        // Sticky search bar: scroll par upar chipak jata hai
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
              ref.read(searchQueryProvider.notifier).setQuery(value);
            },
            decoration: InputDecoration(
              hintText: 'Search plot number (e.g. B-03)',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  searchController.clear();
                  ref.read(searchQueryProvider.notifier).setQuery('');
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

        // Filters aur count: ye search bar ke neeche scroll hote hain
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Block filter: ab blocks ki list se banta hai
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All blocks',
                      selected: selectedBlock == 'All',
                      onTap: () {
                        ref.read(blockFilterProvider.notifier).setBlock('All');
                      },
                    ),
                    for (final block in blocks)
                      _FilterChip(
                        label: 'Block ${block.code}',
                        selected: selectedBlock == block.code,
                        onTap: () {
                          ref
                              .read(blockFilterProvider.notifier)
                              .setBlock(block.code);
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All statuses',
                      selected: selectedStatus == null,
                      onTap: () {
                        ref.read(statusFilterProvider.notifier).setStatus(null);
                      },
                    ),
                    for (final status in PlotStatus.values)
                      _FilterChip(
                        label: status.label,
                        selected: selectedStatus == status,
                        onTap: () {
                          ref
                              .read(statusFilterProvider.notifier)
                              .setStatus(status);
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
                        plots.length == 1 ? '1 plot' : '${plots.length} plots',
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

        // Khali ho to empty state, warna cards ki list
        if (plots.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 56,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No plots found',
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
              itemCount: plots.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final plot = plots[index];
                return PlotCard(
                  plot: plot,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlotDetailScreen(plotId: plot.id),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary,
        shape: const StadiumBorder(),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AppColors.textDark,
        ),
      ),
    );
  }
}