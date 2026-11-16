import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naqsh_office/core/theme/app_input_decoration.dart';
import 'package:naqsh_office/core/theme/app_theme.dart';
import 'package:naqsh_office/features/payments/payment.dart';
import 'package:naqsh_office/features/payments/payments_notifier.dart';
import 'package:naqsh_office/features/plots/plot.dart';
import 'package:naqsh_office/features/plots/plot_status.dart';

const Color _red = Color(0xFFDC2626);
const Color _green = Color(0xFF16A34A);

String _rs(int paisa) => 'Rs ${formatWithCommas(paisa ~/ 100)}';

// Plot Detail ka "Payments" hissa: Total, Paid, Balance, payments ki list.
// Sirf Booked, Allotted ya Possession wale plot par nazar aata hai.
class PlotPaymentsSection extends ConsumerWidget {
  const PlotPaymentsSection({
    super.key,
    required this.plot,
    required this.memberName,
  });

  final Plot plot;
  final String memberName;

  Future<void> _addPayment(
      BuildContext context,
      int balancePaisa,
      ) async {
    final messenger = ScaffoldMessenger.of(context);
    final receipt = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _AddPaymentSheet(
          plot: plot,
          memberName: memberName,
          balancePaisa: balancePaisa,
        );
      },
    );
    if (receipt != null) {
      messenger.showSnackBar(SnackBar(content: Text('Payment $receipt added')));
    }
  }

  void _openPayment(BuildContext context, Payment payment) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _PaymentDetailSheet(payment: payment),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPay =
        plot.memberId != null &&
            (plot.status == PlotStatus.booked ||
                plot.status == PlotStatus.allotted ||
                plot.status == PlotStatus.possession);
    if (!canPay) {
      return const SizedBox.shrink();
    }

    // Sirf is plot ke maujooda member ki payments (purane member ki nahi).
    final payments = [
      for (final payment in ref.watch(paymentsProvider))
        if (payment.plotId == plot.id && payment.memberId == plot.memberId)
          payment,
    ];
    final paid = paidPaisaForPlot(payments, plot.id);
    final balance = plot.pricePaisa - paid;
    var earnest = 0;
    for (final payment in payments) {
      if (payment.isEarnest && !payment.isReversed) {
        earnest += payment.amountPaisa;
      }
    }
    final progress = plot.pricePaisa == 0
        ? 0.0
        : (paid / plot.pricePaisa).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Payments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
            if (balance > 0)
              FilledButton.tonalIcon(
                onPressed: () => _addPayment(context, balance),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add payment'),
              )
            else
              const _Pill(text: 'Fully paid', color: _green),
          ],
        ),
        const SizedBox(height: 12),
        Container(
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
            children: [
              Row(
                children: [
                  _Amount(label: 'Total', value: _rs(plot.pricePaisa)),
                  _Amount(label: 'Paid', value: _rs(paid), color: _green),
                  _Amount(
                    label: 'Balance',
                    value: _rs(balance),
                    color: balance > 0 ? _red : _green,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.border,
                  color: _green,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      earnest > 0 ? 'Earnest ${_rs(earnest)} included' : '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}% paid',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (payments.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'No payments yet.',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
          )
        else
          for (final payment in payments)
            _PaymentTile(
              payment: payment,
              onTap: () => _openPayment(context, payment),
            ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color ?? AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment, required this.onTap});

  final Payment payment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reversed = payment.isReversed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14101828),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(
          reversed ? Icons.replay_rounded : Icons.payments_outlined,
          color: reversed ? _red : _green,
        ),
        title: Text(
          payment.amountText,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: reversed ? AppColors.textMuted : AppColors.textDark,
            decoration: reversed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${payment.isEarnest ? 'Earnest  |  ' : ''}${payment.receiptNo}  |  ${payment.method.label}  |  ${payment.dateText}',
        ),
        trailing: reversed
            ? const _Pill(text: 'Reversed', color: _red)
            : const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

// ---------- Payment ki tafseel + Reverse ----------

class _PaymentDetailSheet extends ConsumerWidget {
  const _PaymentDetailSheet({required this.payment});

  final Payment payment;

  Future<void> _reverse(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(paymentsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();
        String? error;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Reverse ${payment.receiptNo}?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${payment.amountText} will be removed from the paid '
                        'amount. The record is kept as Reversed.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLength: 100,
                    decoration: InputDecoration(
                      labelText: 'Reason',
                      errorText: error,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.length < 3) {
                      setState(() {
                        error = 'Write a reason (at least 3 letters)';
                      });
                      return;
                    }
                    Navigator.pop(dialogContext, text);
                  },
                  style: FilledButton.styleFrom(backgroundColor: _red),
                  child: const Text('Reverse'),
                ),
              ],
            );
          },
        );
      },
    );

    if (reason == null) {
      return;
    }

    navigator.pop();
    try {
      await notifier
          .reversePayment(payment, reason)
          .timeout(const Duration(seconds: 10));
      messenger.showSnackBar(
        SnackBar(content: Text('${payment.receiptNo} reversed')),
      );
    } on TimeoutException {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not reach the server. Try again.'),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    payment.receiptNo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                if (payment.isReversed)
                  const _Pill(text: 'Reversed', color: _red),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              payment.amountText,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            _Row(label: 'Plot', value: payment.plotNumber),
            _Row(label: 'Member', value: payment.memberName),
            _Row(label: 'Method', value: payment.method.label),
            _Row(label: 'Date', value: payment.dateText),
            if (payment.reference.isNotEmpty)
              _Row(label: 'Reference', value: payment.reference),
            if (payment.note.isNotEmpty)
              _Row(label: 'Note', value: payment.note),
            if (payment.createdBy.isNotEmpty)
              _Row(label: 'Added by', value: payment.createdBy),
            if (payment.isReversed) ...[
              _Row(label: 'Reason', value: payment.reverseReason),
              if (payment.reversedAt != null)
                _Row(
                  label: 'Reversed on',
                  value: formatDate(payment.reversedAt!),
                ),
            ],
            const SizedBox(height: 16),
            if (!payment.isReversed)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _reverse(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _red,
                    side: const BorderSide(color: _red),
                  ),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Reverse this payment'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Nayi payment ----------

class _AddPaymentSheet extends ConsumerStatefulWidget {
  const _AddPaymentSheet({
    required this.plot,
    required this.memberName,
    required this.balancePaisa,
  });

  final Plot plot;
  final String memberName;
  final int balancePaisa;

  @override
  ConsumerState<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends ConsumerState<_AddPaymentSheet> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController referenceController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  PaymentMethod method = PaymentMethod.cash;
  bool isSaving = false;
  String? errorText;

  @override
  void dispose() {
    amountController.dispose();
    referenceController.dispose();
    noteController.dispose();
    super.dispose();
  }

  String? validateAmount(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Amount is required';
    }
    final rupees = int.tryParse(text);
    if (rupees == null || rupees <= 0) {
      return 'Enter an amount more than 0';
    }
    if (rupees * 100 > widget.balancePaisa) {
      return 'More than the balance (${_rs(widget.balancePaisa)})';
    }
    return null;
  }

  Future<void> save() async {
    if (isSaving || !formKey.currentState!.validate()) {
      return;
    }

    final notifier = ref.read(paymentsProvider.notifier);
    final navigator = Navigator.of(context);
    final amountPaisa = int.parse(amountController.text.trim()) * 100;

    setState(() {
      isSaving = true;
      errorText = null;
    });

    try {
      final receipt = await notifier
          .addPayment(
        plot: widget.plot,
        memberName: widget.memberName,
        amountPaisa: amountPaisa,
        method: method,
        reference: referenceController.text,
        note: noteController.text,
      )
          .timeout(const Duration(seconds: 15));
      navigator.pop(receipt);
    } on TimeoutException {
      showError('Could not reach the server. Check your internet.');
    } on StateError catch (error) {
      showError(error.message);
    } catch (error) {
      showError('Could not save the payment: $error');
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add payment - ${widget.plot.plotNumber}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Balance: ${_rs(widget.balancePaisa)}',
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 16),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: appInputDecoration(
                  label: 'Amount (Rs)',
                  hint: 'e.g. 500000',
                  prefixText: 'Rs ',
                ),
                validator: validateAmount,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    amountController.text = (widget.balancePaisa ~/ 100)
                        .toString();
                  },
                  child: const Text('Pay full balance'),
                ),
              ),
              const Text(
                'Method',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final option in PaymentMethod.values)
                    ChoiceChip(
                      label: Text(option.label),
                      selected: method == option,
                      onSelected: (_) {
                        setState(() {
                          method = option;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: referenceController,
                style: const TextStyle(fontSize: 16),
                inputFormatters: [LengthLimitingTextInputFormatter(30)],
                decoration: appInputDecoration(
                  label: 'Reference / Cheque no. (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: noteController,
                style: const TextStyle(fontSize: 16),
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
                decoration: appInputDecoration(
                  label: 'Note (optional)',
                  hint: 'e.g. first installment',
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorText!,
                  style: const TextStyle(color: _red, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: isSaving ? null : save,
                  child: Text(isSaving ? 'Saving...' : 'Save payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}