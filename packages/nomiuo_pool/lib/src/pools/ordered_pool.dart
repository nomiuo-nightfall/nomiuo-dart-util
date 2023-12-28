part of '../abstract_pool.dart';

class OrderedPool<PoolResourceType extends Object>
    extends AbstractPool<PoolResourceType> {
  OrderedPool._(PoolMeta poolMeta,
      {required FutureOr<PoolResource<PoolResourceType>> Function()
          poolObjectFactory})
      : super(poolMeta, poolObjectFactory: poolObjectFactory);

  static FutureOr<OrderedPool<PoolResourceType>>
      create<PoolResourceType extends Object>(PoolMeta poolMeta,
          {required FutureOr<PoolResource<PoolResourceType>> Function()
              poolObjectFactory}) async {
    final OrderedPool<PoolResourceType> simplePool =
        OrderedPool<PoolResourceType>._(poolMeta,
            poolObjectFactory: poolObjectFactory);
    await simplePool._initResources();
    return simplePool;
  }

  final Queue<PoolObject<PoolResourceType>> _freeResources =
      ListQueue<PoolObject<PoolResourceType>>();

  final Set<PoolObject<PoolResourceType>> _inUseResources =
      <PoolObject<PoolResourceType>>{};

  final Lock _resourceLock = Lock();

  final Duration _retryInterval = const Duration(milliseconds: 50);

  @override
  FutureOr<int> allPoolResources() async =>
      _freeResources.length + _inUseResources.length;

  @override
  Future<void> operateOnResourceWithTimeout(
      OperationOnResource<PoolResourceType> operationOnResource,
      Duration timeout) async {
    final DateTime startWaitTime = DateTime.now();
    while (true) {
      try {
        await _tryHandleWithinAvailableResources(operationOnResource);
        return;
      } on GetResourceFromPoolFailed {
        await Future<void>.delayed(_retryInterval);
      }

      if (timeout == Duration.zero) {
        continue;
      }

      if (DateTime.now().difference(startWaitTime) > timeout) {
        throw const GetResourceFromPoolTimeout(
            'Failed to get resource from pool: The pool has no '
            'resource available and the timeout is reached.');
      }
    }
  }

  @override
  Future<void> operateOnResourceWithoutTimeout(
      OperationOnResource<PoolResourceType> operationOnResource) async {
    await _tryHandleWithinAvailableResources(operationOnResource);
  }

  /// Throws [GetResourceFromPoolFailed] if the pool has no resource and
  /// space left to create new resource.
  ///
  /// Throws [CreateResourceFailed] if failed to create new resource.
  Future<void> _tryHandleWithinAvailableResources(
      OperationOnResource<PoolResourceType> operationOnResource) async {
    try {
      await _tryBorrowFromFreeResourceAndHandle(operationOnResource);
    } on GetResourceFromPoolFailed {
      await _tryCreateAndHandle(operationOnResource);
    }
  }

  Future<void> _tryCreateAndHandle(
      OperationOnResource<PoolResourceType> operationOnResource) async {
    final PoolObject<PoolResourceType> poolObject =
        await _resourceLock.synchronized(() async => _createToPool());

    try {
      await _handle(poolObject, operationOnResource);
    } finally {
      await _resourceLock
          .synchronized(() => _inUseResources.remove(poolObject));
    }

    await _resourceLock.synchronized(() => _freeResources.add(poolObject));
  }

  Future<void> _tryBorrowFromFreeResourceAndHandle(
      OperationOnResource<PoolResourceType> operationOnResource) async {
    final PoolObject<PoolResourceType> poolObject =
        await _resourceLock.synchronized(() async => _borrowFromFreeResource());

    try {
      await _handle(poolObject, operationOnResource);
    } finally {
      await _resourceLock
          .synchronized(() => _inUseResources.remove(poolObject));
    }

    await _resourceLock.synchronized(() => _freeResources.add(poolObject));
  }

  Future<PoolObject<PoolResourceType>> _createToPool() async {
    if (await allPoolResources() < _poolMeta.maxSize) {
      final PoolObject<PoolResourceType> poolObject =
          await _addUsedResourceFromFactory();
      return poolObject;
    }
    throw const GetResourceFromPoolFailed(
        'Failed to get resource from pool: The pool has no resource available'
        ' and the left space is too small to create new resource.');
  }

  Future<PoolObject<PoolResourceType>> _borrowFromFreeResource() async {
    if (_freeResources.isNotEmpty) {
      final PoolObject<PoolResourceType> poolObject =
          _freeResources.removeFirst();
      _inUseResources.add(poolObject);
      return poolObject;
    }

    throw const GetResourceFromPoolFailed('No resource available in the pool');
  }

  Future<void> _handle(PoolObject<PoolResourceType> poolObject,
      OperationOnResource<PoolResourceType> operationOnResource) async {
    try {
      await operationOnResource(poolObject.resource);
    } on Object catch (error, stackTrace) {
      await poolObject.resource.onRelease(error, stackTrace);
      rethrow;
    }

    await poolObject.resource.onReset();
  }

  /// Add a new resource from the factory to the in used resources and return
  /// it.
  ///
  /// Throw [CreateResourceFailed] if failed to create the new resource.
  Future<PoolObject<PoolResourceType>> _addUsedResourceFromFactory() async {
    try {
      final PoolObject<PoolResourceType> poolObject =
          PoolObject<PoolResourceType>(await _poolObjectFactory());
      _inUseResources.add(poolObject);
      return poolObject;
    } on Object catch (e) {
      throw CreateResourceFailed('Failed to create new resource: $e');
    }
  }

  /// Initialize the pool with the minimum size.
  ///
  /// Throws [CreateResourceFailed] if failed to create the minimum size
  /// resources.
  FutureOr<void> _initResources() async {
    for (int i = 0; i < _poolMeta.minSize; i++) {
      try {
        _freeResources
            .add(PoolObject<PoolResourceType>(await _poolObjectFactory()));
      } on Object catch (e) {
        throw CreateResourceFailed('Failed to create new resource: $e');
      }
    }
  }
}
