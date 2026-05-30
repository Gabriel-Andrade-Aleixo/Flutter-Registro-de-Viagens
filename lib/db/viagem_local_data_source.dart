import 'package:sqflite/sqflite.dart';

import '../models/viagem.dart';
import '../services/app_logger.dart';
import 'database_helper.dart';

class ViagemLocalDataSource {
  static const _tableName = 'viagens';

  Future<List<Viagem>> listar() async {
    AppLogger.info('SQLITE', 'Listando viagens locais.');
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(_tableName, orderBy: 'data DESC');
    AppLogger.info('SQLITE', 'Viagens locais encontradas: ${maps.length}');
    return maps.map(Viagem.fromMap).toList();
  }

  Future<Viagem> cadastrar(Viagem viagem) async {
    AppLogger.info(
      'SQLITE',
      'Inserindo viagem local: destino=${viagem.destino}, valor=${viagem.valor}',
    );
    final db = await DatabaseHelper.instance.database;
    final id = await db.insert(
      _tableName,
      viagem.copyWith(sincronizado: false).toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    AppLogger.info('SQLITE', 'Viagem local inserida com id=$id');
    return viagem.copyWith(id: id, sincronizado: false);
  }

  Future<Viagem> atualizar(Viagem viagem) async {
    AppLogger.info('SQLITE', 'Atualizando viagem local id=${viagem.id}');
    final db = await DatabaseHelper.instance.database;

    if (viagem.id == null) {
      throw ArgumentError('Nao e possivel atualizar uma viagem sem id.');
    }

    final linhas = await db.update(
      _tableName,
      viagem.copyWith(sincronizado: false).toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [viagem.id],
    );
    AppLogger.info('SQLITE', 'Linhas locais atualizadas: $linhas');

    return viagem.copyWith(sincronizado: false);
  }

  Future<void> deletar(int id) async {
    AppLogger.info('SQLITE', 'Excluindo viagem local id=$id');
    final db = await DatabaseHelper.instance.database;
    final linhas = await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    AppLogger.info('SQLITE', 'Linhas locais excluidas: $linhas');
  }

  Future<List<Viagem>> listarPendentesSincronizacao() async {
    AppLogger.info('SQLITE', 'Buscando viagens pendentes de sincronizacao.');
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      _tableName,
      where: 'sincronizado = ?',
      whereArgs: [0],
      orderBy: 'id ASC',
    );
    AppLogger.info('SQLITE', 'Pendencias encontradas: ${maps.length}');
    return maps.map(Viagem.fromMap).toList();
  }

  Future<void> marcarComoSincronizada({
    required int id,
    required int remoteId,
  }) async {
    AppLogger.info(
      'SQLITE',
      'Marcando viagem local id=$id como sincronizada. remoteId=$remoteId',
    );
    final db = await DatabaseHelper.instance.database;
    final linhas = await db.update(
      _tableName,
      {'remote_id': remoteId, 'sincronizado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    AppLogger.info('SQLITE', 'Linhas marcadas como sincronizadas: $linhas');
  }
}
