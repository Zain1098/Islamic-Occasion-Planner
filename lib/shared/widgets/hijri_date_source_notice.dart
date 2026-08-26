import 'package:flutter/material.dart';

/// Makes the origin of the shown Hijri date explicit without claiming that a
/// locally calculated fallback is a religious confirmation.
class HijriDateSourceNotice extends StatelessWidget {
  const HijriDateSourceNotice({super.key, required this.isOfficial});

  final bool isOfficial;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = isOfficial
        ? 'Official Pakistan confirmation'
        : 'Calculated fallback - moon sighting may vary';
    return Semantics(
      label: isOfficial
          ? 'Official Pakistan Hijri date confirmation'
          : 'Calculated Hijri date fallback',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isOfficial
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOfficial ? Icons.verified_outlined : Icons.calculate_outlined,
              size: 18,
              color: isOfficial
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
