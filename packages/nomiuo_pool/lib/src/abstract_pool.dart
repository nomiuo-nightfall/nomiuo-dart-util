import 'dart:async';
import 'dart:collection';

import 'package:synchronized/synchronized.dart';

import 'model/exceptions.dart';
import 'model/pool_meta.dart';
import 'model/pool_object.dart';
import 'model/pool_operation_type.dart';
import 'model/pool_resource.dart';

part 'pools/ordered_pool.dart';

abstract interface class AbstractPool<PoolResourceType extends Object> {
  AbstractPool(this._poolMeta,
      {required FutureOr<PoolResource<PoolResourceType>> Function()
          poolObjectFactory})
      : _poolObjectFactory = poolObjectFactory;

  /// Specify the size or other meta info with the pool.
  final PoolMeta _poolMeta;

  /// Create a new resource in the pool.
  final FutureOr<PoolResource<PoolResourceType>> Function() _poolObjectFactory;

  /// Try to borrow a resource from the pool. If the pool has no resource
  /// available, try to create a new one. If the pool is full, then throw an
  /// exception [GetResourceFromPoolFailed].
  ///
  /// Throw [CreateResourceFailed] if failed to create a new resource.
  ///
  /// Notice that it will not catch any exception thrown by the
  /// [PoolResource.onRelease] or [PoolResource.onReset] method, simply rethrow.
  Future<void> operateOnResourceWithoutTimeout(
      OperationOnResource<PoolResourceType> operationOnResource);

  /// Like the [operateOnResourceWithoutTimeout], but with a timeout. It will
  /// wait until the resource is borrowed or the timeout is reached.
  ///
  /// Throw [CreateResourceFailed] if failed to create a new resource.
  ///
  /// If the timeout is reached, then throw an exception
  /// [GetResourceFromPoolTimeout].
  Future<void> operateOnResourceWithTimeout(
      OperationOnResource<PoolResourceType> operationOnResource,
      Duration timeout);

  /// Get the number of all resources in the pool, including free and in use.
  FutureOr<int> allPoolResources();
}
