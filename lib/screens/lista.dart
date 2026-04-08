import 'package:flutter/material.dart';
import '../../models/viagem.dart';
import 'formulario.dart';

class ListaViagens extends StatefulWidget {
  const ListaViagens({super.key});

  @override
  State<ListaViagens> createState() => _ListaViagensState();
}

class _ListaViagensState extends State<ListaViagens> {
  static const _tituloAppBar = 'Registro de Viagens';
  final List<Viagem> _viagens = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(_tituloAppBar)),
      body: _viagens.isEmpty
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
                return ItemViagem(viagem);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FormularioViagem()),
          ).then((viagemRecebida) => _atualiza(viagemRecebida));
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _atualiza(Viagem? viagemRecebida) {
    if (viagemRecebida != null) {
      setState(() {
        _viagens.add(viagemRecebida);
      });
    }
  }
}

class ItemViagem extends StatelessWidget {
  final Viagem viagem;

  const ItemViagem(this.viagem, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.flight_takeoff),
        title: Text(viagem.destino),
        subtitle: Text(
          '${viagem.dataFormatada} • R\$ ${viagem.valor.toStringAsFixed(2)}',
        ),
      ),
    );
  }
}
