import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:crafting_mpos/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> createRoleFixture() async {
    final now = DateTime.now();

    await database.createBusinessSettings(
      BusinessSettingsCompanion.insert(
        id: 'business-001',
        businessName: 'Test Business',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createRole(
      RolesCompanion.insert(
        id: 'role-001',
        businessId: 'business-001',
        name: 'Cashier',
        slug: 'cashier',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> createPermissionFixture() async {
    await database.createPermission(
      PermissionsCompanion.insert(
        id: 'permission-001',
        name: 'View Products',
        slug: 'products.view',
        module: 'Products',
        createdAt: DateTime.now(),
      ),
    );
  }

  test('Database can save and retrieve business settings', () async {
    final now = DateTime.now();

    await database.createBusinessSettings(
      BusinessSettingsCompanion.insert(
        id: 'business-001',
        businessName: 'Crafting Store',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final businesses = await database.getAllBusinessSettings();

    expect(businesses, hasLength(1));
    expect(businesses.first.id, 'business-001');
    expect(businesses.first.businessName, 'Crafting Store');
    expect(businesses.first.currencyCode, 'PKR');
  });

  test('A business can have multiple branches', () async {
    final now = DateTime.now();

    await database.createBusinessSettings(
      BusinessSettingsCompanion.insert(
        id: 'business-001',
        businessName: 'Crafting Store',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createBranch(
      BranchesCompanion.insert(
        id: 'branch-001',
        businessId: 'business-001',
        name: 'Main Branch',
        code: 'MAIN-001',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createBranch(
      BranchesCompanion.insert(
        id: 'branch-002',
        businessId: 'business-001',
        name: 'Second Branch',
        code: 'BR-002',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final branches = await database.getBranchesForBusiness('business-001');

    expect(branches, hasLength(2));
    expect(branches[0].businessId, 'business-001');
    expect(branches[1].businessId, 'business-001');
  });

  test('A business cannot have duplicate branch codes', () async {
    final now = DateTime.now();

    await database.createBusinessSettings(
      BusinessSettingsCompanion.insert(
        id: 'business-001',
        businessName: 'Crafting Store',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createBranch(
      BranchesCompanion.insert(
        id: 'branch-001',
        businessId: 'business-001',
        name: 'Main Branch',
        code: 'MAIN',
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect(
      database.createBranch(
        BranchesCompanion.insert(
          id: 'branch-002',
          businessId: 'business-001',
          name: 'Second Branch',
          code: 'MAIN',
          createdAt: now,
          updatedAt: now,
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('Different businesses can reuse the same branch code', () async {
    final now = DateTime.now();

    await database.createBusinessSettings(
      BusinessSettingsCompanion.insert(
        id: 'business-001',
        businessName: 'First Store',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createBusinessSettings(
      BusinessSettingsCompanion.insert(
        id: 'business-002',
        businessName: 'Second Store',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createBranch(
      BranchesCompanion.insert(
        id: 'branch-001',
        businessId: 'business-001',
        name: 'Main Branch',
        code: 'MAIN',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createBranch(
      BranchesCompanion.insert(
        id: 'branch-002',
        businessId: 'business-002',
        name: 'Main Branch',
        code: 'MAIN',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final firstBusinessBranches = await database.getBranchesForBusiness(
      'business-001',
    );

    final secondBusinessBranches = await database.getBranchesForBusiness(
      'business-002',
    );

    expect(firstBusinessBranches, hasLength(1));
    expect(secondBusinessBranches, hasLength(1));
  });

  test('Database can create and retrieve a user', () async {
    final now = DateTime.now();

    await database.createBusinessSettings(
      BusinessSettingsCompanion.insert(
        id: 'business-001',
        businessName: 'Crafting Store',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createUser(
      UsersCompanion.insert(
        id: 'user-001',
        businessId: 'business-001',
        username: 'admin',
        displayName: 'Store Administrator',
        passwordHash: 'test-password-hash',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final user = await database.getUserByUsername('business-001', 'admin');

    expect(user, isNotNull);
    expect(user!.id, 'user-001');
    expect(user.username, 'admin');
    expect(user.displayName, 'Store Administrator');
    expect(user.isActive, isTrue);
  });

  test('Users are isolated between businesses', () async {
    final now = DateTime.now();

    await database.createBusinessSettings(
      BusinessSettingsCompanion.insert(
        id: 'business-001',
        businessName: 'First Store',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createBusinessSettings(
      BusinessSettingsCompanion.insert(
        id: 'business-002',
        businessName: 'Second Store',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createUser(
      UsersCompanion.insert(
        id: 'user-001',
        businessId: 'business-001',
        username: 'admin',
        displayName: 'First Administrator',
        passwordHash: 'test-hash-1',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createUser(
      UsersCompanion.insert(
        id: 'user-002',
        businessId: 'business-002',
        username: 'admin',
        displayName: 'Second Administrator',
        passwordHash: 'test-hash-2',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final firstUser = await database.getUserByUsername('business-001', 'admin');

    final secondUser = await database.getUserByUsername(
      'business-002',
      'admin',
    );

    expect(firstUser!.id, 'user-001');
    expect(secondUser!.id, 'user-002');
  });

  test('Database retrieves users for a specific business', () async {
    final now = DateTime.now();

    await database.createBusinessSettings(
      BusinessSettingsCompanion.insert(
        id: 'business-001',
        businessName: 'Crafting Store',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createUser(
      UsersCompanion.insert(
        id: 'user-001',
        businessId: 'business-001',
        username: 'admin',
        displayName: 'Administrator',
        passwordHash: 'test-hash-1',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createUser(
      UsersCompanion.insert(
        id: 'user-002',
        businessId: 'business-001',
        username: 'cashier',
        displayName: 'Store Cashier',
        passwordHash: 'test-hash-2',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final users = await database.getUsersForBusiness('business-001');

    expect(users, hasLength(2));
  });

  test('A business cannot have duplicate usernames', () async {
    final now = DateTime.now();

    await database.createBusinessSettings(
      BusinessSettingsCompanion.insert(
        id: 'business-001',
        businessName: 'Crafting Store',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createUser(
      UsersCompanion.insert(
        id: 'user-001',
        businessId: 'business-001',
        username: 'admin',
        displayName: 'Administrator',
        passwordHash: 'test-hash-1',
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect(
      database.createUser(
        UsersCompanion.insert(
          id: 'user-002',
          businessId: 'business-001',
          username: 'admin',
          displayName: 'Another Administrator',
          passwordHash: 'test-hash-2',
          createdAt: now,
          updatedAt: now,
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('Database can create and retrieve a role', () async {
    final now = DateTime.now();

    await database.createBusinessSettings(
      BusinessSettingsCompanion.insert(
        id: 'business-001',
        businessName: 'Crafting Store',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createRole(
      RolesCompanion.insert(
        id: 'role-001',
        businessId: 'business-001',
        name: 'Store Manager',
        slug: 'store-manager',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final role = await database.getRoleBySlug('business-001', 'store-manager');

    expect(role, isNotNull);
    expect(role!.id, 'role-001');
    expect(role.name, 'Store Manager');
    expect(role.slug, 'store-manager');
    expect(role.isSystem, isFalse);
    expect(role.isActive, isTrue);
  });

  test('Roles are isolated between businesses', () async {
    final now = DateTime.now();

    await database.createBusinessSettings(
      BusinessSettingsCompanion.insert(
        id: 'business-001',
        businessName: 'First Store',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createBusinessSettings(
      BusinessSettingsCompanion.insert(
        id: 'business-002',
        businessName: 'Second Store',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createRole(
      RolesCompanion.insert(
        id: 'role-001',
        businessId: 'business-001',
        name: 'Store Manager',
        slug: 'manager',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createRole(
      RolesCompanion.insert(
        id: 'role-002',
        businessId: 'business-002',
        name: 'Store Manager',
        slug: 'manager',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final firstRole = await database.getRoleBySlug('business-001', 'manager');

    final secondRole = await database.getRoleBySlug('business-002', 'manager');

    expect(firstRole!.id, 'role-001');
    expect(secondRole!.id, 'role-002');
  });

  test('Database retrieves roles for a specific business', () async {
    final now = DateTime.now();

    await database.createBusinessSettings(
      BusinessSettingsCompanion.insert(
        id: 'business-001',
        businessName: 'Crafting Store',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createRole(
      RolesCompanion.insert(
        id: 'role-001',
        businessId: 'business-001',
        name: 'Store Manager',
        slug: 'manager',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createRole(
      RolesCompanion.insert(
        id: 'role-002',
        businessId: 'business-001',
        name: 'Cashier',
        slug: 'cashier',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final roles = await database.getRolesForBusiness('business-001');

    expect(roles, hasLength(2));
  });

  test('A business cannot have duplicate role slugs', () async {
    final now = DateTime.now();

    await database.createBusinessSettings(
      BusinessSettingsCompanion.insert(
        id: 'business-001',
        businessName: 'Crafting Store',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createRole(
      RolesCompanion.insert(
        id: 'role-001',
        businessId: 'business-001',
        name: 'Store Manager',
        slug: 'manager',
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect(
      database.createRole(
        RolesCompanion.insert(
          id: 'role-002',
          businessId: 'business-001',
          name: 'Branch Manager',
          slug: 'manager',
          createdAt: now,
          updatedAt: now,
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('Database can create and retrieve a permission', () async {
    final now = DateTime.now();

    await database.createPermission(
      PermissionsCompanion.insert(
        id: 'permission-001',
        name: 'View Products',
        slug: 'products.view',
        module: 'Products',
        createdAt: now,
      ),
    );

    final permissions = await database.getAllPermissions();

    expect(permissions, hasLength(1));
    expect(permissions.first.id, 'permission-001');
    expect(permissions.first.name, 'View Products');
    expect(permissions.first.slug, 'products.view');
    expect(permissions.first.module, 'Products');
  });

  test('Database can retrieve permissions by module', () async {
    final now = DateTime.now();

    await database.createPermission(
      PermissionsCompanion.insert(
        id: 'permission-001',
        name: 'View Products',
        slug: 'products.view',
        module: 'Products',
        createdAt: now,
      ),
    );

    await database.createPermission(
      PermissionsCompanion.insert(
        id: 'permission-002',
        name: 'Create Products',
        slug: 'products.create',
        module: 'Products',
        createdAt: now,
      ),
    );

    await database.createPermission(
      PermissionsCompanion.insert(
        id: 'permission-003',
        name: 'View Sales',
        slug: 'sales.view',
        module: 'Sales',
        createdAt: now,
      ),
    );

    final productPermissions = await database.getPermissionsByModule(
      'Products',
    );

    expect(productPermissions, hasLength(2));
    expect(
      productPermissions.map((permission) => permission.slug),
      containsAll(['products.view', 'products.create']),
    );
  });

  test(
    'Database returns an empty list for an unknown permission module',
    () async {
      final permissions = await database.getPermissionsByModule('Unknown');

      expect(permissions, isEmpty);
    },
  );

  test('Permission slugs must be globally unique', () async {
    final now = DateTime.now();

    await database.createPermission(
      PermissionsCompanion.insert(
        id: 'permission-001',
        name: 'View Products',
        slug: 'products.view',
        module: 'Products',
        createdAt: now,
      ),
    );

    expect(
      database.createPermission(
        PermissionsCompanion.insert(
          id: 'permission-002',
          name: 'Another View Products',
          slug: 'products.view',
          module: 'Products',
          createdAt: now,
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('Permissions from different modules can coexist', () async {
    final now = DateTime.now();

    await database.createPermission(
      PermissionsCompanion.insert(
        id: 'permission-001',
        name: 'View Products',
        slug: 'products.view',
        module: 'Products',
        createdAt: now,
      ),
    );

    await database.createPermission(
      PermissionsCompanion.insert(
        id: 'permission-002',
        name: 'View Sales',
        slug: 'sales.view',
        module: 'Sales',
        createdAt: now,
      ),
    );

    final permissions = await database.getAllPermissions();

    expect(permissions, hasLength(2));
  });

  test('Permission can be assigned to a role and retrieved', () async {
    await createRoleFixture();
    await createPermissionFixture();

    await database.assignPermissionToRole(
      RolePermissionsCompanion.insert(
        roleId: 'role-001',
        permissionId: 'permission-001',
        createdAt: DateTime.now(),
      ),
    );

    final assignments = await database.getPermissionsForRole('role-001');

    expect(assignments, hasLength(1));
    expect(assignments.first.permissionId, 'permission-001');
  });

  test('Duplicate permission assignments are rejected', () async {
    await createRoleFixture();
    await createPermissionFixture();

    final assignment = RolePermissionsCompanion.insert(
      roleId: 'role-001',
      permissionId: 'permission-001',
      createdAt: DateTime.now(),
    );

    await database.assignPermissionToRole(assignment);

    expect(
      database.assignPermissionToRole(assignment),
      throwsA(isA<Exception>()),
    );
  });

  test('Role permission check returns correct results', () async {
    await createRoleFixture();
    await createPermissionFixture();

    await database.assignPermissionToRole(
      RolePermissionsCompanion.insert(
        roleId: 'role-001',
        permissionId: 'permission-001',
        createdAt: DateTime.now(),
      ),
    );

    expect(
      await database.roleHasPermission('role-001', 'permission-001'),
      isTrue,
    );

    expect(
      await database.roleHasPermission('role-001', 'permission-999'),
      isFalse,
    );
  });

  test('Permission can be removed from a role', () async {
    await createRoleFixture();
    await createPermissionFixture();

    await database.assignPermissionToRole(
      RolePermissionsCompanion.insert(
        roleId: 'role-001',
        permissionId: 'permission-001',
        createdAt: DateTime.now(),
      ),
    );

    final deletedCount = await database.removePermissionFromRole(
      'role-001',
      'permission-001',
    );

    expect(deletedCount, 1);
    expect(
      await database.roleHasPermission('role-001', 'permission-001'),
      isFalse,
    );
  });

  test('Deleting a role cascades to its permission assignments', () async {
    await createRoleFixture();
    await createPermissionFixture();

    await database.assignPermissionToRole(
      RolePermissionsCompanion.insert(
        roleId: 'role-001',
        permissionId: 'permission-001',
        createdAt: DateTime.now(),
      ),
    );

    await (database.delete(
      database.roles,
    )..where((role) => role.id.equals('role-001'))).go();

    final assignments = await database.getPermissionsForRole('role-001');

    expect(assignments, isEmpty);
  });
}
