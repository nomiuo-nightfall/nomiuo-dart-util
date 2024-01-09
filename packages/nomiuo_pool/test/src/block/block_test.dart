import 'dart:async';

import 'package:nomiuo_pool/nomiuo_pool.dart';
import 'package:nomiuo_pool/src/block/block.dart';
@Timeout(Duration(seconds: 10))
import 'package:test/test.dart';

void main() {
  group('Wait for notifier successfully.', () {
    test('One observer binds to one notifier.', () async {
      final Notifier notifier = Notifier();
      final Observer observer = Observer();

      bool callbackCalled = false;
      unawaited(observer.wait(notifier, callback: (Object? obj) {
        callbackCalled = true;
      }));

      await Future<void>.delayed(const Duration(milliseconds: 50), () async {
        await notifier.notifyOne();
        expect(callbackCalled, true);
      });
    }, timeout: const Timeout(Duration(milliseconds: 200)));

    test('One observer binds to one notifier not timeout.', () async {
      final Notifier notifier = Notifier();
      final Observer observer = Observer();

      bool callbackCalled = false;
      unawaited(observer.wait(notifier, timeout: const Duration(seconds: 1),
          callback: (Object? obj) {
        callbackCalled = true;
      }));

      await Future<void>.delayed(const Duration(milliseconds: 50), () async {
        await notifier.notifyOne();
        expect(callbackCalled, true);
      });
    }, timeout: const Timeout(Duration(milliseconds: 200)));

    test('All observers binds to one notifier.', () async {
      final Notifier notifier = Notifier();

      final List<Observer> observers = <Observer>[
        Observer(),
        Observer(),
      ];

      int callbackInvokedCount = 0;
      for (final Observer observer in observers) {
        unawaited(observer.wait(notifier, callback: (Object? obj) {
          callbackInvokedCount++;
        }));
      }

      await Future<void>.delayed(const Duration(milliseconds: 50), () async {
        await notifier.notifyAll();
        expect(callbackInvokedCount, observers.length);
      });
    });

    test('Random wake up one observer.', () async {
      final Notifier notifier = Notifier();
      final Observer observer = Observer();

      bool callbackCalled = false;
      unawaited(observer.wait(notifier, callback: (Object? obj) {
        callbackCalled = true;
      }));

      await Future<void>.delayed(const Duration(milliseconds: 50), () async {
        await notifier.notifyOne();
        expect(callbackCalled, true);
      });
    });

    test('Wake up the specific observer.', () async {
      final Notifier notifier = Notifier();
      final Observer observer = Observer();

      bool callbackCalled = false;
      unawaited(observer.wait(notifier, callback: (Object? obj) {
        callbackCalled = true;
      }));

      await Future<void>.delayed(const Duration(milliseconds: 50), () async {
        await notifier.notify(observer);
        expect(callbackCalled, true);
      });
    });

    test('Notify with a value within notifyOne.', () async {
      final Notifier notifier = Notifier();
      final Observer observer = Observer();
      unawaited(observer.wait(notifier, callback: (Object? obj) {
        expect(obj, 'value');
      }));
      await notifier.notifyOne(obj: 'value');
    });

    test('Notify with a value within notify all.', () async {
      final Notifier notifier = Notifier();
      for (final Observer observer in <Observer>[
        Observer(),
        Observer(),
      ]) {
        unawaited(observer.wait(notifier, callback: (Object? obj) {
          expect(obj, 'value');
        }));
      }
      await notifier.notifyAll(obj: 'value');
    });

    test('Notify with a value within notify.', () async {
      final Notifier notifier = Notifier();
      final Observer observer = Observer();
      unawaited(observer.wait(notifier, callback: (Object? obj) {
        expect(obj, 'value');
      }));
      await notifier.notify(observer, obj: 'value');
    });
  });

  group('Invalid operation.', () {
    test('Wait for notifier timeout.', () async {
      final Notifier notifier = Notifier();
      final Observer observer = Observer();
      expect(
          () async => observer.wait(notifier,
              timeout: const Duration(milliseconds: 50)),
          throwsA(isA<WaitForNotifierTimeout>()));
    });

    test('Wake up the invalid observer.', () async {
      final Notifier notifier = Notifier();
      final Observer observer = Observer();

      expect(() async => notifier.notify(observer),
          throwsA(isA<NoSuchObserver>()));
    });

    test('Repeatedly wait for notifier.', () async {
      final Notifier notifier = Notifier();
      final Observer observer = Observer();

      unawaited(observer.wait(notifier));
      expect(() async => observer.wait(notifier),
          throwsA(isA<ObserverHasWaited>()));
    });

    test('Throw exception in user code.', () async {
      final Notifier notifier = Notifier();
      final Observer observer = Observer();

      expect(
          () async =>
              Future<void>.delayed(const Duration(milliseconds: 25), () async {
                await observer.wait(notifier, callback: (Object? obj) {
                  throw Exception('Test exception.');
                });
              }),
          throwsA(isA<Exception>()));

      await Future<void>.delayed(const Duration(milliseconds: 50), () async {
        await notifier.notifyOne();
      });
    }, timeout: const Timeout(Duration(seconds: 1)));

    test('No available observer.', () async {
      final Notifier notifier = Notifier();
      expect(() async => notifier.notifyOne(), throwsA(isA<NoSuchObserver>()));
    });
  });
}
