import 'package:drift/drift.dart';

// ignore: unused_import
import 'branches.dart';
// ignore: unused_import
import 'product_variants.dart';

@TableIndex(
  name: 'branch_stocks_branch_variant_unique',
  columns: {#branchId, #variantId},
  unique: true,
)
@TableIndex(name: 'branch_stocks_business_id_index', columns: {#businessId})
class BranchStocks extends Table {
  TextColumn get id => text()();

  TextColumn get businessId => text()();

  TextColumn get branchId => text()();

  TextColumn get variantId => text()();

  IntColumn get quantityMilliunits =>
      integer().withDefault(const Constant(0))();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, branch_id) '
        'REFERENCES branches (business_id, id) '
        'ON DELETE CASCADE',
    'FOREIGN KEY (business_id, variant_id) '
        'REFERENCES product_variants (business_id, id) '
        'ON DELETE CASCADE',
  ];
}
