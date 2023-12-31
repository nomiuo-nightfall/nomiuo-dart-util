import 'dart:async';

import 'package:nomiuo_pool/nomiuo_pool.dart';
import 'package:test/test.dart';

class _OperateFailed implements Exception {}

class _ReleaseFailed implements Exception {}

class _PoolIntResource extends PoolResource<int> {
  _PoolIntResource(super.resource);
}

class _PoolIntResourceWithReset extends _PoolIntResource {
  _PoolIntResourceWithReset(super.resource);

  @override
  FutureOr<void> onReset() {
    resource = 1;
  }
}

class _PoolIntResourceWithFailedRelease extends _PoolIntResource {
  _PoolIntResourceWithFailedRelease(super.resource);

  @override
  FutureOr<void> onRelease(Object error, StackTrace stackTrace) {
    throw _ReleaseFailed();
  }
}

void main() {
  test('Initialize the resources.', () async {
    final OrderedPool<int> simplePool = await OrderedPool.create(
        PoolMeta(minSize: 5),
        poolObjectFactory: () => _PoolIntResource(1));

    expect(await simplePool.allPoolResources(), 5);
  });

  group('Test execute on resource.', () {
    test('Get a resource and execute.', () async {
      final OrderedPool<int> simplePool = await OrderedPool.create(
          PoolMeta(maxSize: 1),
          poolObjectFactory: () => _PoolIntResource(1));

      await simplePool.operateOnResourceWithoutTimeout(
          (PoolResource<int> poolResource) async {
        poolResource.resource = 2;
      });
      await simplePool
          .operateOnResourceWithoutTimeout((PoolResource<int> poolResource) {
        expect(poolResource.resource, 2);
      });
    });

    test('Reset the state of the resource.', () async {
      final OrderedPool<int> simplePool = await OrderedPool.create(
          PoolMeta(maxSize: 1),
          poolObjectFactory: () => _PoolIntResourceWithReset(1));

      await simplePool.operateOnResourceWithoutTimeout(
          (PoolResource<int> poolResource) async {
        poolResource.resource = 2;
      });
      await simplePool
          .operateOnResourceWithoutTimeout((PoolResource<int> poolResource) {
        expect(poolResource.resource, 1);
      });
    });

    test('Execute the task with timeout zero.', () async {
      final OrderedPool<int> simplePool = await OrderedPool.create(
          PoolMeta(maxSize: 1),
          poolObjectFactory: () => _PoolIntResource(1));

      unawaited(simplePool.operateOnResourceWithoutTimeout(
          (PoolResource<int> poolResource) async {
        await Future<void>.delayed(const Duration(seconds: 1));
      }));

      // Let the loop execute the last event.
      await Future<void>.delayed(const Duration());

      await simplePool.operateOnResourceWithTimeout(
          (PoolResource<int> poolResource) => null, Duration.zero);
    });

    test('Execute the tasks in parallel.', () async {
      final OrderedPool<int> simplePool = await OrderedPool.create(
          PoolMeta(maxSize: 100, minSize: 50),
          poolObjectFactory: () => _PoolIntResource(1));

      for (int i = 0; i < 1000; i++) {
        unawaited(simplePool.operateOnResourceWithTimeout(
            (PoolResource<int> poolResource) async {
          await Future<void>.delayed(const Duration(microseconds: 50));
        }, const Duration()));
      }

      await Future<void>.delayed(const Duration(seconds: 1));

      expect(await simplePool.allPoolResources(), 100);
    });

    test('Wait for the resource successfully.', () async {
      final OrderedPool<int> simplePool = await OrderedPool.create(
          PoolMeta(maxSize: 1),
          poolObjectFactory: () => _PoolIntResource(1));

      unawaited(simplePool.operateOnResourceWithoutTimeout(
          (PoolResource<int> poolResource) async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }));

      // Let the loop execute the last event.
      await Future<void>.delayed(const Duration());

      await simplePool.operateOnResourceWithTimeout(
          (PoolResource<int> poolResource) {}, const Duration(seconds: 1));
    });
  });

  group('Test throw any exception.', () {
    test('Release the resource.', () async {
      final OrderedPool<int> simplePool = await OrderedPool.create(
          PoolMeta(maxSize: 1),
          poolObjectFactory: () => _PoolIntResource(1));

      try {
        await simplePool
            .operateOnResourceWithoutTimeout((PoolResource<int> poolResource) {
          throw _OperateFailed();
        });

        // ignore: dead_code
        fail('Operation which throws an exception works not as expected.');
      } on _OperateFailed {
        expect(await simplePool.allPoolResources(), 0);

        await simplePool.operateOnResourceWithoutTimeout(
            (PoolResource<int> poolResource) {});

        expect(await simplePool.allPoolResources(), 1);
      }
    });

    test('Wait for the resource failed.', () async {
      final OrderedPool<int> simplePool = await OrderedPool.create(
          PoolMeta(maxSize: 1),
          poolObjectFactory: () => _PoolIntResource(1));

      unawaited(simplePool.operateOnResourceWithoutTimeout(
          (PoolResource<int> poolResource) async {
        await Future<void>.delayed(const Duration(seconds: 1));
      }));

      // Let the loop execute the last event.
      await Future<void>.delayed(const Duration());

      try {
        await simplePool.operateOnResourceWithTimeout(
            (PoolResource<int> poolResource) {},
            const Duration(milliseconds: 500));

        fail('Operation which waits for the resource works not as expected.');
      } on Object catch (e) {
        expect(e, isA<GetResourceFromPoolTimeout>());
      }
    });

    test('Get resource from pool failed.', () async {
      final OrderedPool<int> simplePool = await OrderedPool.create(
          PoolMeta(maxSize: 1),
          poolObjectFactory: () => _PoolIntResource(1));

      unawaited(simplePool.operateOnResourceWithoutTimeout(
          (PoolResource<int> poolResource) async {
        await Future<void>.delayed(const Duration(seconds: 1));
      }));

      try {
        await simplePool
            .operateOnResourceWithoutTimeout((PoolResource<int> poolResource) {
          fail('Never reach here because the pool has no resource.');
        });
        // ignore: dead_code
        fail('Never reach here because the pool has no resource.');
      } on Object catch (e) {
        expect(e, isA<GetResourceFromPoolFailed>());
      }
    });

    test('Failed to create new resource.', () async {
      try {
        await OrderedPool.create(PoolMeta(maxSize: 1),
            poolObjectFactory: () =>
                throw const CreateResourceFailed('Failed to create'
                    ' resource.'));
        fail(
            'Never reach here because the pool failed to create new resource.');
      } on Object catch (e) {
        expect(e, isA<CreateResourceFailed>());
      }
    });

    test('Failed to release the resource.', () async {
      final OrderedPool<int> simplePool = await OrderedPool.create(
          PoolMeta(maxSize: 1),
          poolObjectFactory: () => _PoolIntResourceWithFailedRelease(1));

      try {
        await simplePool
            .operateOnResourceWithoutTimeout((PoolResource<int> poolResource) {
          throw _OperateFailed();
        });
      } on _ReleaseFailed {
        return;
      }

      // ignore: dead_code
      fail('Operation which throws an exception works not as expected.');
    });

    test('Create resource failed in execution.', () async {
      final DateTime startTime = DateTime.now();
      final OrderedPool<int> simplePool =
          await OrderedPool.create(PoolMeta(maxSize: 2), poolObjectFactory: () {
        if (DateTime.now().difference(startTime).inSeconds > 1) {
          throw const CreateResourceFailed('Failed to create resource.');
        }
        return _PoolIntResource(1);
      });

      unawaited(simplePool.operateOnResourceWithoutTimeout(
          (PoolResource<int> poolResource) async {
        await Future<void>.delayed(const Duration(seconds: 5));
      }));

      // Let the loop execute the last event.
      await Future<void>.delayed(const Duration(seconds: 2));

      try {
        await simplePool.operateOnResourceWithTimeout(
            (PoolResource<int> poolResource) {
          fail('Never reach here because the pool has no resource.');
        }, const Duration(seconds: 2));
      } on Object catch (e) {
        expect(e, isA<CreateResourceFailed>());
      }
    });
  });

  group('Test return certain value.', () {
    test('Return calculated value.', () async {
      final OrderedPool<int> simplePool = await OrderedPool.create(
          PoolMeta(maxSize: 1),
          poolObjectFactory: () => _PoolIntResource(1));

      final int result = await simplePool.operateOnResourceWithoutTimeout(
          (PoolResource<int> poolResource) => poolResource.resource * 10);
      expect(10, result);
    });

    test('Return Future value.', () async {
      final OrderedPool<int> simplePool = await OrderedPool.create(
          PoolMeta(maxSize: 1),
          poolObjectFactory: () => _PoolIntResource(1));
      final int i = await simplePool.operateOnResourceWithoutTimeout(
          (PoolResource<int> poolResource) => Future<int>.value(1));
      expect(1, i);
    });
  });
}
