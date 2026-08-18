import 'dart:math';

class IdentifierGenerator {
  IdentifierGenerator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  String next(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${_random.nextInt(1 << 32).toRadixString(36)}';
}
