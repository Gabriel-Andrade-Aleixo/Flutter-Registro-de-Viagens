class Viagem {
  final String destino;
  final DateTime data;
  final double valor;

  Viagem(this.destino, this.data, this.valor);

  @override
  String toString() {
    return 'Viagem{destino: $destino, data: $data, valor: $valor}';
  }

  String get dataFormatada {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }
}
