import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_occasion_planner/core/services/official_hijri_month.dart';

void main() {
  test('parses a confirmed Ruet-e-Hilal record', () {
    final record = OfficialHijriMonth.fromMap({
      'hijri_year': 1448,
      'hijri_month': 3,
      'starts_on': '2026-08-15',
      'authority_name': 'Central Ruet-e-Hilal Committee Pakistan',
      'source_url': 'https://example.gov.pk/announcement',
      'announced_at': '2026-08-14T18:00:00Z',
    });

    expect(record.year, 1448);
    expect(record.month, 3);
    expect(record.startsOn, DateTime(2026, 8, 15));
    expect(record.authorityName, contains('Ruet-e-Hilal'));
  });

  test('rejects an incomplete official record', () {
    expect(
      () => OfficialHijriMonth.fromMap(const {'hijri_year': 1448}),
      throwsFormatException,
    );
  });
}
