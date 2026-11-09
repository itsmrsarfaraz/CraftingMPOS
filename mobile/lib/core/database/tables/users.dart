import 'package:drift/drift.dart';

import 'business_settings.dart';

@TableIndex(
  name: 'users_business_username_unique',
  columns: {#businessId, #username},
  unique: true,
)
class Users extends Table {
  TextColumn get id => text()();

  TextColumn get businessId => text().references(BusinessSettings, #id)();

  TextColumn get username => text().withLength(min: 3, max: 50)();

  TextColumn get displayName => text().withLength(min: 2, max: 100)();

  TextColumn get email => text().nullable()();

  TextColumn get phone => text().nullable()();

  TextColumn get passwordHash => text()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
