part of '../pool.dart';

abstract class _ResourceManager<PoolResourceType extends Object> {
  _ResourceManager(this._poolMeta,
      {required FutureOr<PoolResource<PoolResourceType>> Function()
          poolObjectFactory})
      : _poolObjectFactory = poolObjectFactory;

  static Future<_ResourceManager<PoolResourceType>>
      createOrderedResourceManager<PoolResourceType extends Object>(
          PoolMeta poolMeta,
          {required FutureOr<PoolResource<PoolResourceType>> Function()
              poolObjectFactory}) async {
    final _ResourceManager<PoolResourceType> _orderedResourceManager =
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
  Future<_PoolObject<PoolResourceType>> borrowAvailableResource(
      {Duration? timeout});

  /// Delete the resource from the used list and tag it as free.
  Future<void> freeUsedResource(_PoolObject<PoolResourceType> resource);

  /// Add a resource to the free list.
  Future<void> addFreeResource(_PoolObject<PoolResourceType> resource);

  /// All resources in the pool.
  Future<int> allPoolResources();
}
