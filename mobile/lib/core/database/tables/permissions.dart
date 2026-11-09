import 'package:drift/drift.dart';

@TableIndex(name: 'permissions_slug_unique', columns: {#slug}, unique: true)
class Permissions extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 2, max: 100)();

  TextColumn get slug => text().withLength(min: 3, max: 120)();

  TextColumn get module => text().withLength(min: 2, max: 50)();

  TextColumn get description => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
