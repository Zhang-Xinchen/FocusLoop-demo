import 'package:uuid/uuid.dart';

import 'database.dart';

Future<String> ensureDeviceId(AppDatabase db) async {
  const key = 'device_id';
  final existing =
      await (db.select(db.meta)..where((m) => m.key.equals(key))).getSingleOrNull();
  if (existing != null) {
    return existing.value;
  }
  final id = const Uuid().v4();
  await db.into(db.meta).insert(MetaCompanion.insert(key: key, value: id));
  return id;
}
