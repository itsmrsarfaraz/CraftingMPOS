import 'package:drift/drift.dart';

import 'business_settings.dart';

@TableIndex(
  name: 'categories_business_name_unique',
  columns: {#businessId, #name},
  unique: true,
)
@TableIndex(
  name: 'categories_business_id_id_unique',
  columns: {#businessId, #id},
  unique: true,
)
class Categories extends Table {
  TextColumn get id => text()();

  TextColumn get businessId =>
      text().references(BusinessSettings, #id, onDelete: KeyAction.cascade)();

  TextColumn get name => text().withLength(min: 2, max: 100)();

  TextColumn get description => text().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
