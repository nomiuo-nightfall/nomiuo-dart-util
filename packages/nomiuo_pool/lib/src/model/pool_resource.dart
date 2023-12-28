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
