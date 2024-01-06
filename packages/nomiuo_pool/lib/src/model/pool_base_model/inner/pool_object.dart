part of '../../../pools/pool.dart';

class _PoolObject<PoolResourceType> {
  _PoolObject(this.resource);

  final PoolResource<PoolResourceType> resource;
}
