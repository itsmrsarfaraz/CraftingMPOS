import 'package:drift/drift.dart';

import 'business_settings.dart';

@TableIndex(
  name: 'branches_business_code_unique',
  columns: {#businessId, #code},
  unique: true,
)
class Branches extends Table {
  TextColumn get id => text()();

  TextColumn get businessId => text().references(BusinessSettings, #id)();

  TextColumn get name => text().withLength(min: 2, max: 100)();

  TextColumn get code => text().withLength(min: 1, max: 30)();

  TextColumn get address => text().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
