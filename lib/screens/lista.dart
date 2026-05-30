import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/viagem.dart';
import '../repository/viagem_repository.dart';
import '../services/app_logger.dart';
import 'formulario.dart';

class ListaViagens extends StatefulWidget {
  const ListaViagens({super.key});

  @override
  State<ListaViagens> createState() => _ListaViagensState();
}

class _ListaViagensState extends State<ListaViagens> {
  static const _tituloAppBar = 'Registro de Viagens';
  final ViagemRepository _repository = ViagemRepository(
    fonte: kIsWeb ? FontePersistencia.remota : FontePersistencia.local,
  );
  final List<Viagem> _viagens = [];
  StreamSubscription<List<ConnectivityResult>>? _conexaoSubscription;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarViagens();
    _monitorarConexao();
  }

  @override
  void dispose() {
    _conexaoSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(_tituloAppBar),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () async {
              await _sincronizarSeOnline();
              await _carregarViagens();
            },
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<FontePersistencia>(
            tooltip: 'Fonte de dados',
            icon: Icon(
              _repository.fonte == FontePersistencia.local
                  ? Icons.storage
                  : Icons.cloud,
            ),
            onSelected: _alterarFonte,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: FontePersistencia.local,
                child: Text('SQLite local'),
              ),
              PopupMenuItem(
                value: FontePersistencia.remota,
                child: Text('API remota'),
              ),
            ],
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _viagens.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma viagem cadastrada.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _viagens.length,
              itemBuilder: (context, indice) {
                final viagem = _viagens[indice];
                return ItemViagem(
                  viagem,
                  onEditar: () => _abrirFormulario(viagem),
                  onDeletar: () => _deletar(viagem),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _carregarViagens() async {
    AppLogger.info('APP', 'Carregando viagens na tela.');
    setState(() => _carregando = true);

    try {
      final viagens = await _repository.listar();
      setState(() {
        _viagens
          ..clear()
          ..addAll(viagens);
      });
      AppLogger.info('APP', 'Tela atualizada com ${viagens.length} viagens.');
    } catch (erro) {
      AppLogger.error('APP', 'Falha ao carregar viagens na tela.', erro);
      _mostrarMensagem('Nao foi possivel carregar viagens: $erro');
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  void _monitorarConexao() {
    _conexaoSubscription = Connectivity().onConnectivityChanged.listen((
      resultados,
    ) {
      final conectado = resultados.any(
        (resultado) => resultado != ConnectivityResult.none,
      );

      if (conectado) {
        AppLogger.info('APP', 'Conexao detectada. Tentando sincronizar.');
        _sincronizarSeOnline();
      }
    });
  }

  Future<void> _sincronizarSeOnline() async {
    if (kIsWeb) {
      AppLogger.info(
        'APP',
        'Flutter Web nao usa SQLite local; sincronizacao local ignorada.',
      );
      return;
    }

    final resultados = await Connectivity().checkConnectivity();
    final conectado = resultados.any(
      (resultado) => resultado != ConnectivityResult.none,
    );

    if (!conectado) {
      AppLogger.info('APP', 'Sem internet. Sincronizacao ignorada.');
      return;
    }

    try {
      AppLogger.info('APP', 'Internet disponivel. Sincronizando pendencias.');
      final total = await _repository.sincronizarPendentes();

      if (total > 0) {
        _mostrarMensagem('$total viagem(ns) sincronizada(s) com a API.');
        await _carregarViagens();
      }
    } catch (erro) {
      AppLogger.error('APP', 'Falha ao sincronizar pendencias.', erro);
      _mostrarMensagem('Nao foi possivel sincronizar com a API: $erro');
    }
  }

  Future<void> _abrirFormulario([Viagem? viagem]) async {
    final viagemRecebida = await Navigator.push<Viagem>(
      context,
      MaterialPageRoute(builder: (context) => FormularioViagem(viagem: viagem)),
    );

    if (viagemRecebida == null) {
      return;
    }

    try {
      AppLogger.info(
        'APP',
        'Salvando viagem recebida do formulario. id=${viagemRecebida.id}',
      );
      if (viagemRecebida.id == null) {
        await _repository.cadastrar(viagemRecebida);
        _mostrarMensagem('Viagem cadastrada com sucesso.');
      } else {
        await _repository.atualizar(viagemRecebida);
        _mostrarMensagem('Viagem atualizada com sucesso.');
      }

      await _sincronizarSeOnline();
      await _carregarViagens();
    } catch (erro) {
      AppLogger.error('APP', 'Falha ao salvar viagem.', erro);
      _mostrarMensagem('Nao foi possivel salvar a viagem: $erro');
    }
  }

  Future<void> _deletar(Viagem viagem) async {
    final id = viagem.id;
    if (id == null) {
      return;
    }

    try {
      AppLogger.info('APP', 'Excluindo viagem id=$id');
      await _repository.deletar(id);
      _mostrarMensagem('Viagem excluida com sucesso.');
      await _carregarViagens();
    } catch (erro) {
      AppLogger.error('APP', 'Falha ao excluir viagem.', erro);
      _mostrarMensagem('Nao foi possivel excluir a viagem: $erro');
    }
  }

  void _alterarFonte(FontePersistencia fonte) {
    setState(() => _repository.fonte = fonte);
    _sincronizarSeOnline().then((_) => _carregarViagens());
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }
}

class ItemViagem extends StatelessWidget {
  final Viagem viagem;
  final VoidCallback onEditar;
  final VoidCallback onDeletar;

  const ItemViagem(
    this.viagem, {
    super.key,
    required this.onEditar,
    required this.onDeletar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.flight_takeoff),
        title: Text(viagem.destino),
        subtitle: Text(
          '${viagem.dataFormatada} • R\$ ${viagem.valor.toStringAsFixed(2)}',
        ),
        onTap: onEditar,
        trailing: SizedBox(
          width: 96,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!viagem.sincronizado)
                const Tooltip(
                  message: 'Pendente de envio para a API',
                  child: Icon(Icons.sync_problem, color: Colors.orange),
                ),
              IconButton(
                tooltip: 'Excluir',
                onPressed: onDeletar,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
