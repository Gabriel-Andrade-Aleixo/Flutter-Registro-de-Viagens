import '../db/viagem_local_data_source.dart';
import '../models/viagem.dart';
import '../services/app_logger.dart';
import '../services/viagem_api_service.dart';

enum FontePersistencia { local, remota }

class ViagemRepository {
  ViagemRepository({
    ViagemLocalDataSource? localDataSource,
    ViagemApiService? apiService,
    this.fonte = FontePersistencia.local,
  }) : _localDataSource = localDataSource ?? ViagemLocalDataSource(),
       _apiService = apiService ?? ViagemApiService();

  final ViagemLocalDataSource _localDataSource;
  final ViagemApiService _apiService;
  FontePersistencia fonte;

  Future<List<Viagem>> listar() {
    AppLogger.info('REPOSITORY', 'Listando viagens pela fonte=$fonte');
    return switch (fonte) {
      FontePersistencia.local => _localDataSource.listar(),
      FontePersistencia.remota => _apiService.listar(),
    };
  }

  Future<Viagem> cadastrar(Viagem viagem) {
    AppLogger.info(
      'REPOSITORY',
      'Cadastrando viagem pela fonte=$fonte destino=${viagem.destino}',
    );
    return switch (fonte) {
      FontePersistencia.local => _localDataSource.cadastrar(viagem),
      FontePersistencia.remota => _apiService.cadastrar(viagem),
    };
  }

  Future<Viagem> atualizar(Viagem viagem) {
    AppLogger.info(
      'REPOSITORY',
      'Atualizando viagem pela fonte=$fonte id=${viagem.id}, remoteId=${viagem.remoteId}',
    );
    return switch (fonte) {
      FontePersistencia.local => _localDataSource.atualizar(viagem),
      FontePersistencia.remota => _apiService.atualizar(viagem),
    };
  }

  Future<void> deletar(Viagem viagem) {
    final idRemoto = viagem.remoteId ?? viagem.id;
    AppLogger.info(
      'REPOSITORY',
      'Deletando viagem pela fonte=$fonte id=${viagem.id}, remoteId=${viagem.remoteId}',
    );
    return switch (fonte) {
      FontePersistencia.local => _localDataSource.deletar(viagem),
      FontePersistencia.remota =>
        idRemoto == null ? Future.value() : _apiService.deletar(idRemoto),
    };
  }

  Future<int> sincronizarPendentes() async {
    AppLogger.info('REPOSITORY', 'Iniciando sincronizacao de pendencias.');
    final pendentes = await _localDataSource.listarPendentesSincronizacao();
    var totalSincronizado = 0;

    for (final viagem in pendentes) {
      AppLogger.info(
        'REPOSITORY',
        'Sincronizando localId=${viagem.id}, remoteId=${viagem.remoteId}, action=${viagem.syncAction}',
      );
      final idLocal = viagem.id;
      if (idLocal == null) {
        continue;
      }

      try {
        switch (viagem.syncAction) {
          case SyncAction.criar:
            final viagemRemota = await _apiService.cadastrar(viagem);
            final idRemoto = viagemRemota.id;
            if (idRemoto != null) {
              await _localDataSource.marcarComoSincronizada(
                id: idLocal,
                remoteId: idRemoto,
              );
              totalSincronizado++;
            }
          case SyncAction.atualizar:
            final viagemRemota = await _apiService.atualizar(viagem);
            final idRemoto = viagemRemota.id ?? viagem.remoteId;
            if (idRemoto != null) {
              await _localDataSource.marcarComoSincronizada(
                id: idLocal,
                remoteId: idRemoto,
              );
              totalSincronizado++;
            }
          case SyncAction.deletar:
            final idRemoto = viagem.remoteId;
            if (idRemoto != null) {
              await _apiService.deletar(idRemoto);
            }
            await _localDataSource.removerDefinitivamente(idLocal);
            totalSincronizado++;
          case SyncAction.nenhuma:
            await _localDataSource.marcarComoSincronizada(
              id: idLocal,
              remoteId: viagem.remoteId ?? idLocal,
            );
        }
      } catch (erro) {
        AppLogger.error(
          'REPOSITORY',
          'Falha ao sincronizar viagem localId=$idLocal',
          erro,
        );
        await _localDataSource.marcarErroSincronizacao(idLocal);
      }
    }

    AppLogger.info(
      'REPOSITORY',
      'Sincronizacao finalizada. Total=$totalSincronizado',
    );
    return totalSincronizado;
  }

  Future<int> sincronizarComApi() async {
    AppLogger.info('REPOSITORY', 'Iniciando sincronizacao completa com API.');
    final enviados = await sincronizarPendentes();
    final remotas = await _apiService.listar();
    final baixados = await _localDataSource.salvarViagensRemotas(remotas);
    final total = enviados + baixados;

    AppLogger.info(
      'REPOSITORY',
      'Sincronizacao completa finalizada. Enviados=$enviados, baixados=$baixados',
    );

    return total;
  }
}
