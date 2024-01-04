part of '../pools/operation/operation_pool.dart';

class _PoolObject<PoolResourceType> {
  _PoolObject(this.resource);

  final PoolResource<PoolResourceType> resource;

  final DateTime createTime = DateTime.now();
}
