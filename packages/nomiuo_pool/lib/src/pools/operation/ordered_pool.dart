part of '../pool.dart';

class _OperationPoolImpl<PoolResourceType extends Object>
    implements OperationPool<PoolResourceType> {
  @override
  late final _ResourceManager<PoolResourceType> _resourceManager;

  @override
  Future<int> allPoolResources() => _resourceManager.allPoolResources();

  @override
  Future<ReturnType> operateOnResourceWithTimeout<ReturnType>(
          OperationOnResource<PoolResourceType, ReturnType> operationOnResource,
          Duration timeout) async =>
      _tryHandleWithinAvailableResources(operationOnResource, timeout: timeout);

  @override
  Future<ReturnType> operateOnResource<ReturnType>(
          OperationOnResource<PoolResourceType, ReturnType>
              operationOnResource) async =>
      _tryHandleWithinAvailableResources(operationOnResource);

  /// Throws [GetResourceFromPoolTimeout] if the pool has no resource and
  /// space left to create new resource.
  ///
  /// Throws [CreateResourceFailed] if failed to create new resource.
  Future<ReturnType> _tryHandleWithinAvailableResources<ReturnType>(
      OperationOnResource<PoolResourceType, ReturnType> operationOnResource,
      {Duration? timeout}) async {
    final _PoolObject<PoolResourceType> poolObject =
        await _resourceManager.borrowAvailableResource(timeout: timeout);
    return _handleWithinResourcePool(poolObject, operationOnResource);
  }

  Future<ReturnType> _handleWithinResourcePool<ReturnType>(
      _PoolObject<PoolResourceType> poolObject,
      OperationOnResource<PoolResourceType, ReturnType>
          operationOnResource) async {
    final ReturnType result;
    try {
      result = await _handle(poolObject, operationOnResource);
    } finally {
      await _resourceManager.freeUsedResource(poolObject);
    }

    await _resourceManager.addFreeResource(poolObject);

    return result;
  }

  Future<ReturnType> _handle<ReturnType>(
      _PoolObject<PoolResourceType> poolObject,
      OperationOnResource<PoolResourceType, ReturnType>
          operationOnResource) async {
    final ReturnType result;
    try {
      result = await operationOnResource(poolObject.resource);
    } on Object catch (error, stackTrace) {
      await poolObject.resource.onRelease(error, stackTrace);
      rethrow;
    }

    await poolObject.resource.onReset();

    return result;
  }
}
