import '../athena_sql.dart';
import 'builders/builders.dart';

class AthenaSQL<D extends AthenaDriver> {
  final D driver;
  AthenaSQL(this.driver);

  CreateBuilder<D> get create => CreateBuilder(driver);

  DropBuilder<D> get drop => DropBuilder(driver);
}

extension AthenaDatabaseExtension on AthenaSQL<AthenaDatabaseConnectionDriver> {
  Future<void> open() => driver.open();
  Future<T> transaction<T>(
      Future<T> Function(AthenaSQL<AthenaDatabaseDriver> athenasql) trx) {
    return driver.transaction((driver) => trx(AthenaSQL(driver)));
  }

  Future<bool> tableExists(String table) => driver.tableExists(table);
}

abstract class AthenaMigration {
  final String name;
  final String date;
  const AthenaMigration(this.name, this.date);
  Future<void> up(AthenaSQL<AthenaDatabaseDriver> db);
  Future<void> down(AthenaSQL<AthenaDatabaseDriver> db);
}