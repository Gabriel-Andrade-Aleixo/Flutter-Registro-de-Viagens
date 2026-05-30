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

  Future<void> deletar(int id) {
    AppLogger.info('REPOSITORY', 'Deletando viagem pela fonte=$fonte id=$id');
    return switch (fonte) {
      FontePersistencia.local => _localDataSource.deletar(id),
      FontePersistencia.remota => _apiService.deletar(id),
    };
  }

  Future<int> sincronizarPendentes() async {
    AppLogger.info('REPOSITORY', 'Iniciando sincronizacao de pendencias.');
    final pendentes = await _localDataSource.listarPendentesSincronizacao();
    var totalSincronizado = 0;

    for (final viagem in pendentes) {
      AppLogger.info(
        'REPOSITORY',
        'Sincronizando localId=${viagem.id}, remoteId=${viagem.remoteId}',
      );
      final viagemRemota = viagem.remoteId == null
          ? await _apiService.cadastrar(viagem)
          : await _apiService.atualizar(viagem);

      final idLocal = viagem.id;
      final idRemoto = viagemRemota.id;

      if (idLocal != null && idRemoto != null) {
        await _localDataSource.marcarComoSincronizada(
          id: idLocal,
          remoteId: idRemoto,
        );
        totalSincronizado++;
      }
    }

    AppLogger.info(
      'REPOSITORY',
      'Sincronizacao finalizada. Total=$totalSincronizado',
    );
    return totalSincronizado;
  }
}
