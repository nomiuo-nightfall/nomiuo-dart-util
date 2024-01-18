import 'dart:async';
import 'dart:collection';

import 'package:synchronized/synchronized.dart';

import '../../block/block.dart';
import '../../model/exceptions/_inner_exceptions.dart';
import '../../model/exceptions/block_exceptions.dart';
import '../../model/exceptions/pool_exceptions.dart';
import '../../model/pool_base_model/_pool_object.dart';
import '../../model/pool_base_model/pool_meta.dart';
import '../../model/pool_base_model/pool_resource.dart';

part '__ordered_resource_manager.dart';

abstract class ResourceManager<PoolResourceType extends Object> {
  ResourceManager(this._poolMeta,
      {required FutureOr<PoolResource<PoolResourceType>> Function()
          poolObjectFactory})
      : _poolObjectFactory = poolObjectFactory;

  static Future<ResourceManager<PoolResourceType>>
      createOrderedResourceManager<PoolResourceType extends Object>(
          PoolMeta poolMeta,
          {required FutureOr<PoolResource<PoolResourceType>> Function()
              poolObjectFactory}) async {
    final ResourceManager<PoolResourceType> _orderedResourceManager =
        _OrderedResourceManager<PoolResourceType>(poolMeta,
            poolObjectFactory: poolObjectFactory);
    await _orderedResourceManager._initResources();
    return _orderedResourceManager;
  }

  /// Specify the size or other meta info with the pool.
  final PoolMeta _poolMeta;

  /// Create a new resource in the pool.
  final FutureOr<PoolResource<PoolResourceType>> Function() _poolObjectFactory;

  /// Initialize all resources in the pool.
  /// Throw [CreateResourceFailed] if failed to create new resource.
  Future<void> _initResources();

  /// Borrow a free resource from the pool and tag it as used.
  ///
  /// If the pool has no free resource, try to create new resource. If failed
  /// to create new resource, throw [CreateResourceFailed].
  ///
  /// If the pool has no resource available, no space left and timeout is set,
  /// then throw [GetResourceFromPoolTimeout]. Otherwise, it will wait util
  /// the resource is available.
  Future<PoolObject<PoolResourceType>> borrowAvailableResource(
      {Duration? timeout});

  /// Delete the resource from the used list and tag it as free.
  Future<void> freeUsedResource(PoolObject<PoolResourceType> resource);

  /// Add a resource to the free list.
  Future<void> addFreeResource(PoolObject<PoolResourceType> resource);

  /// All resources in the pool.
  Future<int> allPoolResources();
}
