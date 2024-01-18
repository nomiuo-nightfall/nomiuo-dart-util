import 'package:nomiuo_pool/nomiuo_pool.dart';
import 'package:nomiuo_pool/nomiuo_pool_model.dart';

/// Create your resource here.
class CustomResource extends PoolResource<int> {
  CustomResource(int resource) : super(resource);
}

void main() async {
  // Create an ordered pool.
  // The pool size is 2 and the max size is 10.
  final OperationPool<int> orderedPool = await OperationPool.createOrderedPool(
      PoolMeta(minSize: 2, maxSize: 10),
      poolObjectFactory: () => CustomResource(1));

  // Borrow a resource from the pool and multiply it by 10.
  // If there is no resource available, try to create a new one. Throw
  // [CreateResourceFailed] if failed to create a new resource.
  // Or wait util the resource is available.
  // ignore: unused_local_variable
  final int multiplied10 = await orderedPool.operateOnResource(
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
