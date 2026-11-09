import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/business_settings.dart';
import 'tables/branches.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [BusinessSettings, Branches])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'crafting_mpos'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (Migrator migrator, int from, int to) async {
      if (from < 2) {
        await migrator.createTable(branches);
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

  Future<List<BranchesData>> getBranchesForBusiness(String businessId) {
    return (select(
      branches,
    )..where((branch) => branch.businessId.equals(businessId))).get();
  }
}
