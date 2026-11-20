import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naqsh_office/core/theme/app_input_decoration.dart';
import 'package:naqsh_office/core/theme/app_theme.dart';
import 'package:naqsh_office/features/plots/plot_details.dart';

// Add/Edit Plot form ka "Plot details (optional)" hissa.
// Jab bhi kuch badalta hai, onChanged se naya PlotDetails parent ko milta hai.
class PlotDetailsSection extends StatefulWidget {
  const PlotDetailsSection({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final PlotDetails initial;
  final ValueChanged<PlotDetails> onChanged;

  @override
  State<PlotDetailsSection> createState() => _PlotDetailsSectionState();
}

class _PlotDetailsSectionState extends State<PlotDetailsSection> {
  late final TextEditingController descriptionController;
  late final TextEditingController roadController;
  late final Map<NearbyPlace, TextEditingController> distanceControllers;

  PlotFacing? facing;
  late DevelopmentStatus development;
  late bool possessionReady;
  late Set<Utility> utilities;
  late List<String> locationTags;
  late List<String> advantages;
  late List<String> disadvantages;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;

    descriptionController = TextEditingController(text: initial.description);
    roadController = TextEditingController(
      text: initial.roadWidthFeet?.toString() ?? '',
    );
    distanceControllers = {
      for (final place in NearbyPlace.values)
        place: TextEditingController(
          text: initial.distances[place]?.toString() ?? '',
        ),
    };

    facing = initial.facing;
    development = initial.development;
    possessionReady = initial.possessionReady;
    utilities = {...initial.utilities};
    locationTags = [...initial.locationTags];
    advantages = [...initial.advantages];
    disadvantages = [...initial.disadvantages];
  }

  @override
  void dispose() {
    descriptionController.dispose();
    roadController.dispose();
    for (final controller in distanceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Maujooda sab values se naya PlotDetails banao aur parent ko do.
  void emit() {
    final distances = <NearbyPlace, int>{};
    for (final entry in distanceControllers.entries) {
      final meters = int.tryParse(entry.value.text.trim());
      if (meters != null && meters > 0) {
        distances[entry.key] = meters;
      }
    }

    final road = int.tryParse(roadController.text.trim());

    widget.onChanged(
      PlotDetails(
        description: descriptionController.text.trim(),
        facing: facing,
        roadWidthFeet: (road != null && road > 0) ? road : null,
        development: development,
        possessionReady: possessionReady,
        utilities: [
          for (final utility in Utility.values)
            if (utilities.contains(utility)) utility,
        ],
        locationTags: locationTags,
        advantages: advantages,
        disadvantages: disadvantages,
        distances: distances,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDistance = distanceControllers.values.any(
          (controller) => controller.text.trim().isNotEmpty,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Text(
          'Plot details (optional)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'More details help you show the real value of a plot.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),

        // Description
        TextFormField(
          controller: descriptionController,
          maxLines: 3,
          maxLength: 300,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 16),
          decoration: appInputDecoration(
            label: 'Description',
            hint: 'e.g. Park facing corner plot on a wide road',
          ),
          onChanged: (_) => emit(),
        ),
        const SizedBox(height: 16),

        // Facing
        const _FieldLabel('Facing'),
        Wrap(
          spacing: 8,
          children: [
            for (final option in PlotFacing.values)
              ChoiceChip(
                label: Text(option.label),
                selected: facing == option,
                onSelected: (selected) {
                  setState(() {
                    facing = selected ? option : null;
                  });
                  emit();
                },
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Road width
        TextFormField(
          controller: roadController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 16),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          decoration: appInputDecoration(
            label: 'Road width (ft)',
            hint: 'e.g. 30',
          ),
          onChanged: (_) => emit(),
        ),
        const SizedBox(height: 16),

        // Development status
        const _FieldLabel('Development status'),
        Wrap(
          spacing: 8,
          children: [
            for (final option in DevelopmentStatus.values)
              ChoiceChip(
                label: Text(option.label),
                selected: development == option,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      development = option;
                    });
                    emit();
                  }
                },
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Possession ready'),
          value: possessionReady,
          onChanged: (value) {
            setState(() {
              possessionReady = value;
            });
            emit();
          },
        ),
        const SizedBox(height: 8),

        // Utilities
        const _FieldLabel('Utilities available'),
        Wrap(
          spacing: 8,
          children: [
            for (final utility in Utility.values)
              FilterChip(
                label: Text(utility.label),
                selected: utilities.contains(utility),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      utilities.add(utility);
                    } else {
                      utilities.remove(utility);
                    }
                  });
                  emit();
                },
              ),
          ],
        ),
        const SizedBox(height: 20),

        // Tags
        _TagPicker(
          label: 'Location tags',
          suggestions: locationTagSuggestions,
          selected: locationTags,
          onChanged: (value) {
            setState(() {
              locationTags = value;
            });
            emit();
          },
        ),
        const SizedBox(height: 20),
        _TagPicker(
          label: 'Advantages',
          suggestions: advantageSuggestions,
          selected: advantages,
          onChanged: (value) {
            setState(() {
              advantages = value;
            });
            emit();
          },
        ),
        const SizedBox(height: 20),
        _TagPicker(
          label: 'Disadvantages',
          suggestions: disadvantageUpsides.keys.toList(),
          upsides: disadvantageUpsides,
          selected: disadvantages,
          onChanged: (value) {
            setState(() {
              disadvantages = value;
            });
            emit();
          },
        ),
        const SizedBox(height: 12),

        // Nearby places
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          shape: const Border(),
          collapsedShape: const Border(),
          initiallyExpanded: hasDistance,
          title: const Text(
            'Nearby places (distance in meters)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          subtitle: const Text(
            'Leave blank if not needed',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final fieldWidth = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final place in NearbyPlace.values)
                      SizedBox(
                        width: fieldWidth,
                        child: TextFormField(
                          controller: distanceControllers[place],
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 16),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(5),
                          ],
                          decoration: appInputDecoration(
                            label: '${place.label} (m)',
                            hint: 'e.g. 300',
                          ),
                          onChanged: (_) => emit(),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

// Ready-made tags chuno, ya apna tag likh kar add karo.
class _TagPicker extends StatefulWidget {
  const _TagPicker({
    required this.label,
    required this.suggestions,
    required this.selected,
    required this.onChanged,
    this.upsides = const {},
  });

  final String label;
  final List<String> suggestions;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  // Tag ke saath uska upside (sirf Disadvantages ke liye).
  final Map<String, String> upsides;

  @override
  State<_TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends State<_TagPicker> {
  final TextEditingController customController = TextEditingController();

  @override
  void dispose() {
    customController.dispose();
    super.dispose();
  }

  void toggle(String tag, bool selected) {
    final updated = [...widget.selected];
    if (selected) {
      if (!updated.contains(tag)) {
        updated.add(tag);
      }
    } else {
      updated.remove(tag);
    }
    widget.onChanged(updated);
  }

  void addCustom() {
    final text = customController.text.trim();
    if (text.isEmpty) {
      return;
    }
    final exists = widget.selected.any(
          (tag) => tag.toLowerCase() == text.toLowerCase(),
    );
    if (!exists) {
      widget.onChanged([...widget.selected, text]);
    }
    customController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Suggestions ke saath wo custom tags bhi dikhao jo user ne add kiye.
    final allTags = [
      ...widget.suggestions,
      for (final tag in widget.selected)
        if (!widget.suggestions.contains(tag)) tag,
    ];

    final upsideLines = [
      for (final tag in widget.selected)
        if (widget.upsides.containsKey(tag)) '$tag: ${widget.upsides[tag]}',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(widget.label),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final tag in allTags)
              FilterChip(
                label: Text(tag),
                selected: widget.selected.contains(tag),
                onSelected: (selected) => toggle(tag, selected),
              ),
          ],
        ),
        for (final line in upsideLines)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              line,
              style: const TextStyle(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: AppColors.textMuted,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: customController,
                maxLength: 30,
                style: const TextStyle(fontSize: 15),
                decoration: appInputDecoration(
                  label: 'Add your own',
                  hint: 'Type a tag',
                ).copyWith(counterText: ''),
                onSubmitted: (_) => addCustom(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: addCustom,
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add tag',
            ),
          ],
        ),
      ],
    );
  }
}