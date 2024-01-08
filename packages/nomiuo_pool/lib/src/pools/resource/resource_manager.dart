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

  /// Create a new resource in the pool and tag it as used. If failed to
  /// create a new resource, throw [CreateResourceFailed]. If the pool is full,
  /// throw [GetResourceFromPoolFailed].
  Future<_PoolObject<PoolResourceType>> createNewResource();

  /// Borrow a free resource from the pool and tag it as used. If the pool has
  /// no resource available, then throw [GetResourceFromPoolFailed].
  Future<_PoolObject<PoolResourceType>> borrowAvailableResource();

  /// Delete the resource from the used list and tag it as free.
  Future<void> freeUsedResource(_PoolObject<PoolResourceType> resource);

  /// Add a resource to the free list.
  Future<void> addFreeResource(_PoolObject<PoolResourceType> resource);

  /// All resources in the pool.
  Future<int> allPoolResources();
}
