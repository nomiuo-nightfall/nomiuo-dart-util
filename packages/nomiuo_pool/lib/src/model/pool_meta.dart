class PoolMeta {
  PoolMeta({this.maxSize = 5, this.minSize = 1});

  /// If max size of pool is -1, the pool will never be full.
  final int maxSize;

  final int minSize;
}
