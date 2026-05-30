import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void info(String origem, String mensagem) {
    if (kDebugMode) {
      debugPrint('[$origem] $mensagem');
    }
  }

  static void error(String origem, String mensagem, Object erro) {
    if (kDebugMode) {
      debugPrint('[$origem] ERRO: $mensagem');
      debugPrint('[$origem] DETALHE: $erro');
    }
  }
}
