enum SyncStatus {
  pendente('pendente'),
  sincronizado('sincronizado'),
  erro('erro');

  const SyncStatus(this.valor);

  final String valor;

  static SyncStatus fromString(String? valor) {
    return SyncStatus.values.firstWhere(
      (status) => status.valor == valor,
      orElse: () => SyncStatus.pendente,
    );
  }
}

enum SyncAction {
  nenhuma('nenhuma'),
  criar('criar'),
  atualizar('atualizar'),
  deletar('deletar');

  const SyncAction(this.valor);

  final String valor;

  static SyncAction fromString(String? valor) {
    return SyncAction.values.firstWhere(
      (action) => action.valor == valor,
      orElse: () => SyncAction.nenhuma,
    );
  }
}

class Viagem {
  final int? id;
  final int? remoteId;
  final String destino;
  final DateTime data;
  final double valor;
  final SyncStatus syncStatus;
  final SyncAction syncAction;
  final bool removido;

  const Viagem({
    this.id,
    this.remoteId,
    required this.destino,
    required this.data,
    required this.valor,
    this.syncStatus = SyncStatus.pendente,
    this.syncAction = SyncAction.criar,
    this.removido = false,
  });

  bool get sincronizado =>
      syncStatus == SyncStatus.sincronizado &&
      syncAction == SyncAction.nenhuma &&
      !removido;

  bool get comErro => syncStatus == SyncStatus.erro;

  bool get pendenteSincronizacao => !sincronizado;

  Viagem copyWith({
    int? id,
    int? remoteId,
    String? destino,
    DateTime? data,
    double? valor,
    SyncStatus? syncStatus,
    SyncAction? syncAction,
    bool? removido,
    bool? sincronizado,
  }) {
    return Viagem(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      destino: destino ?? this.destino,
      data: data ?? this.data,
      valor: valor ?? this.valor,
      syncStatus: sincronizado == null
          ? syncStatus ?? this.syncStatus
          : sincronizado
          ? SyncStatus.sincronizado
          : SyncStatus.pendente,
      syncAction: sincronizado == true
          ? SyncAction.nenhuma
          : syncAction ?? this.syncAction,
      removido: removido ?? this.removido,
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
      'sync_status': syncStatus.valor,
      'sync_action': syncAction.valor,
      'removido': removido ? 1 : 0,
    };
  }

  factory Viagem.fromMap(Map<String, Object?> map) {
    final legadoSincronizado = (map['sincronizado'] as int? ?? 0) == 1;
    final syncStatus = map['sync_status'] == null
        ? legadoSincronizado
              ? SyncStatus.sincronizado
              : SyncStatus.pendente
        : SyncStatus.fromString(map['sync_status'] as String?);

    return Viagem(
      id: map['id'] as int?,
      remoteId: map['remote_id'] as int?,
      destino: map['destino'] as String,
      data: DateTime.parse(map['data'] as String),
      valor: (map['valor'] as num).toDouble(),
      syncStatus: syncStatus,
      syncAction: SyncAction.fromString(map['sync_action'] as String?),
      removido: (map['removido'] as int? ?? 0) == 1,
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
      syncStatus: SyncStatus.sincronizado,
      syncAction: SyncAction.nenhuma,
    );
  }

  @override
  String toString() {
    return 'Viagem{id: $id, remoteId: $remoteId, destino: $destino, data: $data, valor: $valor, syncStatus: $syncStatus, syncAction: $syncAction, removido: $removido}';
  }

  String get dataFormatada {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }
}
