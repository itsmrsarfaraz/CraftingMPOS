import 'package:drift/drift.dart';

class BusinessSettings extends Table {
  TextColumn get id => text()();

  TextColumn get businessName => text().withLength(min: 2, max: 150)();

  TextColumn get currencyCode => text().withDefault(const Constant('PKR'))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
