import 'dart:async';

import '../../model/exceptions/pool_exceptions.dart';
import '../../model/pool_base_model/_pool_object.dart';
import '../../model/pool_base_model/pool_meta.dart';
import '../../model/pool_base_model/pool_operation_type.dart';
import '../../model/pool_base_model/pool_resource.dart';
import '../resource/resource_manager.dart';

part '__ordered_pool.dart';

abstract interface class OperationPool<PoolResourceType extends Object> {
  /// Create a pool with ordered resources.
  static FutureOr<OperationPool<PoolResourceType>>
      // ignore: avoid_shadowing_type_parameters
      createOrderedPool<PoolResourceType extends Object>(PoolMeta poolMeta,
          {required FutureOr<PoolResource<PoolResourceType>> Function()
              poolObjectFactory}) async {
    final _OperationPoolImpl<PoolResourceType> pool =
        _OperationPoolImpl<PoolResourceType>();

    final ResourceManager<PoolResourceType> resourceManager =
        await ResourceManager.createOrderedResourceManager(
      poolMeta,
      poolObjectFactory: poolObjectFactory,
    );
    pool._resourceManager = resourceManager;

    return pool;
  }

  /// All resources count in the pool.
  Future<int> allPoolResources();

  /// Like the [operateOnResource], but with a timeout. It will
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
  Future<ReturnType> operateOnResource<ReturnType>(
      OperationOnResource<PoolResourceType, ReturnType> operationOnResource);
}
