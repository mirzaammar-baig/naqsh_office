import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naqsh_office/core/theme/app_input_decoration.dart';
import 'package:naqsh_office/core/theme/app_theme.dart';
import 'package:naqsh_office/core/utils/input_validators.dart';
import 'package:naqsh_office/features/plots/plot.dart';
import 'package:naqsh_office/features/plots/plot_details.dart';
import 'package:naqsh_office/features/plots/widgets/plot_details_section.dart';
import 'package:naqsh_office/features/plots/plot_providers.dart';
import 'package:naqsh_office/features/plots/plot_status.dart';
import 'package:naqsh_office/features/plots/plots_notifier.dart';

class PlotFormScreen extends ConsumerStatefulWidget {
  const PlotFormScreen({super.key, this.plot});

  // null ho to Add, plot mile to Edit.
  final Plot? plot;

  @override
  ConsumerState<PlotFormScreen> createState() => _PlotFormScreenState();
}

class _PlotFormScreenState extends ConsumerState<PlotFormScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final TextEditingController numberController;
  late final TextEditingController widthController;
  late final TextEditingController lengthController;
  late final TextEditingController priceController;

  String? selectedBlock;
  String category = 'Residential';
  bool isCorner = false;
  PlotStatus status = PlotStatus.available;
  PlotDetails details = const PlotDetails();
  bool isSaving = false;

  // Width aur Length: 3 digits tak, aur ek decimal (jaise 22.5).
  static final TextInputFormatter decimalFormatter =
  TextInputFormatter.withFunction((oldValue, newValue) {
    final regex = RegExp(r'^\d{0,3}(\.\d?)?$');
    return regex.hasMatch(newValue.text) ? newValue : oldValue;
  });

  @override
  void initState() {
    super.initState();
    final existing = widget.plot;

    numberController = TextEditingController(
      text: existing == null
          ? ''
          : int.parse(existing.plotNumber.split('-').last).toString(),
    );
    widthController = TextEditingController(
      text: existing == null ? '' : formatNumber(existing.widthFeet),
    );
    lengthController = TextEditingController(
      text: existing == null ? '' : formatNumber(existing.lengthFeet),
    );
    priceController = TextEditingController(
      text: existing == null ? '' : (existing.pricePaisa ~/ 100).toString(),
    );

    selectedBlock = existing?.block;
    category = existing?.category ?? 'Residential';
    isCorner = existing?.isCorner ?? false;
    status = existing?.status ?? PlotStatus.available;
    details = existing?.details ?? const PlotDetails();
  }

  @override
  void dispose() {
    numberController.dispose();
    widthController.dispose();
    lengthController.dispose();
    priceController.dispose();
    super.dispose();
  }

  // Block B aur number 7 ho to B-07.
  String buildPlotNumber(String block, int number) {
    return '$block-${number.toString().padLeft(2, '0')}';
  }
  Future<void> save() async {
    if (isSaving || !formKey.currentState!.validate()) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final notifier = ref.read(plotsProvider.notifier);
    final existing = widget.plot;

    // parse ki jagah tryParse: khali ya ghalat text par crash nahi hota.
    final width = double.tryParse(widthController.text.trim());
    final length = double.tryParse(lengthController.text.trim());
    final priceRupees = int.tryParse(priceController.text.trim());
    final plotNumberValue = int.tryParse(numberController.text.trim());

    final missingAddFields =
        existing == null && (selectedBlock == null || plotNumberValue == null);

    if (width == null ||
        length == null ||
        priceRupees == null ||
        missingAddFields) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill Block, Plot Number, Width, Length and Price.',
          ),
        ),
      );
      return;
    }

    final pricePaisa = priceRupees * 100;

    setState(() {
      isSaving = true;
    });

    try {
      String message;

      if (existing != null) {
        await notifier
            .updatePlot(
          existing.copyWith(
            widthFeet: width,
            lengthFeet: length,
            category: category,
            isCorner: isCorner,
            pricePaisa: pricePaisa,
            details: details,
          ),
        )
            .timeout(const Duration(seconds: 10));
        message = 'Plot ${existing.plotNumber} updated';
      } else {
        final block = selectedBlock!;
        final plotNumber = buildPlotNumber(block, plotNumberValue!);
        await notifier
            .addPlot(
          Plot(
            id: plotNumber.toLowerCase(),
            societyId: 'demo-city',
            block: block,
            plotNumber: plotNumber,
            widthFeet: width,
            lengthFeet: length,
            category: category,
            isCorner: isCorner,
            status: status,
            pricePaisa: pricePaisa,
            details: details,
          ),
        )
            .timeout(const Duration(seconds: 10));
        message = 'Plot $plotNumber added';
      }

      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } on TimeoutException {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Could not reach the server. Check your internet and try again.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Could not save the plot: $error')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final blocks = ref.watch(blocksProvider);
    final existing = widget.plot;
    final isEdit = existing != null;

    // Live preview: Area aur Size khud calculate hote hain.
    final width = double.tryParse(widthController.text.trim());
    final length = double.tryParse(lengthController.text.trim());
    var areaText = '-';
    var sizeText = '-';
    if (width != null && length != null && width > 0 && length > 0) {
      final area = (width * length).round();
      areaText = '${formatWithCommas(area)} sqft';
      sizeText = '${formatNumber(area / Plot.sqftPerMarla)} Marla';
    }

    // Final plot number ka andaza (jaise B-07).
    final typedNumber = int.tryParse(numberController.text.trim());
    final numberHint = (selectedBlock != null &&
        typedNumber != null &&
        typedNumber >= 1)
        ? 'Plot number will be ${buildPlotNumber(selectedBlock!, typedNumber)}'
        : 'Example: Block B and 7 becomes B-07';

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Plot' : 'Add Plot')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // Block
            if (isEdit)
              _LockedField(label: 'Block', value: existing.block)
            else
              DropdownButtonFormField<String>(
                initialValue: selectedBlock,
                isExpanded: true,
                decoration: appInputDecoration(label: 'Block'),
                items: [
                  for (final block in blocks)
                    DropdownMenuItem(
                      value: block.code,
                      child: Text('Block ${block.code}'),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedBlock = value;
                  });
                },
                validator: (value) => value == null ? 'Block is required' : null,
              ),
            const SizedBox(height: 16),

            // Plot Number
            if (isEdit)
              _LockedField(label: 'Plot Number', value: existing.plotNumber)
            else
              TextFormField(
                controller: numberController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 16),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: appInputDecoration(
                  label: 'Plot Number',
                  hint: 'e.g. 7',
                  helper: numberHint,
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  final error = InputValidators.plotNumber(value);
                  if (error != null) {
                    return error;
                  }
                  final block = selectedBlock;
                  if (block == null) {
                    return null;
                  }
                  final fullNumber = buildPlotNumber(
                    block,
                    int.parse(value!.trim()),
                  );
                  if (ref.read(plotsProvider.notifier).plotExists(fullNumber)) {
                    return 'Plot $fullNumber already exists.';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 16),

            // Width aur Length
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: widthController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(fontSize: 16),
                    inputFormatters: [decimalFormatter],
                    decoration: appInputDecoration(label: 'Width (ft)'),
                    onChanged: (_) => setState(() {}),
                    validator: (value) =>
                        InputValidators.dimension(value, 'Width'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: lengthController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(fontSize: 16),
                    inputFormatters: [decimalFormatter],
                    decoration: appInputDecoration(label: 'Length (ft)'),
                    onChanged: (_) => setState(() {}),
                    validator: (value) =>
                        InputValidators.dimension(value, 'Length'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Area aur Size preview (khud calculate)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: _PreviewItem(label: 'Area', value: areaText)),
                  Expanded(child: _PreviewItem(label: 'Size', value: sizeText)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Category
            _SegmentField<String>(
              label: 'Category',
              value: category,
              options: const {
                'Residential': 'Residential',
                'Commercial': 'Commercial',
              },
              onChanged: (value) {
                setState(() {
                  category = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // Corner
            _SegmentField<bool>(
              label: 'Corner plot',
              value: isCorner,
              options: const {true: 'Yes', false: 'No'},
              onChanged: (value) {
                setState(() {
                  isCorner = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // Status: naya plot sirf Available ya Blocked, edit mein locked
            if (isEdit)
              _LockedField(label: 'Status', value: existing.status.label)
            else
              _SegmentField<PlotStatus>(
                label: 'Status',
                value: status,
                options: const {
                  PlotStatus.available: 'Available',
                  PlotStatus.blocked: 'Blocked',
                },
                onChanged: (value) {
                  setState(() {
                    status = value;
                  });
                },
              ),
            const SizedBox(height: 20),

            // Price
            TextFormField(
              controller: priceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 16),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              decoration: appInputDecoration(
                label: 'Price (Rs)',
                hint: 'e.g. 3000000',
                prefixText: 'Rs ',
              ),
              validator: InputValidators.priceRupees,
            ),
            PlotDetailsSection(
              initial: details,
              onChanged: (value) {
                details = value;
              },
            ),
            const SizedBox(height: 28),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: isSaving ? null : save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isSaving
                      ? 'Saving...'
                      : (isEdit ? 'Save Changes' : 'Save Plot'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedField extends StatelessWidget {
  const _LockedField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      enabled: false,
      style: const TextStyle(fontSize: 16),
      decoration: appInputDecoration(label: label, locked: true),
    );
  }
}

class _PreviewItem extends StatelessWidget {
  const _PreviewItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

class _SegmentField<T> extends StatelessWidget {
  const _SegmentField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<T>(
            showSelectedIcon: false,
            segments: [
              for (final entry in options.entries)
                ButtonSegment<T>(value: entry.key, label: Text(entry.value)),
            ],
            selected: {value},
            onSelectionChanged: (selection) => onChanged(selection.first),
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.white,
              selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.12),
              selectedForegroundColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}