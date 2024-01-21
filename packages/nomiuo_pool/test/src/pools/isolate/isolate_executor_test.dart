import 'dart:async';
import 'dart:io';

import 'package:nomiuo_pool/src/model/exceptions/isolate_exceptions.dart';
import 'package:nomiuo_pool/src/pools/isolate/executor/isolate_executor.dart';
import 'package:nomiuo_pool/src/pools/isolate/messages/cancellable_controller.dart';
import 'package:test/test.dart';

class CustomException implements Exception {}

void main() async {
  late IsolateExecutor isolateExecutor;

  setUp(() async => isolateExecutor = await IsolateExecutor.create());

  tearDown(() async => isolateExecutor.close());

  group('Execute the task.', () {
    test('Executor can execute task successfully.', () async {
      final CancellableController<int> cancellableController =
          isolateExecutor.execute(() => 1);
      await cancellableController.future.then((int value) {
        expect(value, 1);
      });
    });
    test('Executor can execute task in timeout.', () async {
      final CancellableController<void> cancellableController =
          isolateExecutor.execute(
              () async =>
                  Future<void>.delayed(const Duration(milliseconds: 200)),
              timeout: const Duration(milliseconds: 300));
      await cancellableController.future;
      expect(isolateExecutor.isFree, isTrue);
    });
    test('Executing the task which throws custom error should throw it.',
        () async {
      final CancellableController<void> cancellableController =
          isolateExecutor.execute(() {
        throw CustomException();
      });
      expect(() async => cancellableController.future,
          throwsA(isA<CustomException>()));
    });
    test('Executing the task status.', () async {
      final CancellableController<void> controller = isolateExecutor.execute(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      expect(isolateExecutor.isRunning, isTrue);
      await controller.future;
      expect(isolateExecutor.isFree, isTrue);
    });
    test('Executing the task but timeout.', () async {
      final CancellableController<void> controller = isolateExecutor.execute(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
          timeout: const Duration(milliseconds: 100));
      expect(isolateExecutor.isRunning, isTrue);
      await expectLater(
          () => controller.future, throwsA(isA<IsolateTaskTimeoutException>()));
      expect(isolateExecutor.isClosed, isTrue);
    });
  });

  group('Pause the task.', () {
    test('Pause the task with timeout.', () async {
      final CancellableController<void> controller = isolateExecutor.execute(
        () async {
          while (true) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }
        },
      );
      expect(isolateExecutor.isRunning, isTrue);
      await controller.pauseInNextTick(
          timeout: const Duration(milliseconds: 100));
      expect(isolateExecutor.isPaused, isTrue);
    });
    test('Pause the task but timeout.', () async {
      final CancellableController<void> controller =
          isolateExecutor.execute(() {
        while (true) {
          sleep(const Duration(milliseconds: 50));
        }
      });
      expect(isolateExecutor.isRunning, isTrue);
      await expectLater(
          () async => controller.pauseInNextTick(
              timeout: const Duration(milliseconds: 100)),
          throwsA(isA<PauseIsolateTaskTimeoutException>()));
      expect(isolateExecutor.isRunning, isTrue);
    });
    test('Pause the task with timeout but successfully.', () async {
      final CancellableController<void> controller =
          isolateExecutor.execute(() async {
        while (true) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      expect(isolateExecutor.isRunning, isTrue);
      await controller.pauseInNextTick(
          timeout: const Duration(milliseconds: 100));
      expect(isolateExecutor.isPaused, isTrue);
    });
    test('Pause the task without timeout and successfully done.', () async {
      final CancellableController<void> controller =
          isolateExecutor.execute(() async {
        while (true) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      expect(isolateExecutor.isRunning, isTrue);
      await controller.pauseInNextTick();
      expect(isolateExecutor.isPaused, isTrue);
    }, timeout: const Timeout(Duration(milliseconds: 150)));
  });

  group('Resume the task.', () {
    test('Resume the task.', () async {
      final CancellableController<void> controller =
          isolateExecutor.execute(() async {
        while (true) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      await controller.pauseInNextTick(
          timeout: const Duration(milliseconds: 100));
      expect(isolateExecutor.isPaused, isTrue);
      controller.resume();
      expect(isolateExecutor.isRunning, isTrue);
    });
  });

  group('Cancel the task.', () {
    test('Cancel the task.', () async {
      final CancellableController<void> controller =
          isolateExecutor.execute(() async {
        while (true) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      expect(isolateExecutor.isRunning, isTrue);
      controller.cancel();
      expect(isolateExecutor.isClosed, isTrue);
      expect(() async => controller.future,
          throwsA(isA<IsolateTaskCancelledException>()));
    });
    test('Cancel the task with sync task.', () async {
      final CancellableController<void> controller =
          isolateExecutor.execute(() {
        while (true) {
          sleep(const Duration(milliseconds: 50));
        }
      });
      expect(isolateExecutor.isRunning, isTrue);
      controller.cancel();
      expect(isolateExecutor.isClosed, isTrue);
      expect(() async => controller.future,
          throwsA(isA<IsolateTaskCancelledException>()));
    });
  });

  group('Work with error status.', () {
    test('Executor of IDLE status can not be resumed.', () async {
      expect(isolateExecutor.resume,
          throwsA(isA<IsolateStatusNotValidException>()));
    });
    test('Executor of IDLE status can not be paused.', () async {
      expect(() async => isolateExecutor.pauseInNextTick(),
          throwsA(isA<IsolateStatusNotValidException>()));
    });

    test('Executor of RUNNING status can not execute task.', () async {
      isolateExecutor.execute(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      expect(() async => isolateExecutor.execute(() {}),
          throwsA(isA<IsolateStatusNotValidException>()));
    });
    test('Executor of RUNNING status can not resume task.', () async {
      isolateExecutor.execute(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      expect(isolateExecutor.resume,
          throwsA(isA<IsolateStatusNotValidException>()));
    });

    test('Executor of PAUSED status can not execute task.', () async {
      isolateExecutor.execute(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await isolateExecutor.pauseInNextTick(
          timeout: const Duration(milliseconds: 100));
      expect(() async => isolateExecutor.execute(() {}),
          throwsA(isA<IsolateStatusNotValidException>()));
    });

    test('Executor of PAUSED status can not pause task again.', () async {
      isolateExecutor.execute(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await isolateExecutor.pauseInNextTick(
          timeout: const Duration(milliseconds: 100));
      expect(() async => isolateExecutor.pauseInNextTick(),
          throwsA(isA<IsolateStatusNotValidException>()));
    });

    test('Executor of CLOSED status can not execute task.', () async {
      isolateExecutor.close();

      expect(() async => isolateExecutor.execute(() {}),
          throwsA(isA<IsolateStatusNotValidException>()));
    });
    test('Executor of CLOSED status can not pause task.', () async {
      isolateExecutor.close();

      expect(() async => isolateExecutor.pauseInNextTick(),
          throwsA(isA<IsolateStatusNotValidException>()));
    });
    test('Executor of CLOSED status can not resume task.', () async {
      isolateExecutor.close();

      expect(() async => isolateExecutor.resume(),
          throwsA(isA<IsolateStatusNotValidException>()));
    });
  });
}
