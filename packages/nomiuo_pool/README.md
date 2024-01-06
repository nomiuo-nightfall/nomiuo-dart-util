# :blossom: Manage the resource with pool
![Static Badge](https://img.shields.io/badge/coverage-90%25-green?logo=TestCafe)
[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg?style=flat-square)](https://github.com/invertase/melos)
# :carousel_horse: Usage
Generate a pool of resources, borrow an resource, execute a task with 
the resource, then release the resource to the pool.

Here is a minimal example: 
```dart
import 'package:nomiuo_pool/nomiuo_pool.dart';

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
```

Future more, you could define the resource within the interface. The pool 
calls the `onReset` method after ending the `callback`. If the `callback` 
failed to execute, the pool will call `onRelease` to release the resource.
```dart
import 'dart:async';

abstract class PoolResource<T> {
  PoolResource(this.resource);

  T resource;

  DateTime createTime = DateTime.now();

  /// If operation on resource throws an exception, this method will be called
  /// to release any system resource such io, socket, binding with the
  /// resource. Then discard this resource.
  FutureOr<void> onRelease(Object error, StackTrace stackTrace) {}

  /// Reset the resource state when the resource is returned.
  FutureOr<void> onReset() {}
}
```

# :heart_decoration: Contribute
Hello! Great to see your interest in this package.
The project is base on [melos](https://melos.invertase.dev/). Before 
contribute to the project, run the command below to initialize the project.
```bash
melos bs
```
Feel free to contribute to the project! If you have any questions or suggestions, 
please [file an issue](https://github.com/nomiuo-nightfall/nomiuo-dart-util/issues),
or [open a PR](https://github.com/nomiuo-nightfall/nomiuo-dart-util/pulls)!

The `PR` will be promptly merged upon approval, provided it has undergone a 
thorough review and demonstrates high test coverage. Please not afraid to 
submit your PR!

Also see the `melos.yaml` file in the root of the project, which provides 
some useful commands to test.


