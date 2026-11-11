
import 'package:drift/drift.dart';

import 'roles.dart';
import 'users.dart';

@TableIndex(
  name: 'user_roles_role_id_index',
  columns: {#roleId},
)
class UserRoles extends Table {
  TextColumn get userId => text().references(
        Users,
        #id,
        onDelete: KeyAction.cascade,
      )();

  TextColumn get roleId => text().references(
        Roles,
        #id,
        onDelete: KeyAction.cascade,
      )();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {
        userId,
        roleId,
      };
}
