import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:tavernup_process_camunda/tavernup_process_camunda.dart';
import 'package:test/test.dart';

/// Builds a Dio instance whose requests are intercepted and answered by
/// [respond]. [capture] records the last intercepted request for assertions.
({Dio dio, _Capture captured}) _fakeDio({
  required dynamic Function(RequestOptions options) respond,
  int statusCode = 200,
}) {
  final captured = _Capture();
  final dio = Dio();
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      captured.last = options;
      handler.resolve(Response<dynamic>(
        requestOptions: options,
        statusCode: statusCode,
        data: respond(options),
      ));
    },
  ));
  return (dio: dio, captured: captured);
}

/// Variant that answers every request with an HTTP error.
({Dio dio, _Capture captured}) _errorDio({
  required int statusCode,
  required dynamic body,
}) {
  final captured = _Capture();
  final dio = Dio();
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      captured.last = options;
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: statusCode,
            data: body,
          ),
          type: DioExceptionType.badResponse,
        ),
        true,
      );
    },
  ));
  return (dio: dio, captured: captured);
}

class _Capture {
  RequestOptions? last;
}

CamundaProcessEngine _engine(Dio dio) => CamundaProcessEngine(
      baseUrl: 'http://localhost:8081/engine-rest',
      dio: dio,
    );

void main() {
  group('Variable encoding', () {
    test('startProcess encodes all variable types in Camunda shape', () async {
      final fake = _fakeDio(respond: (_) => {'id': 'pi-1'});
      final engine = _engine(fake.dio);

      await engine.startProcess(
        processKey: 'my-process',
        variables: {
          'name': Variable.string('alice'),
          'count': Variable.integer(3),
          'rate': Variable.double(1.5),
          'flag': Variable.boolean(true),
          'meta': Variable.json({'k': 'v'}),
        },
      );

      final body = fake.captured.last!.data as Map<String, dynamic>;
      final vars = body['variables'] as Map<String, dynamic>;

      expect(vars['name'], {'value': 'alice', 'type': 'String'});
      expect(vars['count'], {'value': 3, 'type': 'Integer'});
      expect(vars['rate'], {'value': 1.5, 'type': 'Double'});
      expect(vars['flag'], {'value': true, 'type': 'Boolean'});
      expect(vars['meta'], {
        'value': jsonEncode({'k': 'v'}),
        'type': 'Json',
      });
    });

    test('fetchAndLockWorkerTasks decodes all variable types', () async {
      final fake = _fakeDio(respond: (_) => [
            {
              'id': 'task-1',
              'topicName': 'do-stuff',
              'activityId': 'ServiceTask_1',
              'processInstanceId': 'pi-9',
              'variables': {
                'name': {'value': 'alice', 'type': 'String'},
                'count': {'value': 3, 'type': 'Integer'},
                'rate': {'value': 1.5, 'type': 'Double'},
                'flag': {'value': true, 'type': 'Boolean'},
                'meta': {
                  'value': jsonEncode({'k': 'v'}),
                  'type': 'Json',
                },
              },
            }
          ]);
      final engine = _engine(fake.dio);

      final tasks = await engine.fetchAndLockWorkerTasks(
        topicName: 'do-stuff',
        workerId: 'w-1',
      );

      expect(tasks, hasLength(1));
      final vars = tasks.single.variables;
      expect(vars['name'], Variable.string('alice'));
      expect(vars['count'], Variable.integer(3));
      expect(vars['rate'], Variable.double(1.5));
      expect(vars['flag'], Variable.boolean(true));
      expect(vars['meta'], Variable.json({'k': 'v'}));
    });
  });

  group('Requests', () {
    test('startProcess hits /process-definition/key/{key}/start', () async {
      final fake = _fakeDio(respond: (_) => {'id': 'pi-1'});
      final engine = _engine(fake.dio);

      final pid = await engine.startProcess(processKey: 'invitation');

      expect(fake.captured.last!.method, 'POST');
      expect(fake.captured.last!.path,
          '/process-definition/key/invitation/start');
      expect(pid, 'pi-1');
    });

    test('completeUserTask hits /task/{id}/complete with variables', () async {
      final fake = _fakeDio(respond: (_) => null);
      final engine = _engine(fake.dio);

      await engine.completeUserTask(
        taskId: 'task-99',
        variables: {'accepted': Variable.boolean(true)},
      );

      expect(fake.captured.last!.method, 'POST');
      expect(fake.captured.last!.path, '/task/task-99/complete');
      expect(fake.captured.last!.data, {
        'variables': {
          'accepted': {'value': true, 'type': 'Boolean'}
        }
      });
    });

    test(
        'fetchAndLockWorkerTasks posts topic + workerId + lockDuration',
        () async {
      final fake = _fakeDio(respond: (_) => []);
      final engine = _engine(fake.dio);

      await engine.fetchAndLockWorkerTasks(
        topicName: 'entity-operation',
        workerId: 'tavernup-server-1',
        lockDurationMs: 60000,
        variables: ['entityType', 'operation'],
      );

      expect(fake.captured.last!.path, '/external-task/fetchAndLock');
      final body = fake.captured.last!.data as Map<String, dynamic>;
      expect(body['workerId'], 'tavernup-server-1');
      final topics = (body['topics'] as List).cast<Map<String, dynamic>>();
      expect(topics.single['topicName'], 'entity-operation');
      expect(topics.single['lockDuration'], 60000);
      expect(topics.single['variables'], ['entityType', 'operation']);
    });

    test('completeWorkerTask includes workerId', () async {
      final fake = _fakeDio(respond: (_) => null);
      final engine = _engine(fake.dio);

      await engine.completeWorkerTask(
        taskId: 'ext-1',
        workerId: 'tavernup-server-1',
        variables: {'entityId': Variable.string('abc')},
      );

      expect(fake.captured.last!.path, '/external-task/ext-1/complete');
      final body = fake.captured.last!.data as Map<String, dynamic>;
      expect(body['workerId'], 'tavernup-server-1');
      expect(body['variables'], {
        'entityId': {'value': 'abc', 'type': 'String'}
      });
    });

    test('failWorkerTask includes errorMessage and retries', () async {
      final fake = _fakeDio(respond: (_) => null);
      final engine = _engine(fake.dio);

      await engine.failWorkerTask(
        taskId: 'ext-1',
        workerId: 'w-1',
        errorMessage: 'validation failed',
        retries: 2,
      );

      expect(fake.captured.last!.path, '/external-task/ext-1/failure');
      final body = fake.captured.last!.data as Map<String, dynamic>;
      expect(body['errorMessage'], 'validation failed');
      expect(body['retries'], 2);
    });

    test('cancelProcess hits DELETE /process-instance/{id}', () async {
      final fake = _fakeDio(respond: (_) => null);
      final engine = _engine(fake.dio);

      await engine.cancelProcess('pi-42');

      expect(fake.captured.last!.method, 'DELETE');
      expect(fake.captured.last!.path, '/process-instance/pi-42');
    });

    test('deploy sends multipart form', () async {
      final fake = _fakeDio(respond: (_) => {'id': 'deploy-1'});
      final engine = _engine(fake.dio);

      await engine.deploy(
        resourceName: 'invitation.bpmn',
        resource: Uint8List.fromList([1, 2, 3]),
      );

      expect(fake.captured.last!.method, 'POST');
      expect(fake.captured.last!.path, '/deployment/create');
      expect(fake.captured.last!.data, isA<FormData>());
    });

    test('getOpenUserTasks filters by assignee and processInstanceId',
        () async {
      final fake = _fakeDio(respond: (_) => [
            {
              'id': 't-1',
              'name': 'accept-invitation',
              'assignee': 'user-42',
              'processInstanceId': 'pi-1',
              'created': '2026-04-24T12:00:00',
            }
          ]);
      final engine = _engine(fake.dio);

      final tasks = await engine.getOpenUserTasks(
        userId: 'user-42',
        processInstanceId: 'pi-1',
      );

      expect(fake.captured.last!.method, 'GET');
      expect(fake.captured.last!.path, '/task');
      expect(fake.captured.last!.queryParameters, {
        'assignee': 'user-42',
        'processInstanceId': 'pi-1',
      });
      expect(tasks, hasLength(1));
      expect(tasks.single.id, 't-1');
      expect(tasks.single.assignee, 'user-42');
    });
  });

  group('Error handling', () {
    test('404 on completeUserTask throws ArgumentError with context',
        () async {
      final fake = _errorDio(
        statusCode: 404,
        body: {'type': 'RestException', 'message': 'No task found'},
      );
      final engine = _engine(fake.dio);

      await expectLater(
        engine.completeUserTask(taskId: 'missing'),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('missing'),
        )),
      );
    });

    test('400 on startProcess throws StateError with server message',
        () async {
      final fake = _errorDio(
        statusCode: 400,
        body: {
          'type': 'InvalidRequestException',
          'message': 'No matching process definition'
        },
      );
      final engine = _engine(fake.dio);

      await expectLater(
        engine.startProcess(processKey: 'nonexistent'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('No matching process definition'),
        )),
      );
    });
  });
}
