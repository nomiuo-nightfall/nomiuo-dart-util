part of '../pool.dart';

abstract interface class OperationPool<PoolResourceType extends Object> {
  /// Create a pool with ordered resources.
  static FutureOr<OperationPool<PoolResourceType>>
      // ignore: avoid_shadowing_type_parameters
      createOrderedPool<PoolResourceType extends Object>(PoolMeta poolMeta,
          {required FutureOr<PoolResource<PoolResourceType>> Function()
              poolObjectFactory}) async {
    final OperationPool<PoolResourceType> pool =
        _OperationPoolImpl<PoolResourceType>();

    final _ResourceManager<PoolResourceType> resourceManager =
        await _ResourceManager.createOrderedResourceManager(
      poolMeta,
      poolObjectFactory: poolObjectFactory,
    );
    pool._resourceManager = resourceManager;

    return pool;
  }

  late final _ResourceManager<PoolResourceType> _resourceManager;

  /// All resources count in the pool.
  Future<int> allPoolResources() => _resourceManager.allPoolResources();

  /// Like the [operateOnResourceWithoutTimeout], but with a timeout. It will
  /// wait until the resource is borrowed or the timeout is reached. Note
  /// that the zero duration timeout means wait forever.
  ///
  /// Throw [CreateResourceFailed] if failed to create a new resource.
  ///
  /// If the timeout is reached, then throw an exception
  /// [GetResourceFromPoolTimeout].
  Future<ReturnType> operateOnResourceWithTimeout<ReturnType>(
      OperationOnResource<PoolResourceType, ReturnType> operationOnResource,
      Duration timeout);

  /// Try to borrow a resource from the pool. If the pool has no resource
  /// available, try to create a new one. If the pool is full, then throw an
  /// exception [GetResourceFromPoolFailed].
  ///
  /// Throw [CreateResourceFailed] if failed to create a new resource.
  ///
  /// Notice that it will not catch any exception thrown by the
  /// [PoolResource.onRelease] or [PoolResource.onReset] method, simply rethrow.
  Future<ReturnType> operateOnResourceWithoutTimeout<ReturnType>(
      OperationOnResource<PoolResourceType, ReturnType> operationOnResource);
}
