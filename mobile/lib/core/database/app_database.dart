import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/business_settings.dart';
import 'tables/branches.dart';
import 'tables/users.dart';
import 'tables/roles.dart';
import 'tables/permissions.dart';
import 'tables/role_permissions.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    BusinessSettings,
    Branches,
    Users,
    Roles,
    Permissions,
    RolePermissions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'crafting_mpos'));

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (Migrator migrator, int from, int to) async {
      if (from < 2) {
        await migrator.createTable(branches);
      }

      if (from < 3) {
        await migrator.createIndex(branchesBusinessCodeUnique);
      }

      if (from < 4) {
        await migrator.createTable(users);
        await migrator.createIndex(usersBusinessUsernameUnique);
      }

      if (from < 5) {
        await migrator.createTable(roles);
        await migrator.createIndex(rolesBusinessSlugUnique);
      }

      if (from < 6) {
        await migrator.createTable(permissions);
        await migrator.createIndex(permissionsSlugUnique);
      }

      if (from < 7) {
        await migrator.createTable(rolePermissions);
        await migrator.createIndex(rolePermissionsPermissionIdIndex);
      }
    },
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<int> createBusinessSettings(BusinessSettingsCompanion settings) {
    return into(businessSettings).insert(settings);
  }

  Future<List<BusinessSetting>> getAllBusinessSettings() {
    return select(businessSettings).get();
  }

  Future<int> createBranch(BranchesCompanion branch) {
    return into(branches).insert(branch);
  }

  Future<List<Branche>> getBranchesForBusiness(String businessId) {
    return (select(
      branches,
    )..where((branch) => branch.businessId.equals(businessId))).get();
  }

  Future<int> createUser(UsersCompanion user) {
    return into(users).insert(user);
  }

  Future<List<User>> getUsersForBusiness(String businessId) {
    return (select(
      users,
    )..where((user) => user.businessId.equals(businessId))).get();
  }

  Future<User?> getUserByUsername(String businessId, String username) {
    return (select(users)..where(
          (user) =>
              user.businessId.equals(businessId) &
              user.username.equals(username),
        ))
        .getSingleOrNull();
  }

  Future<int> createRole(RolesCompanion role) {
    return into(roles).insert(role);
  }

  Future<List<Role>> getRolesForBusiness(String businessId) {
    return (select(
      roles,
    )..where((role) => role.businessId.equals(businessId))).get();
  }

  Future<Role?> getRoleBySlug(String businessId, String slug) {
    return (select(roles)..where(
          (role) => role.businessId.equals(businessId) & role.slug.equals(slug),
        ))
        .getSingleOrNull();
  }

  Future<int> createPermission(PermissionsCompanion permission) {
    return into(permissions).insert(permission);
  }

  Future<List<Permission>> getAllPermissions() {
    return select(permissions).get();
  }

  Future<List<Permission>> getPermissionsByModule(String module) {
    return (select(
      permissions,
    )..where((permission) => permission.module.equals(module))).get();
  }

  Future<int> assignPermissionToRole(RolePermissionsCompanion assignment) {
    return into(rolePermissions).insert(assignment);
  }

  Future<List<RolePermission>> getPermissionsForRole(String roleId) {
    return (select(
      rolePermissions,
    )..where((assignment) => assignment.roleId.equals(roleId))).get();
  }

  Future<int> removePermissionFromRole(String roleId, String permissionId) {
    return (delete(rolePermissions)..where(
          (assignment) =>
              assignment.roleId.equals(roleId) &
              assignment.permissionId.equals(permissionId),
        ))
        .go();
  }

  Future<bool> roleHasPermission(String roleId, String permissionId) async {
    final assignment =
        await (select(rolePermissions)..where(
              (item) =>
                  item.roleId.equals(roleId) &
                  item.permissionId.equals(permissionId),
            ))
            .getSingleOrNull();

    return assignment != null;
  }
}
