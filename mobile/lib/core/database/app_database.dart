import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/business_settings.dart';
import 'tables/branches.dart';
import 'tables/users.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [BusinessSettings, Branches, Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'crafting_mpos'));

  @override
  int get schemaVersion => 4;

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
}
