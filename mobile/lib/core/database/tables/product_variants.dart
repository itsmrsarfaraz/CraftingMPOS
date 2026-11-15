import 'package:drift/drift.dart';

// ignore: unused_import
import 'products.dart';

@TableIndex(
  name: 'product_variants_business_sku_unique',
  columns: {#businessId, #sku},
  unique: true,
)
@TableIndex(
  name: 'product_variants_business_product_index',
  columns: {#businessId, #productId},
)
@TableIndex(
  name: 'product_variants_business_id_id_unique',
  columns: {#businessId, #id},
  unique: true,
)
class ProductVariants extends Table {
  TextColumn get id => text()();

  TextColumn get businessId => text()();

  TextColumn get productId => text()();

  TextColumn get name => text().withLength(min: 1, max: 150)();

  TextColumn get sku => text().nullable()();

  TextColumn get attributes => text().nullable()();

  IntColumn get costPrice => integer()();

  IntColumn get sellingPrice => integer()();

  TextColumn get unit => text().withDefault(const Constant('piece'))();

  BoolColumn get trackStock => boolean().withDefault(const Constant(true))();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, product_id) '
        'REFERENCES products (business_id, id) '
        'ON DELETE CASCADE',
    'CHECK (cost_price >= 0)',
    'CHECK (selling_price >= 0)',
  ];
}
