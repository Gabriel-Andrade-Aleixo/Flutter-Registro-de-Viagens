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
  static const _textBotaoConfirmar = 'Confirmar';

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
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Editor(
              controlador: _controladorDestino,
              rotulo: _rotuloDestino,
              dica: _dicaDestino,
              icone: Icons.place,
              teclado: TextInputType.text,
            ),
            Editor(
              controlador: _controladorData,
              rotulo: _rotuloData,
              dica: _dicaData,
              icone: Icons.calendar_today,
              teclado: TextInputType.none,
              readOnly: true,
              onTap: _selecionarData,
            ),
            Editor(
              controlador: _controladorValor,
              rotulo: _rotuloValor,
              dica: _dicaValor,
              icone: Icons.attach_money,
              teclado: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: () {
                _criarViagem(context);
              },
              child: const Text(_textBotaoConfirmar),
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
      destino: destino,
      data: _dataSelecionada,
      valor: valor,
    );
    Navigator.pop(context, viagemCriada);
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }
}
