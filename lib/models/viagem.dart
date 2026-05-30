class Viagem {
  final int? id;
  final int? remoteId;
  final String destino;
  final DateTime data;
  final double valor;
  final bool sincronizado;

  const Viagem({
    this.id,
    this.remoteId,
    required this.destino,
    required this.data,
    required this.valor,
    this.sincronizado = false,
  });

  Viagem copyWith({
    int? id,
    int? remoteId,
    String? destino,
    DateTime? data,
    double? valor,
    bool? sincronizado,
  }) {
    return Viagem(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      destino: destino ?? this.destino,
      data: data ?? this.data,
      valor: valor ?? this.valor,
      sincronizado: sincronizado ?? this.sincronizado,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'remote_id': remoteId,
      'destino': destino,
      'data': data.toIso8601String(),
      'valor': valor,
      'sincronizado': sincronizado ? 1 : 0,
    };
  }

  factory Viagem.fromMap(Map<String, Object?> map) {
    return Viagem(
      id: map['id'] as int?,
      remoteId: map['remote_id'] as int?,
      destino: map['destino'] as String,
      data: DateTime.parse(map['data'] as String),
      valor: (map['valor'] as num).toDouble(),
      sincronizado: (map['sincronizado'] as int? ?? 0) == 1,
    );
  }

  Map<String, Object?> toJson() {
    return {'destino': destino, 'data': data.toIso8601String(), 'valor': valor};
  }

  factory Viagem.fromJson(Map<String, dynamic> json) {
    return Viagem(
      id: json['id'] as int?,
      remoteId: json['id'] as int?,
      destino: json['destino'] as String,
      data: DateTime.parse(json['data'] as String),
      valor: (json['valor'] as num).toDouble(),
      sincronizado: true,
    );
  }

  @override
  String toString() {
    return 'Viagem{id: $id, remoteId: $remoteId, destino: $destino, data: $data, valor: $valor, sincronizado: $sincronizado}';
  }

  String get dataFormatada {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }
}
