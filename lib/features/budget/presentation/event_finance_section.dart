import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/planner_data_refresh.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/services/savings_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/identifier_generator.dart';
import '../../../shared/models/budget_item.dart';
import '../../../shared/models/saving_entry.dart';
import '../../savings/presentation/add_saving_dialog.dart';
import 'event_plan_provider.dart';

const _presetCategories = [
  'Niaz',
  'Lighting',
  'Decoration',
  'Dawat',
  'Sadqah',
  'Clothes',
  'Qurbani',
  'Transport',
  'Other',
];

class EventFinanceSection extends ConsumerWidget {
  const EventFinanceSection({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).value;
    final currencyCode = settings?.currencyCode ?? 'PKR';

    return ref.watch(eventPlanProvider(eventId)).when(
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
              _SummaryCard(
                plan: data.savingsPlan,
                currencyCode: currencyCode,
              ),
              const SizedBox(height: 24),
              _Header(
                title: 'Planned expenses',
                action: 'Add category',
                onAction: () => _editBudget(context, ref, currencyCode: currencyCode),
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
                    currencyCode: currencyCode,
                    onEdit: () => _editBudget(
                      context,
                      ref,
                      currencyCode: currencyCode,
                      item: item,
                    ),
                    onDelete: () => _deleteBudget(context, ref, item),
                  ),
                ),
              const SizedBox(height: 24),
              _Header(
                title: 'Saving history',
                action: 'Add saving',
                onAction: () => showAddSavingDialog(
                  context: context,
                  ref: ref,
                  eventId: eventId,
                  currencyCode: currencyCode,
                  currentSaved: data.savingsPlan.savedAmount,
                ),
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
                    currencyCode: currencyCode,
                    onDelete: () => _deleteSaving(context, ref, entry),
                  ),
                ),
            ],
          ),
        );
  }

  Future<void> _editBudget(
    BuildContext context,
    WidgetRef ref, {
    required String currencyCode,
    BudgetItem? item,
  }) async {
    final category = TextEditingController(text: item?.category ?? '');
    final amount = TextEditingController(
      text: item?.plannedAmount.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<(String, int)?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            item == null ? 'Add expense category' : 'Edit expense category',
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: category,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Category'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a category'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Presets',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _presetCategories.map((preset) {
                      final selected = category.text.trim().toLowerCase() == preset.toLowerCase();
                      return ChoiceChip(
                        label: Text(preset, style: const TextStyle(fontSize: 12)),
                        selected: selected,
                        onSelected: (val) {
                          setState(() {
                            category.text = preset;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amount,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Planned amount (${currencyCode.toUpperCase()})',
                    ),
                    validator: (value) => _positiveAmount(value) == null
                        ? 'Enter an amount above zero'
                        : null,
                  ),
                ],
              ),
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

  Future<void> _deleteBudget(
    BuildContext context,
    WidgetRef ref,
    BudgetItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense category?'),
        content: Text('Are you sure you want to delete "${item.category}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(budgetRepositoryProvider).delete(item.id);
    _refresh(ref);
  }

  Future<void> _deleteSaving(
    BuildContext context,
    WidgetRef ref,
    SavingEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete saving entry?'),
        content: const Text('Are you sure you want to remove this saving record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(savingRepositoryProvider).delete(entry.id);
    _refresh(ref);
  }

  void _refresh(WidgetRef ref) {
    refreshPlannerData(ref);
    ref.read(reminderCoordinatorProvider).rescheduleByEventId(eventId);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.plan,
    required this.currencyCode,
  });

  final SavingsPlan plan;
  final String currencyCode;

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
            '${formatCurrency(plan.savedAmount, currencyCode)} saved of ${formatCurrency(plan.targetAmount, currencyCode)}',
          ),
          const SizedBox(height: 4),
          Text(
            plan.isOverdue
                ? 'This occasion has passed.'
                : '${plan.daysRemaining} days left · ${formatCurrency(plan.remainingAmount, currencyCode)} remaining',
          ),
          if (plan.targetAmount > 0 &&
              !plan.isOverdue &&
              plan.remainingAmount > 0) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _RateChip(label: 'Daily', amount: plan.perDay, currencyCode: currencyCode),
                _RateChip(label: 'Weekly', amount: plan.perWeek, currencyCode: currencyCode),
                _RateChip(label: 'Monthly', amount: plan.perMonth, currencyCode: currencyCode),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

class _RateChip extends StatelessWidget {
  const _RateChip({
    required this.label,
    required this.amount,
    required this.currencyCode,
  });

  final String label;
  final int amount;
  final String currencyCode;

  @override
  Widget build(BuildContext context) =>
      Chip(label: Text('$label: ${formatCurrency(amount, currencyCode)}'));
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.item,
    required this.currencyCode,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetItem item;
  final String currencyCode;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(item.category),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatCurrency(item.plannedAmount, currencyCode)),
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
  const _SavingRow({
    required this.entry,
    required this.currencyCode,
    required this.onDelete,
  });

  final SavingEntry entry;
  final String currencyCode;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final added = entry.entryType == SavingEntryType.add;
    return Card(
      child: ListTile(
        leading: Icon(
          added ? Icons.add_circle_outline : Icons.remove_circle_outline,
        ),
        title: Text('${added ? '+' : '-'} ${formatCurrency(entry.amount, currencyCode)}'),
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
