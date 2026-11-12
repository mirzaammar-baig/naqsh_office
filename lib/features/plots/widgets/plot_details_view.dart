import 'package:flutter/material.dart';
import 'package:naqsh_office/core/theme/app_theme.dart';
import 'package:naqsh_office/features/plots/plot_details.dart';

const Color _green = Color(0xFF16A34A);
const Color _amber = Color(0xFFD97706);

// Plot Detail screen mein plot ki extra tafseel dikhata hai.
// Jo cheez bhari nahi gayi, wo hissa nazar nahi aata.
class PlotDetailsView extends StatelessWidget {
  const PlotDetailsView({super.key, required this.details});

  final PlotDetails details;

  IconData _placeIcon(NearbyPlace place) {
    return switch (place) {
      NearbyPlace.masjid => Icons.mosque_outlined,
      NearbyPlace.park => Icons.park_outlined,
      NearbyPlace.school => Icons.school_outlined,
      NearbyPlace.hospital => Icons.local_hospital_outlined,
      NearbyPlace.market => Icons.storefront_outlined,
      NearbyPlace.zoo => Icons.pets_outlined,
      NearbyPlace.mainGate => Icons.door_front_door_outlined,
      NearbyPlace.mainRoad => Icons.add_road_rounded,
      NearbyPlace.playground => Icons.sports_soccer_outlined,
      NearbyPlace.graveyard => Icons.landscape_outlined,
      NearbyPlace.busStop => Icons.directions_bus_outlined,
      NearbyPlace.mall => Icons.local_mall_outlined,
      NearbyPlace.bank => Icons.account_balance_outlined,
      NearbyPlace.petrolPump => Icons.local_gas_station_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final showFeatures =
        details.facing != null ||
            details.roadWidthFeet != null ||
            details.possessionReady ||
            details.development != DevelopmentStatus.undeveloped;

    if (details.isEmpty && !showFeatures) {
      return const SizedBox.shrink();
    }

    // Qareeb se door ki tarteeb mein.
    final nearby = details.distances.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (details.description.isNotEmpty)
          _SectionCard(
            title: 'About this plot',
            child: Text(
              details.description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppColors.textDark,
              ),
            ),
          ),

        if (showFeatures)
          _SectionCard(
            title: 'Features',
            child: Column(
              children: [
                if (details.facing != null)
                  _FeatureRow(label: 'Facing', value: details.facing!.label),
                if (details.roadWidthFeet != null)
                  _FeatureRow(label: 'Road width', value: details.roadWidthText),
                _FeatureRow(
                  label: 'Development',
                  value: details.development.label,
                ),
                _FeatureRow(
                  label: 'Possession',
                  value: details.possessionReady ? 'Ready' : 'Not ready',
                ),
              ],
            ),
          ),

        if (details.utilities.isNotEmpty)
          _SectionCard(
            title: 'Utilities',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final utility in details.utilities)
                  _TagChip(label: utility.label, color: AppColors.primary),
              ],
            ),
          ),

        if (details.locationTags.isNotEmpty)
          _SectionCard(
            title: 'Location',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in details.locationTags)
                  _TagChip(
                    label: tag,
                    color: AppColors.primary,
                    icon: Icons.place_outlined,
                  ),
              ],
            ),
          ),

        if (details.advantages.isNotEmpty)
          _SectionCard(
            title: 'Advantages',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in details.advantages)
                  _TagChip(
                    label: tag,
                    color: _green,
                    icon: Icons.check_circle_outline_rounded,
                  ),
              ],
            ),
          ),

        if (details.disadvantages.isNotEmpty)
          _SectionCard(
            title: 'Things to consider',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final tag in details.disadvantages)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TagChip(
                          label: tag,
                          color: _amber,
                          icon: Icons.info_outline_rounded,
                        ),
                        if (disadvantageUpsides.containsKey(tag))
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text(
                              'Upside: ${disadvantageUpsides[tag]}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

        if (nearby.isNotEmpty)
          _SectionCard(
            title: 'Nearby places',
            child: Column(
              children: [
                for (final entry in nearby)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _placeIcon(entry.key),
                            size: 19,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.key.label,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        Text(
                          formatDistance(entry.value),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14101828),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}