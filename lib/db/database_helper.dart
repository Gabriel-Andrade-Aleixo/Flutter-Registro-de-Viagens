import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../services/app_logger.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();
  static const _databaseName = 'registro_viagens.db';
  static const _databaseVersion = 3;

  Database? _database;
  bool _factoryConfigurada = false;

  Future<Database> get database async {
    _configurarDatabaseFactory();

    if (_database != null) {
      return _database!;
    }

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    AppLogger.info('SQLITE', 'Abrindo banco local em: $path');

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    AppLogger.info('SQLITE', 'Criando tabela viagens. Versao: $version');
    await db.execute('''
      CREATE TABLE viagens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id INTEGER,
        destino TEXT NOT NULL,
        data TEXT NOT NULL,
        valor REAL NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL DEFAULT 'pendente',
        sync_action TEXT NOT NULL DEFAULT 'criar',
        removido INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.info(
      'SQLITE',
      'Atualizando banco local da versao $oldVersion para $newVersion',
    );

    if (oldVersion < 2) {
      await db.execute('ALTER TABLE viagens ADD COLUMN remote_id INTEGER');
      await db.execute(
        'ALTER TABLE viagens ADD COLUMN sincronizado INTEGER NOT NULL DEFAULT 0',
      );
    }

    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE viagens ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'pendente'",
      );
      await db.execute(
        "ALTER TABLE viagens ADD COLUMN sync_action TEXT NOT NULL DEFAULT 'criar'",
      );
      await db.execute(
        'ALTER TABLE viagens ADD COLUMN removido INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('''
        UPDATE viagens
        SET sync_status = CASE
          WHEN sincronizado = 1 THEN 'sincronizado'
          ELSE 'pendente'
        END,
        sync_action = CASE
          WHEN sincronizado = 1 THEN 'nenhuma'
          WHEN remote_id IS NULL THEN 'criar'
          ELSE 'atualizar'
        END
      ''');
    }
  }

  void _configurarDatabaseFactory() {
    if (_factoryConfigurada) {
      return;
    }

    if (kIsWeb) {
      throw UnsupportedError(
        'SQLite local nao funciona no Flutter Web com sqflite. Rode em Windows, Android ou celular; ou use a fonte API remota.',
      );
    }

    final isDesktop =
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;

    if (isDesktop) {
      AppLogger.info('SQLITE', 'Configurando sqflite_common_ffi para desktop.');
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _factoryConfigurada = true;
  }
}
