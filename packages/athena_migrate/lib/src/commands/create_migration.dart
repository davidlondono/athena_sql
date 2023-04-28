import 'dart:io';

// import 'package:clock/clock.dart';
import 'package:intl/intl.dart';
import '../utils/config.dart';
import 'package:athena_migrate/src/executable.dart';
import 'package:dcli/dcli.dart';
import 'package:path/path.dart' as path;

abstract class ConsoleConfig {
  static const migrationDestination = 'database/migrations';
  static const stubsDirectory = 'templates/stubs';
}

const migrationFile = '''
import 'package:athena_sql/athena_sql.dart';

class {{className}} extends AthenaMigration {
  {{className}}() : super("{{name}}","{{date}}");
  @override
  Future<void> up(AthenaSQL<AthenaDatabaseDriver> db) async {
    // add the migration code here
  }
  @override
  Future<void> down(AthenaSQL<AthenaDatabaseDriver> db) async {
    // add the migration code here
  }
}
''';

var defaultListContents = '''
import 'package:athena_sql/athena_sql.dart';

import 'index.dart';

final List<AthenaMigration> migrations = [
];

''';

const drivers = <String, String>{
  'postgresql': 'MySQL',
};

class MigrationNew {
  final String name;
  final String date;
  final String driver;

  String get contents => migrationFile
      .replaceAll('{{date}}', date)
      .replaceAll('{{driver}}', driver)
      .replaceAll('{{name}}', name)
      .replaceAll('{{className}}', className);

  String get fileName => '${[date, name].join(' ').snakeCase}.dart';
  String get className => 'Migration $name $date'.pascalCase;

  MigrationNew(this.name, this.date, this.driver);

  File generate(String destinationFile) => File(destinationFile)
    ..createSync(recursive: true)
    ..writeAsStringSync(contents);

  void register(String destinationDir) {
    registerMainFile(destinationDir);
  }

  void registerMainFile(String destinationDir) {
    File(path.join(destinationDir, fileName))
      ..createSync(recursive: true)
      ..writeAsStringSync(contents);
  }
}

class CreateMigrationCommand extends ExecutableComand {
  final AthenaConfig config;

  String getDateNewMigration() {
    var now = DateTime.now();
    var formatter = DateFormat('yyyy_MM_dd_HHmmss');
    return formatter.format(now);
  }

  CreateMigrationCommand(this.config)
      : super('create', 'Creates a migration file');

  MigrationNew _loadTemplate(String migrationName) {
    final date = getDateNewMigration();

    return MigrationNew(migrationName, date, config.driver);
  }

  @override
  Future<int> run(ArgResults? args) async {
    // var logging = silent ? null : progress('Creating migration');
    var migrationName = args?.arguments.join(' ');
    if (migrationName == null || migrationName.isEmpty) {
      print(yellow('Migration name is required'));
      var name = ask('name:',
          required: true, validator: Ask.regExp(r'^[\w\d\-_\s]+$'));
      migrationName = name;
    }
    print('Creating migration');
    final migration = _loadTemplate(migrationName);
    migration.register(config.migrationsPath);

    print('Migration created: ${migration.fileName}');

    return 0;
  }
}

extension StringExtension on String {
  String snakeCasetoSentenceCase() {
    return "${this[0].toUpperCase()}${substring(1)}"
        .replaceAll(RegExp(r'(_|-)+'), ' ');
  }
}

// convert any string into snake_case
extension StringExtension2 on String {
  String get snakeCase {
    return replaceAllMapped(RegExp(r'[A-Z]'), (match) => '${match.group(0)}')
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'(_|-)+'), '_');
  }

  String get pascalCase {
    List<String> words = replaceAll(RegExp('[^a-zA-Z0-9]+'), ' ').split(' ');
    String pascalCase = '';
    for (String word in words) {
      pascalCase +=
          word.substring(0, 1).toUpperCase() + word.substring(1).toLowerCase();
    }
    return pascalCase;
  }
}