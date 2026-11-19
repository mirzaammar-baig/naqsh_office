import 'dart:async';

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

  bool isSaving = false;

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  String? validateCode(String? value) {
    final text = (value ?? '').trim().toUpperCase();
    if (text.isEmpty) {
      return 'Block name is required';
    }
    if (text.length > 10) {
      return 'Maximum 10 characters';
    }
    if (ref.read(plotsProvider.notifier).blockExists(text)) {
      return 'Block $text already exists';
    }
    return null;
  }

  Future<void> save() async {
    if (isSaving || !formKey.currentState!.validate()) {
      return;
    }

    final code = codeController.text.trim().toUpperCase();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final notifier = ref.read(plotsProvider.notifier);

    setState(() {
      isSaving = true;
    });

    try {
      await notifier.addBlock(code).timeout(const Duration(seconds: 10));
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text('Block $code added')));
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
        SnackBar(content: Text('Could not save the block: $error')),
      );
    }
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
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: appInputDecoration(
                    label: 'Block Name',
                    hint: 'e.g. D or BAKAR',
                    helper: 'Up to 10 capital letters or digits',
                  ),
                  validator: validateCode,
                  onFieldSubmitted: (_) => save(),
                ),
                const SizedBox(height: 24),
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
                      isSaving ? 'Saving...' : 'Save Block',
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
        ],
      ),
    );
  }
}