part of '../pool.dart';

class _OrderedResourceManager<PoolResourceType extends Object>
    extends _ResourceManager<PoolResourceType> {
  _OrderedResourceManager(super.poolMeta, {required super.poolObjectFactory});

  final Queue<_PoolObject<PoolResourceType>> _freeResources =
      ListQueue<_PoolObject<PoolResourceType>>();

  final Set<_PoolObject<PoolResourceType>> _inUseResources =
      <_PoolObject<PoolResourceType>>{};

  final Lock _resourceLock = Lock();

  @override
  Future<_PoolObject<PoolResourceType>> borrowAvailableResource() =>
      _resourceLock.synchronized(() {
        if (_freeResources.isNotEmpty) {
          final _PoolObject<PoolResourceType> poolObject =
              _freeResources.removeFirst();
          _inUseResources.add(poolObject);
          return poolObject;
        }

        throw const GetResourceFromPoolFailed(
            'No resource available in the pool');
      });

  @override
  Future<_PoolObject<PoolResourceType>> createNewResource() =>
      _resourceLock.synchronized(() async {
        if (await allPoolResources() < _poolMeta.maxSize) {
          try {
            final _PoolObject<PoolResourceType> poolObject =
                _PoolObject<PoolResourceType>(await _poolObjectFactory());
            _inUseResources.add(poolObject);
            return poolObject;
          } on Object catch (e) {
            throw CreateResourceFailed('Failed to create new resource: $e');
          }
        }
        throw const GetResourceFromPoolFailed(
            'Failed to get resource from pool: The pool has no resource '
            'available and the left space is too small to create new '
            'resource.');
      });

  @override
  Future<void> addFreeResource(_PoolObject<PoolResourceType> resource) =>
      _resourceLock.synchronized(() {
        _freeResources.add(resource);
      });

  @override
  Future<void> freeUsedResource(_PoolObject<PoolResourceType> resource) =>
      _resourceLock.synchronized(() {
        _inUseResources.remove(resource);
      });

  @override
  Future<int> allPoolResources() =>
      Future<int>.value(_freeResources.length + _inUseResources.length);

  @override
  Future<void> _initResources() async {
    for (int i = 0; i < _poolMeta.minSize; i++) {
      try {
        _freeResources
            .add(_PoolObject<PoolResourceType>(await _poolObjectFactory()));
      } on Object catch (e) {
        throw CreateResourceFailed('Failed to create new resource: $e');
      }
    }
  }
}
