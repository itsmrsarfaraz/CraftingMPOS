import 'package:drift/drift.dart';

import 'business_settings.dart';

@TableIndex(
  name: 'roles_business_slug_unique',
  columns: {#businessId, #slug},
  unique: true,
)
class Roles extends Table {
  TextColumn get id => text()();

  TextColumn get businessId => text().references(BusinessSettings, #id)();

  TextColumn get name => text().withLength(min: 2, max: 80)();

  TextColumn get slug => text().withLength(min: 2, max: 100)();

  TextColumn get description => text().nullable()();

  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
