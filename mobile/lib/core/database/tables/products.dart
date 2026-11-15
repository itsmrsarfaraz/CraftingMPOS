import 'package:drift/drift.dart';

import 'business_settings.dart';
// ignore: unused_import
import 'categories.dart';

@TableIndex(name: 'products_business_id_index', columns: {#businessId})
@TableIndex(
  name: 'products_business_id_id_unique',
  columns: {#businessId, #id},
  unique: true,
)
class Products extends Table {
  TextColumn get id => text()();

  TextColumn get businessId =>
      text().references(BusinessSettings, #id, onDelete: KeyAction.cascade)();

  TextColumn get categoryId => text().nullable()();

  TextColumn get name => text().withLength(min: 2, max: 150)();

  TextColumn get description => text().nullable()();

  TextColumn get imagePath => text().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, category_id) '
        'REFERENCES categories (business_id, id) '
        'ON DELETE RESTRICT',
  ];
}
