class OfficialHijriMonth {
  const OfficialHijriMonth({
    required this.year,
    required this.month,
    required this.startsOn,
    required this.authorityName,
    required this.sourceUrl,
    required this.announcedAt,
  });

  final int year;
  final int month;
  final DateTime startsOn;
  final String authorityName;
  final Uri sourceUrl;
  final DateTime announcedAt;

  factory OfficialHijriMonth.fromMap(Map<String, dynamic> map) {
    final startsOn = DateTime.tryParse(map['starts_on'] as String? ?? '');
    final announcedAt = DateTime.tryParse(map['announced_at'] as String? ?? '');
    final sourceUrl = Uri.tryParse(map['source_url'] as String? ?? '');
    final year = map['hijri_year'] as int?;
    final month = map['hijri_month'] as int?;
    final authorityName = map['authority_name'] as String?;

    if (startsOn == null ||
        announcedAt == null ||
        sourceUrl == null ||
        !sourceUrl.hasScheme ||
        year == null ||
        month == null ||
        authorityName == null ||
        authorityName.isEmpty) {
      throw const FormatException('Invalid official Hijri month record.');
    }

    return OfficialHijriMonth(
      year: year,
      month: month,
      startsOn: DateTime(startsOn.year, startsOn.month, startsOn.day),
      authorityName: authorityName,
      sourceUrl: sourceUrl,
      announcedAt: announcedAt,
    );
  }
}
