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
      Duration timeout) async {
    final DateTime startWaitTime = DateTime.now();
    final Completer<ReturnType> completer = Completer<ReturnType>();

    Timer.periodic(const Duration(milliseconds: 100), (Timer timer) async {
      try {
        final ReturnType result =
            await _tryHandleWithinAvailableResources(operationOnResource);
        timer.cancel();
        completer.complete(result);
      } on GetResourceFromPoolFailed {
        if (timeout == Duration.zero) {
          return;
        }

        if (DateTime.now().difference(startWaitTime) > timeout) {
          timer.cancel();
          completer.completeError(const GetResourceFromPoolTimeout(
              'Failed to get resource from pool: The pool has no '
              'resource available and the timeout is reached.'));
        }
      } on CreateResourceFailed catch (e) {
        timer.cancel();
        completer.completeError(e);
      }
    });

    return completer.future;
  }

  @override
  Future<ReturnType> operateOnResourceWithoutTimeout<ReturnType>(
          OperationOnResource<PoolResourceType, ReturnType>
              operationOnResource) async =>
      _tryHandleWithinAvailableResources(operationOnResource);

  /// Throws [GetResourceFromPoolFailed] if the pool has no resource and
  /// space left to create new resource.
  ///
  /// Throws [CreateResourceFailed] if failed to create new resource.
  Future<ReturnType> _tryHandleWithinAvailableResources<ReturnType>(
      OperationOnResource<PoolResourceType, ReturnType>
          operationOnResource) async {
    try {
      return await _tryBorrowFromFreeResourceAndHandle(operationOnResource);
    } on GetResourceFromPoolFailed {
      return _tryCreateAndHandle(operationOnResource);
    }
  }

  Future<ReturnType> _tryCreateAndHandle<ReturnType>(
      OperationOnResource<PoolResourceType, ReturnType>
          operationOnResource) async {
    final _PoolObject<PoolResourceType> poolObject =
        await _resourceManager.createNewResource();

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

  Future<ReturnType> _tryBorrowFromFreeResourceAndHandle<ReturnType>(
      OperationOnResource<PoolResourceType, ReturnType>
          operationOnResource) async {
    final _PoolObject<PoolResourceType> poolObject =
        await _resourceManager.borrowAvailableResource();

    return _handleWithinResourcePool(poolObject, operationOnResource);
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
