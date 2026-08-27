/// Utility function for formatting amounts with currency symbol according to settings.
String formatCurrency(int amount, String currencyCode) {
  final formattedNumber = amount.toString().replaceAllMapped(
    RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  final symbol = switch (currencyCode.toUpperCase()) {
    'PKR' => 'Rs',
    'USD' => '\$',
    'EUR' => '€',
    'GBP' => '£',
    'INR' => '₹',
    'SAR' => 'SR',
    'AED' => 'AED',
    _ => currencyCode,
  };
  return '$symbol $formattedNumber';
}
