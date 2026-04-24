import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tavernup_client/src/infrastructure/websocket_realtime_transport.dart';
import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:uuid/data.dart';
import 'package:uuid/uuid.dart';

class _FakeConnection implements WebSocketConnection {
  final _incoming = StreamController<dynamic>.broadcast();
  final _outgoing = <String>[];
  final _readyCompleter = Completer<void>()..complete();

  List<String> get sent => List.unmodifiable(_outgoing);

  void receive(dynamic raw) => _incoming.add(raw);
  void closeFromServer() => _incoming.close();

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  Future<void> get ready => _readyCompleter.future;

  @override
  void send(String data) => _outgoing.add(data);

  @override
  Future<void> close() async {
    if (!_incoming.isClosed) await _incoming.close();
  }
}

class _StubUuid implements Uuid {
  final List<String> _ids;
  var _i = 0;
  _StubUuid(this._ids);

  @override
  String v4({V4Options? config, Map<String, dynamic>? options}) =>
      _ids[_i++];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeConnection connection;
  late WebSocketRealtimeTransport transport;

  setUp(() {
    connection = _FakeConnection();
    transport = WebSocketRealtimeTransport(
      Uri.parse('ws://localhost:8080'),
      connectionFactory: (_) => connection,
      uuid: _StubUuid(['req-1', 'req-2']),
    );
  });

  test('connect transitions state: disconnected -> connecting -> connected',
      () async {
    final states = <RealtimeConnectionState>[];
    final sub = transport.connectionState.listen(states.add);
    await transport.connect();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(states, [
      RealtimeConnectionState.disconnected,
      RealtimeConnectionState.connecting,
      RealtimeConnectionState.connected,
    ]);
  });

  test('request sends framed message with requestId', () async {
    await transport.connect();
    unawaited(transport.request('validate-user', {'nickname': 'alice'}));
    await Future<void>.delayed(Duration.zero);
    expect(connection.sent, hasLength(1));
    expect(jsonDecode(connection.sent.first), {
      'type': 'validate-user',
      'requestId': 'req-1',
      'payload': {'nickname': 'alice'},
    });
  });

  test('request completes with data when server responds success', () async {
    await transport.connect();
    final future = transport.request('validate-user', {'nickname': 'alice'});
    connection.receive(jsonEncode({
      'requestId': 'req-1',
      'success': true,
      'data': {'userId': 'user-42'},
    }));
    expect(await future, {'userId': 'user-42'});
  });

  test('request throws with server error message on success=false', () async {
    await transport.connect();
    final future = transport.request('validate-user', {'nickname': 'ghost'});
    connection.receive(jsonEncode({
      'requestId': 'req-1',
      'success': false,
      'error': 'User not found: ghost',
    }));
    await expectLater(
      future,
      throwsA(isA<StateError>()
          .having((e) => e.message, 'message', 'User not found: ghost')),
    );
  });

  test('concurrent requests are correlated independently', () async {
    await transport.connect();
    final f1 = transport.request('validate-user', {'nickname': 'alice'});
    final f2 = transport.request('complete-task', {'taskId': 'task-9'});
    connection.receive(jsonEncode({
      'requestId': 'req-2',
      'success': true,
      'data': {'done': true},
    }));
    connection.receive(jsonEncode({
      'requestId': 'req-1',
      'success': true,
      'data': {'userId': 'user-42'},
    }));
    expect(await f2, {'done': true});
    expect(await f1, {'userId': 'user-42'});
  });

  test('subscribe delivers server-initiated pushes by topic', () async {
    await transport.connect();
    final received = <Map<String, dynamic>>[];
    final sub =
        transport.subscribe('user-task-created').listen(received.add);
    connection.receive(jsonEncode({
      'topic': 'user-task-created',
      'payload': {'taskId': 'task-1'},
    }));
    connection.receive(jsonEncode({
      'topic': 'other-event',
      'payload': {'noise': true},
    }));
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(received, [
      {'taskId': 'task-1'}
    ]);
  });

  test('request before connect throws StateError', () {
    expect(
      () => transport.request('x', {}),
      throwsA(isA<StateError>()),
    );
  });

  test('connection close completes pending requests with error', () async {
    await transport.connect();
    final future = transport.request('validate-user', {'nickname': 'alice'});
    connection.closeFromServer();
    await expectLater(future, throwsA(isA<StateError>()));
  });

  test('connection close emits disconnected state', () async {
    await transport.connect();
    final states = <RealtimeConnectionState>[];
    final sub = transport.connectionState.listen(states.add);
    connection.closeFromServer();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(states.last, RealtimeConnectionState.disconnected);
  });
}
