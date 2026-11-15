import 'package:drift/drift.dart';

// ignore: unused_import
import 'branches.dart';
// ignore: unused_import
import 'product_variants.dart';

@TableIndex(
  name: 'stock_movements_business_branch_created_index',
  columns: {#businessId, #branchId, #createdAt},
)
@TableIndex(
  name: 'stock_movements_business_variant_created_index',
  columns: {#businessId, #variantId, #createdAt},
)
@TableIndex(
  name: 'stock_movements_transfer_group_index',
  columns: {#transferGroupId},
)
@TableIndex(
  name: 'stock_movements_reference_index',
  columns: {#businessId, #referenceType, #referenceId},
)
class StockMovements extends Table {
  TextColumn get id => text()();

  TextColumn get businessId => text()();

  TextColumn get branchId => text()();

  TextColumn get variantId => text()();

  TextColumn get movementType => text()();

  IntColumn get quantityDeltaMilliunits => integer()();

  IntColumn get unitCostPaisa => integer().nullable()();

  TextColumn get referenceType => text().nullable()();

  TextColumn get referenceId => text().nullable()();

  TextColumn get transferGroupId => text().nullable()();

  TextColumn get note => text().nullable()();

  TextColumn get createdByUserId => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, branch_id) '
        'REFERENCES branches (business_id, id) '
        'ON DELETE RESTRICT',
    'FOREIGN KEY (business_id, variant_id) '
        'REFERENCES product_variants (business_id, id) '
        'ON DELETE RESTRICT',
    'CHECK (quantity_delta_milliunits != 0)',
    'CHECK (unit_cost_paisa IS NULL OR unit_cost_paisa >= 0)',
    "CHECK (movement_type IN ("
        "'opening', "
        "'purchase', "
        "'sale', "
        "'adjustment_in', "
        "'adjustment_out', "
        "'transfer_in', "
        "'transfer_out', "
        "'customer_return', "
        "'supplier_return', "
        "'damage'"
        '))',
    "CHECK ("
        "(movement_type IN ("
        "'opening', 'purchase', 'adjustment_in', "
        "'transfer_in', 'customer_return'"
        ") AND quantity_delta_milliunits > 0) "
        "OR "
        "(movement_type IN ("
        "'sale', 'adjustment_out', 'transfer_out', "
        "'supplier_return', 'damage'"
        ") AND quantity_delta_milliunits < 0)"
        ')',
    "CHECK ("
        "(movement_type IN ('transfer_in', 'transfer_out') "
        "AND transfer_group_id IS NOT NULL) "
        "OR "
        "(movement_type NOT IN ('transfer_in', 'transfer_out') "
        "AND transfer_group_id IS NULL)"
        ')',
  ];
}
