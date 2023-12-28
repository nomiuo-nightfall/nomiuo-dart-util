import 'dart:async';

import 'package:nomiuo_pool/orange_pool.dart';
import 'package:test/test.dart';

class OperateFailed implements Exception {}

class ReleaseFailed implements Exception {}

class PoolIntResource extends PoolResource<int> {
  PoolIntResource(super.resource);
}

class PoolIntResourceWithReset extends PoolIntResource {
  PoolIntResourceWithReset(super.resource);

  @override
  FutureOr<void> onReset() {
    resource = 1;
  }
}

class PoolIntResourceWithFailedRelease extends PoolIntResource {
  PoolIntResourceWithFailedRelease(super.resource);

  @override
  FutureOr<void> onRelease(Object error, StackTrace stackTrace) {
    throw ReleaseFailed();
  }
}

void main() {
  test('Initialize the resources.', () async {
    final OrderedPool<int> simplePool = await OrderedPool.create(
        PoolMeta(minSize: 5),
        poolObjectFactory: () => PoolIntResource(1));

    expect(await simplePool.allPoolResources(), 5);
  });

  test('Get a resource and execute.', () async {
    final OrderedPool<int> simplePool = await OrderedPool.create(
        PoolMeta(maxSize: 1),
        poolObjectFactory: () => PoolIntResource(1));

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
        poolObjectFactory: () => PoolIntResourceWithReset(1));

    await simplePool.operateOnResourceWithoutTimeout(
        (PoolResource<int> poolResource) async {
      poolResource.resource = 2;
    });
    await simplePool
        .operateOnResourceWithoutTimeout((PoolResource<int> poolResource) {
      expect(poolResource.resource, 1);
    });
  });

  test('Release the resource.', () async {
    final OrderedPool<int> simplePool = await OrderedPool.create(
        PoolMeta(maxSize: 1),
        poolObjectFactory: () => PoolIntResource(1));

    try {
      await simplePool
          .operateOnResourceWithoutTimeout((PoolResource<int> poolResource) {
        throw OperateFailed();
      });

      fail('Operation which throws an exception works not as expected.');
    } on OperateFailed {
      expect(await simplePool.allPoolResources(), 0);

      await simplePool
          .operateOnResourceWithoutTimeout((PoolResource<int> poolResource) {});

      expect(await simplePool.allPoolResources(), 1);
    }
  });

  test('Failed to release the resource.', () async {
    final OrderedPool<int> simplePool = await OrderedPool.create(
        PoolMeta(maxSize: 1),
        poolObjectFactory: () => PoolIntResourceWithFailedRelease(1));

    try {
      await simplePool
          .operateOnResourceWithoutTimeout((PoolResource<int> poolResource) {
        throw OperateFailed();
      });
    } on ReleaseFailed {
      return;
    }

    fail('Operation which throws an exception works not as expected.');
  });

  test('Wait for the resource failed.', () async {
    final OrderedPool<int> simplePool = await OrderedPool.create(
        PoolMeta(maxSize: 1),
        poolObjectFactory: () => PoolIntResource(1));

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

  test('Wait for the resource successfully.', () async {
    final OrderedPool<int> simplePool = await OrderedPool.create(
        PoolMeta(maxSize: 1),
        poolObjectFactory: () => PoolIntResource(1));

    unawaited(simplePool.operateOnResourceWithoutTimeout(
        (PoolResource<int> poolResource) async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }));

    // Let the loop execute the last event.
    await Future<void>.delayed(const Duration());

    await simplePool.operateOnResourceWithTimeout(
        (PoolResource<int> poolResource) {}, const Duration(seconds: 1));
  });

  test('Get resource from pool failed.', () async {
    final OrderedPool<int> simplePool = await OrderedPool.create(
        PoolMeta(maxSize: 1),
        poolObjectFactory: () => PoolIntResource(1));

    unawaited(simplePool.operateOnResourceWithoutTimeout(
        (PoolResource<int> poolResource) async {
      await Future<void>.delayed(const Duration(seconds: 1));
    }));

    try {
      await simplePool
          .operateOnResourceWithoutTimeout((PoolResource<int> poolResource) {
        fail('Never reach here because the pool has no resource.');
      });
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
      fail('Never reach here because the pool failed to create new resource.');
    } on Object catch (e) {
      expect(e, isA<CreateResourceFailed>());
    }
  });

  test('Execute the task with timeout zero.', () async {
    final OrderedPool<int> simplePool = await OrderedPool.create(
        PoolMeta(maxSize: 1),
        poolObjectFactory: () => PoolIntResource(1));

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
        poolObjectFactory: () => PoolIntResource(1));

    for (int i = 0; i < 1000; i++) {
      unawaited(simplePool.operateOnResourceWithTimeout(
          (PoolResource<int> poolResource) async {
        await Future<void>.delayed(const Duration(microseconds: 50));
      }, const Duration()));
    }

    await Future<void>.delayed(const Duration(seconds: 1));

    expect(await simplePool.allPoolResources(), 100);
  });

  test('Create resource failed in execution.', () async {
    final DateTime startTime = DateTime.now();
    final OrderedPool<int> simplePool =
        await OrderedPool.create(PoolMeta(maxSize: 2), poolObjectFactory: () {
      if (DateTime.now().difference(startTime).inSeconds > 1) {
        throw const CreateResourceFailed('Failed to create resource.');
      }
      return PoolIntResource(1);
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
}
