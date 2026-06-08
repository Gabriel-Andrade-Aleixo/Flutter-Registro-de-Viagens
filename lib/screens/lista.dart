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
  bool _sincronizando = false;

  @override
  void initState() {
    super.initState();
    _sincronizarSeOnline().then((_) => _carregarViagens());
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _carregando
            ? const _LoadingView()
            : RefreshIndicator(
                onRefresh: () async {
                  await _sincronizarSeOnline();
                  await _carregarViagens();
                },
                child: _viagens.isEmpty
                    ? _EmptyView(onCadastrar: () => _abrirFormulario())
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: _viagens.length + 1,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, indice) {
                          if (indice == 0) {
                            return _DashboardViagens(
                              viagens: _viagens,
                              fonte: _repository.fonte,
                              sincronizando: _sincronizando,
                            );
                          }

                          final viagem = _viagens[indice - 1];
                          return ItemViagem(
                            viagem,
                            onEditar: () => _abrirFormulario(viagem),
                            onDeletar: () => _deletar(viagem),
                          );
                        },
                      ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Nova viagem'),
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
      setState(() => _sincronizando = true);
      AppLogger.info('APP', 'Internet disponivel. Sincronizando pendencias.');
      final total = await _repository.sincronizarComApi();

      if (total > 0) {
        _mostrarMensagem('Sincronizacao concluida com a API.');
        await _carregarViagens();
      }
    } catch (erro) {
      AppLogger.error('APP', 'Falha ao sincronizar pendencias.', erro);
      _mostrarMensagem('Nao foi possivel sincronizar com a API: $erro');
    } finally {
      if (mounted) {
        setState(() => _sincronizando = false);
      }
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
      await _repository.deletar(viagem);
      _mostrarMensagem('Viagem excluida com sucesso.');
      await _sincronizarSeOnline();
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
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onEditar,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.flight_takeoff, color: colors.secondary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viagem.destino,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        _InfoPill(
                          icon: Icons.calendar_today,
                          texto: viagem.dataFormatada,
                        ),
                        _InfoPill(
                          icon: Icons.payments_outlined,
                          texto: 'R\$ ${viagem.valor.toStringAsFixed(2)}',
                        ),
                        if (viagem.comErro)
                          const _InfoPill(
                            icon: Icons.error_outline,
                            texto: 'Erro ao enviar',
                            destaque: true,
                          )
                        else if (viagem.pendenteSincronizacao)
                          const _InfoPill(
                            icon: Icons.schedule,
                            texto: 'Local',
                            destaque: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Excluir viagem',
                onPressed: onDeletar,
                icon: const Icon(Icons.delete_outline),
                color: const Color(0xFFE85D4F),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardViagens extends StatelessWidget {
  final List<Viagem> viagens;
  final FontePersistencia fonte;
  final bool sincronizando;

  const _DashboardViagens({
    required this.viagens,
    required this.fonte,
    required this.sincronizando,
  });

  @override
  Widget build(BuildContext context) {
    final valorTotal = viagens.fold<double>(
      0,
      (total, viagem) => total + viagem.valor,
    );
    final pendentes = viagens
        .where((viagem) => viagem.pendenteSincronizacao)
        .length;
    final fonteTexto = fonte == FontePersistencia.local ? 'SQLite' : 'API';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3D6E), Color(0xFF0F9F9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map_outlined, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sincronizando
                      ? 'Sincronizando registros'
                      : 'Resumo das viagens',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _FonteBadge(texto: fonteTexto),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ResumoItem(
                  rotulo: 'Registros',
                  valor: viagens.length.toString(),
                ),
              ),
              Expanded(
                child: _ResumoItem(
                  rotulo: 'Total',
                  valor: 'R\$ ${valorTotal.toStringAsFixed(2)}',
                ),
              ),
              Expanded(
                child: _ResumoItem(rotulo: 'Pendentes', valor: '$pendentes'),
              ),
            ],
          ),
          if (sincronizando) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(
              minHeight: 4,
              color: Colors.white,
              backgroundColor: Color(0x4499E4E0),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResumoItem extends StatelessWidget {
  final String rotulo;
  final String valor;

  const _ResumoItem({required this.rotulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(color: Color(0xFFD8F4F1), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _FonteBadge extends StatelessWidget {
  final String texto;

  const _FonteBadge({required this.texto});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          texto,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String texto;
  final bool destaque;

  const _InfoPill({
    required this.icon,
    required this.texto,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    final cor = destaque ? const Color(0xFFE85D4F) : const Color(0xFF526273);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: cor),
        const SizedBox(width: 4),
        Text(texto, style: TextStyle(color: cor, fontSize: 13)),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/icons/app_icon.png',
              width: 72,
              height: 72,
            ),
          ),
          const SizedBox(height: 22),
          const SizedBox(
            width: 180,
            child: LinearProgressIndicator(minHeight: 4),
          ),
          const SizedBox(height: 14),
          const Text(
            'Carregando suas viagens...',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onCadastrar;

  const _EmptyView({required this.onCadastrar});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 72, 24, 96),
      children: [
        Icon(
          Icons.travel_explore,
          size: 76,
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(height: 18),
        const Text(
          'Nenhuma viagem cadastrada',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Adicione seu primeiro destino para acompanhar datas, valores e sincronizacao.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF526273), fontSize: 15),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onCadastrar,
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('Cadastrar viagem'),
        ),
      ],
    );
  }
}
