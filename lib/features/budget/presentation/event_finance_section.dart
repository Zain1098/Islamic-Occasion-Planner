import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/services/savings_service.dart';
import '../../../core/utils/identifier_generator.dart';
import '../../../features/dashboard/presentation/dashboard_provider.dart';
import '../../../shared/models/budget_item.dart';
import '../../../shared/models/saving_entry.dart';
import 'event_plan_provider.dart';

class EventFinanceSection extends ConsumerWidget {
  const EventFinanceSection({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(eventPlanProvider(eventId))
      .when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => Padding(
          padding: const EdgeInsets.all(24),
          child: TextButton(
            onPressed: () => ref.invalidate(eventPlanProvider(eventId)),
            child: const Text('Could not load plan. Try again'),
          ),
        ),
        data: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryCard(plan: data.savingsPlan),
            const SizedBox(height: 24),
            _Header(
              title: 'Planned expenses',
              action: 'Add category',
              onAction: () => _editBudget(context, ref),
            ),
            const SizedBox(height: 8),
            if (data.budgetItems.isEmpty)
              const _EmptyCard(
                message: 'Plan this occasion before the expense reaches you.',
              )
            else
              ...data.budgetItems.map(
                (item) => _BudgetRow(
                  item: item,
                  onEdit: () => _editBudget(context, ref, item: item),
                  onDelete: () => _deleteBudget(ref, item),
                ),
              ),
            const SizedBox(height: 24),
            _Header(
              title: 'Saving history',
              action: 'Add saving',
              onAction: () =>
                  _addSaving(context, ref, data.savingsPlan.savedAmount),
            ),
            const SizedBox(height: 8),
            if (data.savingEntries.isEmpty)
              const _EmptyCard(
                message: 'Record savings as you set money aside.',
              )
            else
              ...data.savingEntries.map(
                (entry) => _SavingRow(
                  entry: entry,
                  onDelete: () => _deleteSaving(ref, entry),
                ),
              ),
          ],
        ),
      );

  Future<void> _editBudget(
    BuildContext context,
    WidgetRef ref, {
    BudgetItem? item,
  }) async {
    final category = TextEditingController(text: item?.category ?? '');
    final amount = TextEditingController(
      text: item?.plannedAmount.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<(String, int)?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          item == null ? 'Add expense category' : 'Edit expense category',
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: category,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a category'
                    : null,
              ),
              TextFormField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Planned amount (PKR)',
                ),
                validator: (value) => _positiveAmount(value) == null
                    ? 'Enter an amount above zero'
                    : null,
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
                Navigator.pop(context, (
                  category.text.trim(),
                  _positiveAmount(amount.text)!,
                ));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    category.dispose();
    amount.dispose();
    if (result == null) return;
    final savedItem = BudgetItem(
      id: item?.id ?? IdentifierGenerator().next('budget'),
      eventId: eventId,
      category: result.$1,
      plannedAmount: result.$2,
      actualAmount: item?.actualAmount,
    );
    await ref.read(budgetRepositoryProvider).save(savedItem);
    _refresh(ref);
  }

  Future<void> _deleteBudget(WidgetRef ref, BudgetItem item) async {
    await ref.read(budgetRepositoryProvider).delete(item.id);
    _refresh(ref);
  }

  Future<void> _addSaving(
    BuildContext context,
    WidgetRef ref,
    int currentSaved,
  ) async {
    final amount = TextEditingController();
    final note = TextEditingController();
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
                  controller: amount,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (PKR)'),
                  validator: (value) {
                    final parsed = _positiveAmount(value);
                    if (parsed == null) {
                      return 'Enter an amount above zero';
                    }
                    if (type == SavingEntryType.subtract &&
                        parsed > currentSaved) {
                      return 'Cannot subtract more than saved';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: note,
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
                  Navigator.pop(context, (
                    type,
                    _positiveAmount(amount.text)!,
                    note.text.trim().isEmpty ? null : note.text.trim(),
                  ));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    amount.dispose();
    note.dispose();
    if (result == null) return;
    await ref
        .read(savingRepositoryProvider)
        .save(
          SavingEntry(
            id: IdentifierGenerator().next('saving'),
            eventId: eventId,
            amount: result.$2,
            entryType: result.$1,
            createdAt: DateTime.now(),
            note: result.$3,
          ),
        );
    _refresh(ref);
  }

  Future<void> _deleteSaving(WidgetRef ref, SavingEntry entry) async {
    await ref.read(savingRepositoryProvider).delete(entry.id);
    _refresh(ref);
  }

  void _refresh(WidgetRef ref) {
    ref.invalidate(eventPlanProvider(eventId));
    ref.invalidate(dashboardProvider);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.plan});

  final SavingsPlan plan;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Savings progress',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: plan.progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 12),
          Text(
            'Rs ${_formatAmount(plan.savedAmount)} saved of Rs ${_formatAmount(plan.targetAmount)}',
          ),
          const SizedBox(height: 4),
          Text(
            plan.isOverdue
                ? 'This occasion has passed.'
                : '${plan.daysRemaining} days left · Rs ${_formatAmount(plan.remainingAmount)} remaining',
          ),
          if (plan.targetAmount > 0 &&
              !plan.isOverdue &&
              plan.remainingAmount > 0) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _RateChip(label: 'Daily', amount: plan.perDay),
                _RateChip(label: 'Weekly', amount: plan.perWeek),
                _RateChip(label: 'Monthly', amount: plan.perMonth),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

class _RateChip extends StatelessWidget {
  const _RateChip({required this.label, required this.amount});
  final String label;
  final int amount;
  @override
  Widget build(BuildContext context) =>
      Chip(label: Text('$label: Rs ${_formatAmount(amount)}'));
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });
  final BudgetItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(item.category),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Rs ${_formatAmount(item.plannedAmount)}'),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    ),
  );
}

class _SavingRow extends StatelessWidget {
  const _SavingRow({required this.entry, required this.onDelete});
  final SavingEntry entry;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final added = entry.entryType == SavingEntryType.add;
    return Card(
      child: ListTile(
        leading: Icon(
          added ? Icons.add_circle_outline : Icons.remove_circle_outline,
        ),
        title: Text('${added ? '+' : '-'} Rs ${_formatAmount(entry.amount)}'),
        subtitle: Text(
          entry.note ??
              '${entry.createdAt.day}/${entry.createdAt.month}/${entry.createdAt.year}',
        ),
        trailing: IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.action,
    required this.onAction,
  });
  final String title;
  final String action;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      TextButton.icon(
        onPressed: onAction,
        icon: const Icon(Icons.add),
        label: Text(action),
      ),
    ],
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
  );
}

int? _positiveAmount(String? value) {
  final amount = int.tryParse(value?.trim() ?? '');
  return amount == null || amount <= 0 ? null : amount;
}

String _formatAmount(int amount) => amount.toString().replaceAllMapped(
  RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'),
  (match) => ',',
);
