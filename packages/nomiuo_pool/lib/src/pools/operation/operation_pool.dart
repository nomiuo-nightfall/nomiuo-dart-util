import 'dart:async';
import 'dart:collection';

import 'package:synchronized/synchronized.dart';

import '../../model/exceptions.dart';
import '../../model/pool_meta.dart';
import '../../model/pool_operation_type.dart';
import '../../model/pool_resource.dart';

part '../../model/pool_object.dart';
part 'manager/ordered_resource_manager.dart';
part 'manager/resource_manager.dart';

class OperationPool<PoolResourceType extends Object> {
  OperationPool._();

  /// Create a pool with ordered resources.
  static FutureOr<OperationPool<PoolResourceType>>
      // ignore: avoid_shadowing_type_parameters
      createOrderedPool<PoolResourceType extends Object>(PoolMeta poolMeta,
          {required FutureOr<PoolResource<PoolResourceType>> Function()
              poolObjectFactory}) async {
    final OperationPool<PoolResourceType> pool =
        OperationPool<PoolResourceType>._();

    final _ResourceManager<PoolResourceType> resourceManager =
        await _ResourceManager.createOrderedResourceManager(
      poolMeta,
      poolObjectFactory: poolObjectFactory,
    );
    pool._resourceManager = resourceManager;

    return pool;
  }

  late final _ResourceManager<PoolResourceType> _resourceManager;

  Future<int> allPoolResources() => _resourceManager.allPoolResources();

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
