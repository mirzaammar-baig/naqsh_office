import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naqsh_office/core/theme/app_input_decoration.dart';
import 'package:naqsh_office/core/theme/app_theme.dart';
import 'package:naqsh_office/core/utils/input_validators.dart';
import 'package:naqsh_office/features/plots/plots_notifier.dart';

class AddBlockScreen extends ConsumerStatefulWidget {
  const AddBlockScreen({super.key});

  @override
  ConsumerState<AddBlockScreen> createState() => _AddBlockScreenState();
}

class _AddBlockScreenState extends ConsumerState<AddBlockScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  void save() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final code = codeController.text.trim().toUpperCase();
    ref.read(plotsProvider.notifier).addBlock(code);

    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text('Block $code added')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Block')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: codeController,
                  style: const TextStyle(fontSize: 16),
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    UpperCaseTextFormatter(),
                    LengthLimitingTextInputFormatter(5),
                  ],
                  decoration: appInputDecoration(
                    label: 'Block Code',
                    hint: 'e.g. D',
                    helper: '1 to 5 capital letters or digits',
                  ),
                  validator: (value) {
                    return InputValidators.blockCode(
                      value,
                      exists: ref.read(plotsProvider.notifier).blockExists,
                    );
                  },
                  onFieldSubmitted: (_) => save(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Save Block',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}