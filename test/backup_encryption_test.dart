import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_occasion_planner/core/services/backup_encryption.dart';

void main() {
  test('encrypted backup round-trips only with its PIN', () async {
    final encryption = BackupEncryption();
    final encrypted = await encryption.encrypt('{"schemaVersion":1}', 'safe-pin-123');

    await expectLater(encryption.decrypt(encrypted, 'wrong-pin'), throwsFormatException);
    await expectLater(encryption.decrypt(encrypted, 'safe-pin-123'), completion('{"schemaVersion":1}'));
  });
}
