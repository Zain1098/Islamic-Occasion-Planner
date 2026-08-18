import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/providers/repository_providers.dart';
import 'core/storage/hive_app_storage.dart';
import 'features/events/data/hive_event_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await HiveAppStorage.open();
  final events = HiveEventRepository(storage);
  await events.seedDefaults();
  runApp(
    ProviderScope(
      overrides: [appStorageProvider.overrideWithValue(storage)],
      child: const IslamicOccasionPlannerApp(),
    ),
  );
}
