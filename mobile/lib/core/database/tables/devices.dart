import 'package:drift/drift.dart';

import 'business_settings.dart';

@TableIndex(name: 'devices_business_id_index', columns: {#businessId})
class Devices extends Table {
  TextColumn get id => text()();

  TextColumn get businessId =>
      text().references(BusinessSettings, #id, onDelete: KeyAction.cascade)();

  TextColumn get deviceName => text().withLength(min: 2, max: 100)();

  TextColumn get deviceType => text().withDefault(const Constant('android'))();

  TextColumn get deviceIdentifier => text().withLength(min: 10, max: 255)();

  TextColumn get publicKey => text()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get registeredAt => dateTime()();

  DateTimeColumn get lastSeenAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {businessId, deviceIdentifier},
  ];
}
