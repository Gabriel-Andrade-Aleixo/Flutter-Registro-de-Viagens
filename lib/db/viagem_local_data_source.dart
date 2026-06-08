import 'package:sqflite/sqflite.dart';

import '../models/viagem.dart';
import '../services/app_logger.dart';
import 'database_helper.dart';

class ViagemLocalDataSource {
  static const _tableName = 'viagens';

  Future<List<Viagem>> listar() async {
    AppLogger.info('SQLITE', 'Listando viagens locais.');
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      _tableName,
      where: 'removido = ?',
      whereArgs: [0],
      orderBy: 'data DESC',
    );
    AppLogger.info('SQLITE', 'Viagens locais encontradas: ${maps.length}');
    return maps.map(Viagem.fromMap).toList();
  }

  Future<Viagem> cadastrar(Viagem viagem) async {
    AppLogger.info(
      'SQLITE',
      'Inserindo viagem local: destino=${viagem.destino}, valor=${viagem.valor}',
    );
    final db = await DatabaseHelper.instance.database;
    final viagemPendente = viagem.copyWith(
      syncStatus: SyncStatus.pendente,
      syncAction: SyncAction.criar,
      removido: false,
    );
    final id = await db.insert(
      _tableName,
      viagemPendente.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    AppLogger.info('SQLITE', 'Viagem local inserida com id=$id');
    return viagemPendente.copyWith(id: id);
  }

  Future<Viagem> atualizar(Viagem viagem) async {
    AppLogger.info('SQLITE', 'Atualizando viagem local id=${viagem.id}');
    final db = await DatabaseHelper.instance.database;

    if (viagem.id == null) {
      throw ArgumentError('Nao e possivel atualizar uma viagem sem id.');
    }

    final action = viagem.remoteId == null
        ? SyncAction.criar
        : SyncAction.atualizar;
    final viagemPendente = viagem.copyWith(
      syncStatus: SyncStatus.pendente,
      syncAction: action,
      removido: false,
    );
    final linhas = await db.update(
      _tableName,
      viagemPendente.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [viagem.id],
    );
    AppLogger.info('SQLITE', 'Linhas locais atualizadas: $linhas');

    return viagemPendente;
  }

  Future<void> deletar(Viagem viagem) async {
    final id = viagem.id;
    if (id == null) {
      return;
    }

    AppLogger.info('SQLITE', 'Excluindo viagem local id=$id');
    final db = await DatabaseHelper.instance.database;

    if (viagem.remoteId == null) {
      final linhas = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      AppLogger.info('SQLITE', 'Linhas locais excluidas: $linhas');
      return;
    }

    final linhas = await db.update(
      _tableName,
      {
        'sync_status': SyncStatus.pendente.valor,
        'sync_action': SyncAction.deletar.valor,
        'removido': 1,
        'sincronizado': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    AppLogger.info('SQLITE', 'Linhas marcadas para exclusao remota: $linhas');
  }

  Future<List<Viagem>> listarPendentesSincronizacao() async {
    AppLogger.info('SQLITE', 'Buscando viagens pendentes de sincronizacao.');
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      _tableName,
      where: 'sync_status != ? OR sync_action != ?',
      whereArgs: [SyncStatus.sincronizado.valor, SyncAction.nenhuma.valor],
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
      {
        'remote_id': remoteId,
        'sincronizado': 1,
        'sync_status': SyncStatus.sincronizado.valor,
        'sync_action': SyncAction.nenhuma.valor,
        'removido': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    AppLogger.info('SQLITE', 'Linhas marcadas como sincronizadas: $linhas');
  }

  Future<void> marcarErroSincronizacao(int id) async {
    AppLogger.info('SQLITE', 'Marcando erro de sincronizacao no id=$id');
    final db = await DatabaseHelper.instance.database;
    await db.update(
      _tableName,
      {'sync_status': SyncStatus.erro.valor, 'sincronizado': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> removerDefinitivamente(int id) async {
    AppLogger.info('SQLITE', 'Removendo definitivamente id=$id');
    final db = await DatabaseHelper.instance.database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> salvarViagensRemotas(List<Viagem> viagens) async {
    AppLogger.info(
      'SQLITE',
      'Salvando ${viagens.length} viagens remotas no banco local.',
    );
    final db = await DatabaseHelper.instance.database;
    var total = 0;

    for (final viagem in viagens) {
      final remoteId = viagem.remoteId ?? viagem.id;
      if (remoteId == null) {
        continue;
      }

      final maps = await db.query(
        _tableName,
        columns: ['id', 'sync_status'],
        where: 'remote_id = ?',
        whereArgs: [remoteId],
        limit: 1,
      );

      final dados =
          viagem
              .copyWith(
                remoteId: remoteId,
                syncStatus: SyncStatus.sincronizado,
                syncAction: SyncAction.nenhuma,
                removido: false,
              )
              .toMap()
            ..remove('id');

      if (maps.isEmpty) {
        await db.insert(_tableName, dados);
      } else {
        final localStatus = SyncStatus.fromString(
          maps.first['sync_status'] as String?,
        );
        if (localStatus != SyncStatus.sincronizado) {
          AppLogger.info(
            'SQLITE',
            'Registro remoto $remoteId ignorado porque ha alteracao local pendente.',
          );
          continue;
        }

        await db.update(
          _tableName,
          dados,
          where: 'id = ?',
          whereArgs: [maps.first['id']],
        );
      }

      total++;
    }

    AppLogger.info('SQLITE', 'Viagens remotas salvas localmente: $total');
    return total;
  }
}
