import 'package:drift/drift.dart';

// ignore: unused_import
import 'product_variants.dart';

@TableIndex(
  name: 'product_codes_business_code_unique',
  columns: {#businessId, #code},
  unique: true,
)
@TableIndex(
  name: 'product_codes_business_variant_index',
  columns: {#businessId, #variantId},
)
class ProductCodes extends Table {
  TextColumn get id => text()();

  TextColumn get businessId => text()();

  TextColumn get variantId => text()();

  TextColumn get code => text().withLength(min: 1, max: 255)();

  TextColumn get codeType => text().withDefault(const Constant('CODE128'))();

  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, variant_id) '
        'REFERENCES product_variants (business_id, id) '
        'ON DELETE CASCADE',
  ];
}
