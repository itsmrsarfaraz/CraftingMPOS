import 'package:drift/drift.dart';

import 'permissions.dart';
import 'roles.dart';

@TableIndex(
  name: 'role_permissions_permission_id_index',
  columns: {#permissionId},
)
class RolePermissions extends Table {
  TextColumn get roleId =>
      text().references(Roles, #id, onDelete: KeyAction.cascade)();

  TextColumn get permissionId =>
      text().references(Permissions, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {roleId, permissionId};
}
