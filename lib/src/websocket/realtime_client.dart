import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

enum RealtimeStatus {
  idle,
  connecting,
  connected,
  disconnected,
  reconnecting,
  closed,
}

class RealtimeClient {
  RealtimeClient({
    required this.urlBuilder,
    this.headersBuilder,
    this.reconnect = true,
    this.maxReconnectAttempts = 5,
    this.reconnectDelay = const Duration(seconds: 2),
  });

  final Uri Function() urlBuilder;
  final FutureOr<Map<String, dynamic>?> Function()? headersBuilder;
  final bool reconnect;
  final int maxReconnectAttempts;
  final Duration reconnectDelay;

  final _statusController = StreamController<RealtimeStatus>.broadcast();
  final _messageController = StreamController<dynamic>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  int _reconnectAttempts = 0;
  bool _closedByUser = false;

  Stream<RealtimeStatus> get statusStream => _statusController.stream;

  Stream<dynamic> get messageStream => _messageController.stream;

  RealtimeStatus _status = RealtimeStatus.idle;

  RealtimeStatus get status => _status;

  Future<void> connect() async {
    _closedByUser = false;
    _emitStatus(
      _reconnectAttempts > 0
          ? RealtimeStatus.reconnecting
          : RealtimeStatus.connecting,
    );

    await headersBuilder?.call();
    _channel = WebSocketChannel.connect(urlBuilder());
    _emitStatus(RealtimeStatus.connected);
    _subscription = _channel!.stream.listen(
      _messageController.add,
      onError: (Object error, StackTrace stackTrace) {
        _messageController.addError(error, stackTrace);
        _handleDisconnect();
      },
      onDone: _handleDisconnect,
      cancelOnError: true,
    );
  }

  void send(dynamic data) {
    final channel = _channel;
    if (channel == null) {
      throw StateError('WebSocket 尚未连接');
    }
    if (data is String || data is List<int>) {
      channel.sink.add(data);
    } else {
      channel.sink.add(jsonEncode(data));
    }
  }

  Future<void> close([int? closeCode, String? closeReason]) async {
    _closedByUser = true;
    _emitStatus(RealtimeStatus.closed);
    await _subscription?.cancel();
    await _channel?.sink.close(closeCode, closeReason);
    _subscription = null;
    _channel = null;
  }

  Future<void> dispose() async {
    await close();
    await _statusController.close();
    await _messageController.close();
  }

  void _handleDisconnect() {
    if (_closedByUser) {
      return;
    }
    _emitStatus(RealtimeStatus.disconnected);
    _subscription?.cancel();
    _subscription = null;
    _channel = null;

    if (!reconnect || _reconnectAttempts >= maxReconnectAttempts) {
      return;
    }

    _reconnectAttempts += 1;
    Future<void>.delayed(reconnectDelay, connect);
  }

  void _emitStatus(RealtimeStatus status) {
    _status = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
}
