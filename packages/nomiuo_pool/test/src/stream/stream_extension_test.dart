import 'dart:async';
import 'dart:isolate';

import 'package:nomiuo_pool/nomiuo_pool_util.dart';
import 'package:nomiuo_pool/src/model/exceptions/stream_exceptions.dart';
import 'package:test/test.dart';

void main() {
  test('Stream receives error.', () async {
    final StreamController<Object?> controller = StreamController<Object?>();
    final Stream<Object?> stream = controller.stream;
    final Future<void> catchError =
        stream.firstWithTimeout(const Duration(milliseconds: 100));
    controller.addError('error');
    expect(() async => catchError, throwsA(isA<String>()));
    await controller.close();
  });
  test('Receive port receives data in time.', () async {
    final ReceivePort receivePort = ReceivePort();
    final Future<void> catchError = receivePort
        .firstWithTimeout(const Duration(milliseconds: 100))
        .then((Object? value) {
      expect(value, 'test');
    }).catchError((Object? error) => fail('Receive port should not timeout.'));
    receivePort.sendPort.send('test');
    await catchError;
  });

  test('Receive port receives data timeout.', () async {
    final ReceivePort receivePort = ReceivePort();
    final Future<void> catchError = receivePort
        .firstWithTimeout(const Duration(milliseconds: 100))
        .then((Object? value) {
      fail('Receive port should not receive data.');
      // ignore: dead_code
      return;
    }).catchError((Object? error) {
      throwsA(isA<StreamWaitTimeout>());
    });
    await catchError;
  });

  test('Receive port should call timeout callback when timeout.', () async {
    final ReceivePort receivePort = ReceivePort();
    bool called = false;
    final Future<void> catchError = receivePort
        .firstWithTimeout(const Duration(milliseconds: 100),
            onTimeout: () => called = true)
        .then((Object? value) {
      fail('Receive port should not receive data.');
      // ignore: dead_code
      return;
    }).catchError((Object? error) {
      expect(called, true);
      throwsA(isA<StreamWaitTimeout>());
    });
    await catchError;
  });

  test('Receive port timeout and call timeout callback that throws an error.',
      () async {
    final ReceivePort receivePort = ReceivePort();
    final Future<void> catchError = receivePort
        .firstWithTimeout(const Duration(milliseconds: 100), onTimeout: () {
      throw TimeoutException('test');
    }).then((Object? value) {
      fail('Receive port should not receive data.');
      // ignore: dead_code
      return;
    }).catchError((Object? error) {
      throwsA(isA<TimeoutException>());
    });
    await catchError;
  });

  test('Receive port receives specific data', () async {
    final ReceivePort receivePort = ReceivePort();
    final Future<void> future = receivePort
        .firstWhereWithTimeout((Object? element) => element == 'test',
            timeout: const Duration(milliseconds: 100),
            onTimeout: () => fail('Receive port should not timeout.'))
        .then((Object? value) {
      expect(value, 'test');
    });

    receivePort.sendPort.send('test');
    receivePort.sendPort.send('test2');
    await future;
  });
}
