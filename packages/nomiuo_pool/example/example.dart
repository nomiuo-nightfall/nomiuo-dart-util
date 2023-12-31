import 'package:nomiuo_pool/nomiuo_pool.dart';

/// Create your resource here.
class CustomResource extends PoolResource<int> {
  CustomResource(int resource) : super(resource);
}

void main() async {
  // Create an ordered pool.
  // The pool size is 2 and the max size is 10.
  final OrderedPool<int> orderedPool = await OrderedPool.create(
      PoolMeta(minSize: 2, maxSize: 10),
      poolObjectFactory: () => CustomResource(1));

  // Borrow a resource from the pool and multiply it by 10.
  // If there is no resource available, try to create a new one. Throw
  // [CreateResourceFailed] if failed to create a new resource.
  // If the maximum size is reached, then throw an exception
  // [GetResourceFromPoolFailed].
  // ignore: unused_local_variable
  final int multiplied10 = await orderedPool.operateOnResourceWithoutTimeout(
      (PoolResource<int> poolResource) => poolResource.resource * 10);

  // Borrow a resource from the pool and multiply it by 10, but with a timeout.
  // If the timeout is reached, then throw an exception
  // [GetResourceFromPoolTimeout].
  // ignore: unused_local_variable
  final int multiplied10WithTimeout =
      await orderedPool.operateOnResourceWithTimeout(
          (PoolResource<int> poolResource) => poolResource.resource * 10,
          const Duration(seconds: 1));
}
