part of '_resource_manager.dart';

class _OrderedResourceManager<PoolResourceType extends Object>
    extends ResourceManager<PoolResourceType> {
  _OrderedResourceManager(super.poolMeta, {required super.poolObjectFactory});

  final Queue<PoolObject<PoolResourceType>> _freeResources =
      ListQueue<PoolObject<PoolResourceType>>();

  final Set<PoolObject<PoolResourceType>> _inUseResources =
      <PoolObject<PoolResourceType>>{};

  final Notifier _resourceNotifier = Notifier();

  final Lock _resourceLock = Lock();

  @override
  Future<PoolObject<PoolResourceType>> borrowAvailableResource(
      {Duration? timeout}) async {
    try {
      return await _tryToBorrow();
    } on GetResourceFromPoolFailed {
      try {
        return await _tryToCreate();
      } on GetResourceFromPoolFailed {
        return _waitForResource(timeout);
      }
    }
  }

  @override
  Future<void> addFreeResource(PoolObject<PoolResourceType> resource) =>
      _resourceLock.synchronized(() {
        _freeResources.add(resource);

        if (_resourceNotifier.hasObservers) {
          _freeResources.remove(resource);
          _inUseResources.add(resource);
          _resourceNotifier.notifyOne(obj: resource);
        }
      });

  @override
  Future<void> freeUsedResource(PoolObject<PoolResourceType> resource) =>
      _resourceLock.synchronized(() {
        _inUseResources.remove(resource);
      });

  @override
  Future<int> allPoolResources() =>
      Future<int>.value(_freeResources.length + _inUseResources.length);

  Future<PoolObject<PoolResourceType>> _waitForResource(
      Duration? timeout) async {
    final Completer<PoolObject<PoolResourceType>> completer =
        Completer<PoolObject<PoolResourceType>>();
    await _blockUtilTimeoutOrResourceAvailable(timeout, completer);
    return completer.future;
  }

  @override
  Future<void> _initResources() async {
    for (int i = 0; i < _poolMeta.minSize; i++) {
      try {
        _freeResources
            .add(PoolObject<PoolResourceType>(await _poolObjectFactory()));
      } on Object catch (e) {
        throw CreateResourceFailed('Failed to create new resource: $e');
      }
    }
  }

  Future<PoolObject<PoolResourceType>> _tryToBorrow() async =>
      _resourceLock.synchronized(() {
        if (_freeResources.isNotEmpty) {
          final PoolObject<PoolResourceType> poolObject =
              _freeResources.removeFirst();
          _inUseResources.add(poolObject);
          return poolObject;
        }

        throw const GetResourceFromPoolFailed('The pool has no free resource '
            'now.');
      });

  Future<void> _blockUtilTimeoutOrResourceAvailable(Duration? timeout,
      Completer<PoolObject<PoolResourceType>> completer) async {
    final Observer observer = Observer();

    await observer.wait(_resourceNotifier, timeout: timeout,
        callback: (Object? resource) {
      final PoolObject<PoolResourceType> freePoolObject =
          resource! as PoolObject<PoolResourceType>;
      completer.complete(freePoolObject);
    }).catchError((Object error) {
      if (error is WaitForNotifierTimeout) {
        completer.completeError(const GetResourceFromPoolTimeout(
            'Failed to get resource from pool: The pool has no resource '
            'now.'));
      }
    });
  }

  Future<PoolObject<PoolResourceType>> _tryToCreate() =>
      _resourceLock.synchronized(() async {
        if (await allPoolResources() < _poolMeta.maxSize) {
          try {
            final PoolObject<PoolResourceType> poolObject =
                PoolObject<PoolResourceType>(await _poolObjectFactory());
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
  Iterable<PoolResourceType> getAllPoolResources() {
    final List<PoolResourceType> allPoolResources = <PoolResourceType>[];
    for (final PoolObject<PoolResourceType> poolObject in _freeResources) {
      allPoolResources.add(poolObject.resource.resource);
    }
    for (final PoolObject<PoolResourceType> poolObject in _inUseResources) {
      allPoolResources.add(poolObject.resource.resource);
    }
    return allPoolResources;
  }
}
