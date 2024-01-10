part of '../pool.dart';

class _OrderedResourceManager<PoolResourceType extends Object>
    extends _ResourceManager<PoolResourceType> {
  _OrderedResourceManager(super.poolMeta, {required super.poolObjectFactory});

  final Queue<_PoolObject<PoolResourceType>> _freeResources =
      ListQueue<_PoolObject<PoolResourceType>>();

  final Set<_PoolObject<PoolResourceType>> _inUseResources =
      <_PoolObject<PoolResourceType>>{};

  final Notifier _resourceNotifier = Notifier();

  final Lock _resourceLock = Lock();

  @override
  Future<_PoolObject<PoolResourceType>> borrowAvailableResource(
      {Duration? timeout}) async {
    try {
      return await _tryToBorrow();
    } on _GetResourceFromPoolFailed {
      try {
        return await _tryToCreate();
      } on _GetResourceFromPoolFailed {
        return _waitForResource(timeout);
      }
    }
  }

  @override
  Future<void> addFreeResource(_PoolObject<PoolResourceType> resource) =>
      _resourceLock.synchronized(() {
        _freeResources.add(resource);

        if (_resourceNotifier.hasObservers) {
          _freeResources.remove(resource);
          _inUseResources.add(resource);
          _resourceNotifier.notifyOne(obj: resource);
        }
      });

  @override
  Future<void> freeUsedResource(_PoolObject<PoolResourceType> resource) =>
      _resourceLock.synchronized(() {
        _inUseResources.remove(resource);
      });

  @override
  Future<int> allPoolResources() =>
      Future<int>.value(_freeResources.length + _inUseResources.length);

  Future<_PoolObject<PoolResourceType>> _waitForResource(
      Duration? timeout) async {
    final Completer<_PoolObject<PoolResourceType>> completer =
        Completer<_PoolObject<PoolResourceType>>();
    await _blockUtilTimeoutOrResourceAvailable(timeout, completer);
    return completer.future;
  }

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

  Future<_PoolObject<PoolResourceType>> _tryToBorrow() async =>
      _resourceLock.synchronized(() {
        if (_freeResources.isNotEmpty) {
          final _PoolObject<PoolResourceType> poolObject =
              _freeResources.removeFirst();
          _inUseResources.add(poolObject);
          return poolObject;
        }

        throw const _GetResourceFromPoolFailed('The pool has no free resource '
            'now.');
      });

  Future<void> _blockUtilTimeoutOrResourceAvailable(Duration? timeout,
      Completer<_PoolObject<PoolResourceType>> completer) async {
    final Observer observer = Observer();

    await observer.wait(_resourceNotifier, timeout: timeout,
        callback: (Object? resource) {
      final _PoolObject<PoolResourceType> freePoolObject =
          resource! as _PoolObject<PoolResourceType>;
      completer.complete(freePoolObject);
    }).catchError((Object error) {
      if (error is WaitForNotifierTimeout) {
        completer.completeError(const GetResourceFromPoolTimeout(
            'Failed to get resource from pool: The pool has no resource '
            'now.'));
      }
    });
  }

  Future<_PoolObject<PoolResourceType>> _tryToCreate() =>
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
        throw const _GetResourceFromPoolFailed(
            'Failed to get resource from pool: The pool has no resource '
            'available and the left space is too small to create new '
            'resource.');
      });
}
