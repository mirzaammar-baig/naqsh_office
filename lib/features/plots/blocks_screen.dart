import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naqsh_office/core/theme/app_input_decoration.dart';
import 'package:naqsh_office/core/theme/app_theme.dart';
import 'package:naqsh_office/features/plots/add_block_screen.dart';
import 'package:naqsh_office/features/plots/block.dart';
import 'package:naqsh_office/features/plots/plot_providers.dart';
import 'package:naqsh_office/features/plots/plots_notifier.dart';

const Color _red = Color(0xFFDC2626);

class BlocksScreen extends ConsumerWidget {
  const BlocksScreen({super.key});

  Future<void> _edit(BuildContext context, Block block, int count) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _EditBlockSheet(block: block, plotCount: count);
      },
    );
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _delete(
      BuildContext context,
      WidgetRef ref,
      Block block,
      int count,
      ) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(plotsProvider.notifier);

    // Plots hon to delete nahi ho sakta.
    if (count > 0) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('Cannot delete Block ${block.code}'),
            content: Text(
              'This block has $count ${count == 1 ? 'plot' : 'plots'}. '
                  'Delete or move those plots first, then delete the block.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Delete Block ${block.code}?'),
          content: const Text('This block has no plots. It will be removed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: _red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    try {
      await notifier
          .deleteBlock(block.code)
          .timeout(const Duration(seconds: 10));
      messenger.showSnackBar(
        SnackBar(content: Text('Block ${block.code} deleted')),
      );
    } on TimeoutException {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not reach the server. Try again.'),
        ),
      );
    } on StateError catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocks = ref.watch(blocksProvider);
    final counts = ref.watch(blockPlotCountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Blocks')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBlockScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Block'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: blocks.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final block = blocks[index];
          final count = counts[block.code] ?? 0;
          return _BlockTile(
            block: block,
            plotCount: count,
            onEdit: () => _edit(context, block, count),
            onDelete: () => _delete(context, ref, block, count),
          );
        },
      ),
    );
  }
}

class _BlockTile extends StatelessWidget {
  const _BlockTile({
    required this.block,
    required this.plotCount,
    required this.onEdit,
    required this.onDelete,
  });

  final Block block;
  final int plotCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final code = block.code;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
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
      child: Row(
        children: [
          // Badge: naam lamba ho to chora ho jata hai.
          Container(
            constraints: const BoxConstraints(
              minWidth: 56,
              maxWidth: 120,
              minHeight: 56,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              code,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: code.length <= 3 ? 20 : 15,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Block $code',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  plotCount == 1 ? '1 plot' : '$plotCount plots',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                if (block.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    block.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else {
                onDelete();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: _red),
                  title: Text('Delete', style: TextStyle(color: _red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- Block edit ----------

class _EditBlockSheet extends ConsumerStatefulWidget {
  const _EditBlockSheet({required this.block, required this.plotCount});

  final Block block;
  final int plotCount;

  @override
  ConsumerState<_EditBlockSheet> createState() => _EditBlockSheetState();
}

class _EditBlockSheetState extends ConsumerState<_EditBlockSheet> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final TextEditingController codeController;
  late final TextEditingController descriptionController;

  bool isSaving = false;
  String? errorText;

  // Naam sirf khali block ka badal sakta hai.
  bool get canRename => widget.plotCount == 0;

  @override
  void initState() {
    super.initState();
    codeController = TextEditingController(text: widget.block.code);
    descriptionController = TextEditingController(
      text: widget.block.description,
    );
  }

  @override
  void dispose() {
    codeController.dispose();
    descriptionController.dispose();
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
    if (text != widget.block.code &&
        ref.read(plotsProvider.notifier).blockExists(text)) {
      return 'Block $text already exists';
    }
    return null;
  }

  Future<void> save() async {
    if (isSaving || !formKey.currentState!.validate()) {
      return;
    }

    final notifier = ref.read(plotsProvider.notifier);
    final navigator = Navigator.of(context);
    final newCode = canRename
        ? codeController.text.trim().toUpperCase()
        : widget.block.code;

    setState(() {
      isSaving = true;
      errorText = null;
    });

    try {
      await notifier
          .editBlock(
        block: widget.block,
        newCode: newCode,
        description: descriptionController.text,
      )
          .timeout(const Duration(seconds: 10));
      navigator.pop('Block $newCode updated');
    } on TimeoutException {
      showError('Could not reach the server. Check your internet.');
    } on StateError catch (error) {
      showError(error.message);
    } catch (error) {
      showError('Could not save: $error');
    }
  }

  void showError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      isSaving = false;
      errorText = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Block ${widget.block.code}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: codeController,
                enabled: canRename,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(fontSize: 16),
                inputFormatters: [LengthLimitingTextInputFormatter(10)],
                decoration: appInputDecoration(
                  label: 'Block name',
                  helper: canRename
                      ? 'Up to 10 characters'
                      : 'Locked: this block has ${widget.plotCount} '
                      '${widget.plotCount == 1 ? 'plot' : 'plots'}',
                  locked: !canRename,
                ),
                validator: canRename ? validateCode : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                style: const TextStyle(fontSize: 16),
                inputFormatters: [LengthLimitingTextInputFormatter(60)],
                decoration: appInputDecoration(
                  label: 'Description (optional)',
                  hint: 'e.g. Near main gate',
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorText!,
                  style: const TextStyle(
                    color: _red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: isSaving ? null : save,
                  child: Text(isSaving ? 'Saving...' : 'Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}