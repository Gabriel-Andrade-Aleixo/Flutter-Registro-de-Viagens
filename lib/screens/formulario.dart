import 'package:flutter/material.dart';
import '../components/editor.dart';
import '../models/viagem.dart';

class FormularioViagem extends StatefulWidget {
  final Viagem? viagem;

  const FormularioViagem({super.key, this.viagem});

  @override
  State<FormularioViagem> createState() => _FormularioViagemState();
}

class _FormularioViagemState extends State<FormularioViagem> {
  static const _rotuloDestino = 'Destino';
  static const _dicaDestino = 'Ex.: Rio de Janeiro';
  static const _rotuloValor = 'Valor';
  static const _dicaValor = '0.00';
  static const _rotuloData = 'Data da viagem';
  static const _dicaData = 'Selecione a data';

  final TextEditingController _controladorDestino = TextEditingController();
  final TextEditingController _controladorValor = TextEditingController();
  final TextEditingController _controladorData = TextEditingController();

  DateTime _dataSelecionada = DateTime.now();

  @override
  void initState() {
    super.initState();

    final viagem = widget.viagem;
    if (viagem != null) {
      _controladorDestino.text = viagem.destino;
      _controladorValor.text = viagem.valor.toStringAsFixed(2);
      _dataSelecionada = viagem.data;
    }

    _controladorData.text = _formatarData(_dataSelecionada);
  }

  @override
  void dispose() {
    _controladorDestino.dispose();
    _controladorValor.dispose();
    _controladorData.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.viagem == null ? 'Criando Viagem' : 'Editando Viagem',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F3D6E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_location_alt_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.viagem == null
                              ? 'Novo destino'
                              : 'Atualizar destino',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Preencha as informacoes da viagem',
                          style: TextStyle(color: Color(0xFFD8F4F1)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Editor(
                      controlador: _controladorDestino,
                      rotulo: _rotuloDestino,
                      dica: _dicaDestino,
                      icone: Icons.place_outlined,
                      teclado: TextInputType.text,
                    ),
                    const SizedBox(height: 14),
                    Editor(
                      controlador: _controladorData,
                      rotulo: _rotuloData,
                      dica: _dicaData,
                      icone: Icons.calendar_today,
                      teclado: TextInputType.none,
                      readOnly: true,
                      onTap: _selecionarData,
                    ),
                    const SizedBox(height: 14),
                    Editor(
                      controlador: _controladorValor,
                      rotulo: _rotuloValor,
                      dica: _dicaValor,
                      icone: Icons.payments_outlined,
                      teclado: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                _criarViagem(context);
              },
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                widget.viagem == null
                    ? 'Cadastrar viagem'
                    : 'Salvar alteracoes',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selecionarData() async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (data != null) {
      setState(() {
        _dataSelecionada = data;
        _controladorData.text = _formatarData(data);
      });
    }
  }

  void _criarViagem(BuildContext context) {
    final String destino = _controladorDestino.text.trim();
    final double? valor = double.tryParse(
      _controladorValor.text.replaceAll(',', '.'),
    );

    if (destino.isEmpty || valor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha destino e valor corretamente.')),
      );
      return;
    }

    final viagemCriada = Viagem(
      id: widget.viagem?.id,
      remoteId: widget.viagem?.remoteId,
      destino: destino,
      data: _dataSelecionada,
      valor: valor,
      syncStatus: widget.viagem?.syncStatus ?? SyncStatus.pendente,
      syncAction: widget.viagem?.syncAction ?? SyncAction.criar,
      removido: widget.viagem?.removido ?? false,
    );
    Navigator.pop(context, viagemCriada);
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }
}
