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
}
