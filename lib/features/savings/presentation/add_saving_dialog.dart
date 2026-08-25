import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/planner_data_refresh.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/identifier_generator.dart';
import '../../../shared/models/saving_entry.dart';

Future<void> showAddSavingDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String eventId,
  required String currencyCode,
  int currentSaved = 0,
}) async {
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  var type = SavingEntryType.add;
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<(SavingEntryType, int, String?)?>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Record saving'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<SavingEntryType>(
                segments: const [
                  ButtonSegment(
                    value: SavingEntryType.add,
                    label: Text('Add'),
                  ),
                  ButtonSegment(
                    value: SavingEntryType.subtract,
                    label: Text('Subtract'),
                  ),
                ],
                selected: {type},
                onSelectionChanged: (value) =>
                    setState(() => type = value.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (${currencyCode.toUpperCase()})',
                ),
                validator: (value) {
                  final amount = int.tryParse(value?.trim() ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Enter an amount above zero';
                  }
                  if (type == SavingEntryType.subtract && amount > currentSaved) {
                    return 'Cannot subtract more than saved';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final amount = int.parse(amountController.text.trim());
                final note = noteController.text.trim();
                Navigator.pop(
                  context,
                  (type, amount, note.isEmpty ? null : note),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );

  amountController.dispose();
  noteController.dispose();

  if (result == null) return;

  await ref.read(savingRepositoryProvider).save(
        SavingEntry(
          id: IdentifierGenerator().next('saving'),
          eventId: eventId,
          amount: result.$2,
          entryType: result.$1,
          createdAt: DateTime.now(),
          note: result.$3,
        ),
      );

  refreshPlannerData(ref);
  await ref.read(reminderCoordinatorProvider).rescheduleByEventId(eventId);
}
