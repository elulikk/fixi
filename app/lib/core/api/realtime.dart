import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/models.dart';

class WsEvent {
  final String type;
  final Map<String, dynamic> data;
  const WsEvent(this.type, this.data);
}

/// Conexión WebSocket con reconexión automática (backoff exponencial).
class RealtimeService {
  RealtimeService({required this.baseUrl, required this.token});
  final String Function() baseUrl;
  final String? Function() token;

  final _ctrl = StreamController<WsEvent>.broadcast();
  final ValueNotifier<bool> connected = ValueNotifier(false);
  WebSocketChannel? _ch;
  StreamSubscription? _sub;
  Timer? _retry;
  int _attempt = 0;
  bool _running = false;

  Stream<WsEvent> get events => _ctrl.stream;

  void start() {
    if (_running) return;
    _running = true;
    _attempt = 0;
    _connect();
  }

  void stop() {
    _running = false;
    _retry?.cancel();
    _sub?.cancel();
    _ch?.sink.close();
    _ch = null;
    connected.value = false;
  }

  void restart() {
    stop();
    start();
  }

  void _connect() {
    final t = token();
    if (!_running || t == null) return;
    final base = baseUrl().replaceAll(RegExp(r'/+$'), '');
    final wsBase = base.startsWith('https') ? base.replaceFirst('https', 'wss') : base.replaceFirst('http', 'ws');
    try {
      final ch = WebSocketChannel.connect(Uri.parse('$wsBase/ws?token=${Uri.encodeQueryComponent(t)}'));
      _ch = ch;
      _sub = ch.stream.listen(
        (raw) {
          if (!connected.value) {
            connected.value = true;
            _attempt = 0;
          }
          try {
            final j = jsonDecode('$raw');
            if (j is Map && j['type'] != null) _ctrl.add(WsEvent('${j['type']}', asMap(j['data'])));
          } catch (_) {}
        },
        onDone: _scheduleRetry,
        onError: (_) => _scheduleRetry(),
        cancelOnError: true,
      );
      // Si el canal abre sin mensajes, igual lo damos por conectado tras un instante.
      ch.ready.then((_) {
        if (_ch == ch) {
          connected.value = true;
          _attempt = 0;
        }
      }).catchError((_) {});
    } catch (_) {
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    connected.value = false;
    _sub?.cancel();
    if (!_running) return;
    _retry?.cancel();
    final secs = min(30, pow(2, _attempt).toInt());
    _attempt = min(_attempt + 1, 6);
    _retry = Timer(Duration(seconds: secs), _connect);
  }

  void dispose() {
    stop();
    _ctrl.close();
  }
}
