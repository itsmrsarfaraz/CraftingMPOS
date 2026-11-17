import 'package:drift/drift.dart';

import 'branches.dart';
import 'users.dart';

@TableIndex(name: 'user_branches_branch_id_index', columns: {#branchId})
class UserBranches extends Table {
  TextColumn get userId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();

  TextColumn get branchId =>
      text().references(Branches, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId, branchId};
}
