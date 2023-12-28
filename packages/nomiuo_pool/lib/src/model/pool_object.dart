import 'pool_resource.dart';

class PoolObject<PoolResourceType> {
  PoolObject(this.resource);

  final PoolResource<PoolResourceType> resource;

  final DateTime createTime = DateTime.now();
}
