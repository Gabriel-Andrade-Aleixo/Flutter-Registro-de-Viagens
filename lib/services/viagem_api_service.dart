import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/viagem.dart';
import 'app_logger.dart';

class ViagemApiService {
  ViagemApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? _resolverBaseUrl() {
    AppLogger.info('API-HTTP', 'Base URL configurada: $_baseUrl');
  }

  static const _apiBaseUrlDefinida = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  final http.Client _client;
  final String _baseUrl;

  static String _resolverBaseUrl() {
    if (_apiBaseUrlDefinida.isNotEmpty) {
      return _apiBaseUrlDefinida;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }

    return 'http://localhost:3000';
  }

  Uri _uri([String path = '']) => Uri.parse('$_baseUrl/viagens$path');

  Future<List<Viagem>> listar() async {
    final uri = _uri();
    AppLogger.info('API-HTTP', 'GET $uri');
    final response = await _client.get(uri);
    AppLogger.info('API-HTTP', 'GET $uri -> ${response.statusCode}');
    _validarResposta(response);

    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => Viagem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Viagem> cadastrar(Viagem viagem) async {
    final uri = _uri();
    AppLogger.info(
      'API-HTTP',
      'POST $uri destino=${viagem.destino}, localId=${viagem.id}',
    );
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(viagem.toJson()),
    );
    AppLogger.info('API-HTTP', 'POST $uri -> ${response.statusCode}');
    _validarResposta(response, statusEsperado: 201);
    return Viagem.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Viagem> atualizar(Viagem viagem) async {
    final idRemoto = viagem.remoteId ?? viagem.id;
    if (idRemoto == null) {
      throw ArgumentError('Nao e possivel atualizar uma viagem sem id.');
    }

    final uri = _uri('/$idRemoto');
    AppLogger.info(
      'API-HTTP',
      'PUT $uri destino=${viagem.destino}, localId=${viagem.id}',
    );
    final response = await _client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(viagem.toJson()),
    );
    AppLogger.info('API-HTTP', 'PUT $uri -> ${response.statusCode}');
    _validarResposta(response);
    return Viagem.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deletar(int id) async {
    final uri = _uri('/$id');
    AppLogger.info('API-HTTP', 'DELETE $uri');
    final response = await _client.delete(uri);
    AppLogger.info('API-HTTP', 'DELETE $uri -> ${response.statusCode}');
    _validarResposta(response, statusEsperado: 204);
  }

  void _validarResposta(http.Response response, {int statusEsperado = 200}) {
    if (response.statusCode != statusEsperado) {
      throw Exception('Erro na API (${response.statusCode}): ${response.body}');
    }
  }
}
