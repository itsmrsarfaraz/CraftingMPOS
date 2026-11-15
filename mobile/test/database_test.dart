import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';

import 'package:crafting_mpos/core/database/app_database.dart';

void main() {
  late AppDatabase database;
  late bool databaseClosed;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    databaseClosed = false;
  });

  tearDown(() async {
    if (!databaseClosed) {
      await database.close();
    }
  });

  Future<void> createRoleFixture({
    String businessId = 'business-001',
    String roleId = 'role-001',
  }) async {
    final now = DateTime.now();

    await database.createBusinessSettings(
      BusinessSettingsCompanion.insert(
        id: businessId,
        businessName: 'Test Business',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createRole(
      RolesCompanion.insert(
        id: roleId,
        businessId: businessId,
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

  Future<void> createUserFixture() async {
    final now = DateTime.now();

    await database.createUser(
      UsersCompanion.insert(
        id: 'user-001',
        businessId: 'business-001',
        username: 'cashier01',
        displayName: 'Test Cashier',
        passwordHash: 'test-password-hash',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> createBranchFixture({
    String businessId = 'business-001',
    String branchId = 'branch-001',
    String code = 'MAIN',
    String name = 'Main Branch',
  }) async {
    await database.createBranch(
      BranchesCompanion.insert(
        id: branchId,
        businessId: businessId,
        name: name,
        code: code,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> createDeviceFixture({
    String businessId = 'business-001',
    String deviceId = 'device-001',
    String deviceIdentifier = 'android-device-001',
    String deviceName = 'Main Counter',
  }) async {
    await database.createDevice(
      DevicesCompanion.insert(
        id: deviceId,
        businessId: businessId,
        deviceName: deviceName,
        deviceIdentifier: deviceIdentifier,
        publicKey: 'test-public-key-$deviceId',
        registeredAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> createCategoryFixture({
    String businessId = 'business-001',
    String categoryId = 'category-001',
    String name = 'Beverages',
    String? description = 'Drinks and beverages',
  }) async {
    await database.createBusinessSettings(
      BusinessSettingsCompanion.insert(
        id: businessId,
        businessName: 'Test Business',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    await database.createCategory(
      CategoriesCompanion.insert(
        id: categoryId,
        businessId: businessId,
        name: name,
        description: Value(description),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
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

  test('A user can have multiple roles', () async {
    await createRoleFixture();
    await createUserFixture();

    final now = DateTime.now();

    await database.createRole(
      RolesCompanion.insert(
        id: 'role-002',
        businessId: 'business-001',
        name: 'Inventory Manager',
        slug: 'inventory-manager',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.assignRoleToUser('user-001', 'role-001');
    await database.assignRoleToUser('user-001', 'role-002');

    final assignments = await database.getRolesForUser('user-001');

    expect(assignments, hasLength(2));
  });

  test('Multiple users can have the same role', () async {
    await createRoleFixture();
    await createUserFixture();

    final now = DateTime.now();

    await database.createUser(
      UsersCompanion.insert(
        id: 'user-002',
        businessId: 'business-001',
        username: 'cashier02',
        displayName: 'Second Cashier',
        passwordHash: 'test-password-hash',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.assignRoleToUser('user-001', 'role-001');
    await database.assignRoleToUser('user-002', 'role-001');

    final users = await database.getUsersForRole('role-001');

    expect(users, hasLength(2));
    expect(
      users.map((assignment) => assignment.userId),
      containsAll(['user-001', 'user-002']),
    );
  });

  test('Duplicate role assignments are rejected', () async {
    await createRoleFixture();
    await createUserFixture();

    await database.assignRoleToUser('user-001', 'role-001');

    expect(
      database.assignRoleToUser('user-001', 'role-001'),
      throwsA(isA<Exception>()),
    );
  });

  test('Users cannot receive roles from another business', () async {
    await createRoleFixture();
    await createUserFixture();

    final now = DateTime.now();

    await database.createBusinessSettings(
      BusinessSettingsCompanion.insert(
        id: 'business-002',
        businessName: 'Another Business',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createRole(
      RolesCompanion.insert(
        id: 'role-002',
        businessId: 'business-002',
        name: 'Manager',
        slug: 'manager',
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect(
      database.assignRoleToUser('user-001', 'role-002'),
      throwsA(isA<StateError>()),
    );

    final assignments = await database.getRolesForUser('user-001');

    expect(assignments, isEmpty);
  });

  test('Role assignment can be removed from a user', () async {
    await createRoleFixture();
    await createUserFixture();

    await database.assignRoleToUser('user-001', 'role-001');

    final deletedCount = await database.removeRoleFromUser(
      'user-001',
      'role-001',
    );

    expect(deletedCount, 1);
    expect(await database.userHasRole('user-001', 'role-001'), isFalse);
  });

  test('Deleting a user or role cascades to role assignments', () async {
    await createRoleFixture();
    await createUserFixture();

    final now = DateTime.now();

    await database.createUser(
      UsersCompanion.insert(
        id: 'user-002',
        businessId: 'business-001',
        username: 'cashier02',
        displayName: 'Second Cashier',
        passwordHash: 'test-password-hash',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.assignRoleToUser('user-001', 'role-001');
    await database.assignRoleToUser('user-002', 'role-001');

    await (database.delete(
      database.users,
    )..where((user) => user.id.equals('user-001'))).go();

    expect(await database.getUsersForRole('role-001'), hasLength(1));

    await (database.delete(
      database.roles,
    )..where((role) => role.id.equals('role-001'))).go();

    expect(await database.getUsersForRole('role-001'), isEmpty);
  });

  test('A user can be assigned to multiple branches', () async {
    await createRoleFixture();
    await createUserFixture();

    await createBranchFixture();

    await createBranchFixture(
      branchId: 'branch-002',
      code: 'BR-002',
      name: 'Second Branch',
    );

    await database.assignUserToBranch('user-001', 'branch-001');
    await database.assignUserToBranch('user-001', 'branch-002');

    final assignments = await database.getBranchesForUser('user-001');

    expect(assignments, hasLength(2));
    expect(
      assignments.map((assignment) => assignment.branchId),
      containsAll(['branch-001', 'branch-002']),
    );
  });

  test('Database can register and retrieve a device', () async {
    await createRoleFixture();
    await createDeviceFixture();

    final device = await database.getDeviceByIdentifier(
      'business-001',
      'android-device-001',
    );

    expect(device, isNotNull);
    expect(device!.id, 'device-001');
    expect(device.businessId, 'business-001');
    expect(device.deviceName, 'Main Counter');
    expect(device.deviceType, 'android');
    expect(device.isActive, isTrue);
  });

  test('Database can retrieve all devices for a business', () async {
    await createRoleFixture();

    await createDeviceFixture(
      deviceId: 'device-001',
      deviceIdentifier: 'android-device-001',
      deviceName: 'Main Counter',
    );

    await createDeviceFixture(
      deviceId: 'device-002',
      deviceIdentifier: 'android-device-002',
      deviceName: 'Second Counter',
    );

    final devices = await database.getDevicesForBusiness('business-001');

    expect(devices.length, 2);
    expect(
      devices.map((device) => device.deviceName),
      containsAll(['Main Counter', 'Second Counter']),
    );
  });

  test('Devices are isolated between businesses', () async {
    await createRoleFixture();

    await createDeviceFixture(
      businessId: 'business-001',
      deviceId: 'device-001',
      deviceIdentifier: 'android-device-001',
    );

    await createRoleFixture(businessId: 'business-002', roleId: 'role-002');

    await createDeviceFixture(
      businessId: 'business-002',
      deviceId: 'device-002',
      deviceIdentifier: 'android-device-002',
    );

    final firstBusinessDevices = await database.getDevicesForBusiness(
      'business-001',
    );

    final secondBusinessDevices = await database.getDevicesForBusiness(
      'business-002',
    );

    expect(firstBusinessDevices.length, 1);
    expect(firstBusinessDevices.first.id, 'device-001');

    expect(secondBusinessDevices.length, 1);
    expect(secondBusinessDevices.first.id, 'device-002');
  });

  test('Device identifier must be unique within a business', () async {
    await createRoleFixture();

    await createDeviceFixture(
      businessId: 'business-001',
      deviceId: 'device-001',
      deviceIdentifier: 'android-device-001',
    );

    await expectLater(
      createDeviceFixture(
        businessId: 'business-001',
        deviceId: 'device-002',
        deviceIdentifier: 'android-device-001',
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('Different businesses can use the same device identifier', () async {
    await createRoleFixture();

    await createDeviceFixture(
      businessId: 'business-001',
      deviceId: 'device-001',
      deviceIdentifier: 'android-device-shared',
    );

    await createRoleFixture(businessId: 'business-002', roleId: 'role-002');

    await createDeviceFixture(
      businessId: 'business-002',
      deviceId: 'device-002',
      deviceIdentifier: 'android-device-shared',
    );

    final firstBusinessDevice = await database.getDeviceByIdentifier(
      'business-001',
      'android-device-shared',
    );

    final secondBusinessDevice = await database.getDeviceByIdentifier(
      'business-002',
      'android-device-shared',
    );

    expect(firstBusinessDevice?.id, 'device-001');
    expect(secondBusinessDevice?.id, 'device-002');
  });

  test('Database can update device last seen timestamp', () async {
    await createRoleFixture();
    await createDeviceFixture();

    final deviceBefore = await database.getDeviceByIdentifier(
      'business-001',
      'android-device-001',
    );

    expect(deviceBefore, isNotNull);
    expect(deviceBefore!.lastSeenAt, isNull);

    final updatedRows = await database.updateDeviceLastSeen('device-001');

    final deviceAfter = await database.getDeviceByIdentifier(
      'business-001',
      'android-device-001',
    );

    expect(updatedRows, 1);
    expect(deviceAfter!.lastSeenAt, isNotNull);
    expect(
      deviceAfter.updatedAt.isAfter(deviceBefore.updatedAt) ||
          deviceAfter.updatedAt.isAtSameMomentAs(deviceBefore.updatedAt),
      isTrue,
    );
  });

  test('Database can deactivate and reactivate a device', () async {
    await createRoleFixture();
    await createDeviceFixture();

    final initialDevice = await database.getDeviceByIdentifier(
      'business-001',
      'android-device-001',
    );

    expect(initialDevice!.isActive, isTrue);

    final deactivatedRows = await database.setDeviceActive('device-001', false);

    final deactivatedDevice = await database.getDeviceByIdentifier(
      'business-001',
      'android-device-001',
    );

    expect(deactivatedRows, 1);
    expect(deactivatedDevice!.isActive, isFalse);

    final activatedRows = await database.setDeviceActive('device-001', true);

    final activatedDevice = await database.getDeviceByIdentifier(
      'business-001',
      'android-device-001',
    );

    expect(activatedRows, 1);
    expect(activatedDevice!.isActive, isTrue);
  });

  test('Database returns null for an unregistered device', () async {
    await createRoleFixture();

    final device = await database.getDeviceByIdentifier(
      'business-001',
      'unknown-device-001',
    );

    expect(device, isNull);
  });

  test('Deleting a business also deletes its registered devices', () async {
    await createRoleFixture();
    await createDeviceFixture();

    final devicesBefore = await database.getDevicesForBusiness('business-001');

    expect(devicesBefore.length, 1);

    await (database.delete(
      database.businessSettings,
    )..where((business) => business.id.equals('business-001'))).go();

    final devicesAfter = await database.getDevicesForBusiness('business-001');

    expect(devicesAfter, isEmpty);
  });

  test('Version 10 database upgrades successfully to version 13', () async {
    await database.close();
    databaseClosed = true;
    final legacyDatabase = AppDatabase(
      NativeDatabase.memory(
        setup: (db) {
          db.execute('''
          CREATE TABLE business_settings (
            id TEXT PRIMARY KEY
          )
        ''');

          db.execute('''
  CREATE TABLE branches (
    id TEXT PRIMARY KEY,
    business_id TEXT NOT NULL
      REFERENCES business_settings(id)
  )
''');

          db.execute('''
          CREATE TABLE roles (
            id TEXT PRIMARY KEY,
            business_id TEXT NOT NULL
              REFERENCES business_settings(id)
          )
        ''');

          db.execute('''
          CREATE TABLE role_permissions (
            role_id TEXT NOT NULL
              REFERENCES roles(id) ON DELETE CASCADE,
            permission_id TEXT NOT NULL,
            PRIMARY KEY (role_id, permission_id)
          )
        ''');

          db.execute('''
          CREATE TABLE user_roles (
            user_id TEXT NOT NULL,
            role_id TEXT NOT NULL
              REFERENCES roles(id) ON DELETE CASCADE,
            PRIMARY KEY (user_id, role_id)
          )
        ''');

          db.execute('''
          CREATE TABLE devices (
            id TEXT PRIMARY KEY,
            business_id TEXT NOT NULL
              REFERENCES business_settings(id) ON DELETE CASCADE
          )
        ''');

          db.execute('PRAGMA user_version = 10');
        },
      ),
    );
    final versionResult = await legacyDatabase
        .customSelect('PRAGMA user_version')
        .getSingle();

    expect(versionResult.read<int>('user_version'), 13);

    final categoriesResult = await legacyDatabase.customSelect('''
  SELECT name
  FROM sqlite_master
  WHERE type = 'table'
    AND name = 'categories'
''').get();

    expect(categoriesResult, hasLength(1));

    // Verify product and inventory tables were created.
    final productTables = await legacyDatabase.customSelect('''
  SELECT name
  FROM sqlite_master
  WHERE type = 'table'
    AND name IN (
      'products',
      'product_variants',
      'product_codes',
      'branch_stocks'
    )
''').get();

    expect(productTables, hasLength(4));

    // Verify the primary barcode partial unique index exists.
    final primaryBarcodeIndex = await legacyDatabase.customSelect('''
  SELECT name
  FROM sqlite_master
  WHERE type = 'index'
    AND name = 'product_codes_one_primary_per_variant'
''').get();

    expect(primaryBarcodeIndex, hasLength(1));

    final triggerResult = await legacyDatabase.customSelect('''
  SELECT name
  FROM sqlite_master
  WHERE type = 'trigger'
    AND name = 'business_delete_roles_cascade'
''').get();

    expect(triggerResult, hasLength(1));
    try {
      // Insert existing version 10 records.
      await legacyDatabase.customStatement(
        "INSERT INTO business_settings (id) VALUES ('business-001')",
      );

      await legacyDatabase.customStatement(
        "INSERT INTO roles (id, business_id) "
        "VALUES ('role-001', 'business-001')",
      );

      await legacyDatabase.customStatement(
        "INSERT INTO role_permissions (role_id, permission_id) "
        "VALUES ('role-001', 'permission-001')",
      );

      await legacyDatabase.customStatement(
        "INSERT INTO user_roles (user_id, role_id) "
        "VALUES ('user-001', 'role-001')",
      );

      await legacyDatabase.customStatement(
        "INSERT INTO devices (id, business_id) "
        "VALUES ('device-001', 'business-001')",
      );

      // Delete the business.
      await legacyDatabase.customStatement(
        "DELETE FROM business_settings WHERE id = 'business-001'",
      );

      // Verify that the migration trigger and foreign-key cascades worked.
      final roles = await legacyDatabase
          .customSelect('SELECT * FROM roles')
          .get();

      final rolePermissions = await legacyDatabase
          .customSelect('SELECT * FROM role_permissions')
          .get();

      final userRoles = await legacyDatabase
          .customSelect('SELECT * FROM user_roles')
          .get();

      final devices = await legacyDatabase
          .customSelect('SELECT * FROM devices')
          .get();

      expect(roles, isEmpty);
      expect(rolePermissions, isEmpty);
      expect(userRoles, isEmpty);
      expect(devices, isEmpty);
    } finally {
      await legacyDatabase.close();
    }
  });

  group('Category Management', () {
    test('Create and retrieve a category', () async {
      await createCategoryFixture();

      final category = await database.getCategoryById(
        'business-001',
        'category-001',
      );

      expect(category, isNotNull);
      expect(category!.name, 'Beverages');
      expect(category.description, 'Drinks and beverages');
      expect(category.isActive, isTrue);
    });

    test('Retrieve categories for a business', () async {
      await createCategoryFixture();

      await database.createCategory(
        CategoriesCompanion.insert(
          id: 'category-002',
          businessId: 'business-001',
          name: 'Groceries',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final categories = await database.getCategoriesForBusiness(
        'business-001',
      );

      expect(categories, hasLength(2));
      expect(categories.map((category) => category.name).toList(), [
        'Beverages',
        'Groceries',
      ]);
    });

    test('Categories are isolated between businesses', () async {
      await createCategoryFixture();

      await createCategoryFixture(
        businessId: 'business-002',
        categoryId: 'category-002',
        name: 'Electronics',
      );

      final categories = await database.getCategoriesForBusiness(
        'business-001',
      );

      expect(categories, hasLength(1));
      expect(categories.first.name, 'Beverages');

      final otherBusinessCategory = await database.getCategoryById(
        'business-001',
        'category-002',
      );

      expect(otherBusinessCategory, isNull);
    });

    test('Duplicate category names within a business are rejected', () async {
      await createCategoryFixture();

      expect(
        () => database.createCategory(
          CategoriesCompanion.insert(
            id: 'category-002',
            businessId: 'business-001',
            name: 'Beverages',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
