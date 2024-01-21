import '../../../model/exceptions/isolate_exceptions.dart';
import '../executor/isolate_executor.dart';
import '__isolate_pool_impl.dart';

/// Manage a pool of [IsolateExecutor].
abstract class IsolatePool {
  static Future<IsolatePool> create() async {
    final IsolatePoolImpl isolatePoolImpl = IsolatePoolImpl();
    await isolatePoolImpl.init();
    return isolatePoolImpl;
  }

  /// Borrow an [IsolateExecutor] from pool.
  ///
  /// If the pool is closed, then throw [IsolateStatusNotValidException].
  Future<IsolateExecutor> borrow();

  /// Return an [IsolateExecutor] back to pool.
  ///
  /// If the pool is closed, then throw [IsolateStatusNotValidException].
  void returnBack(IsolateExecutor executor);

  /// Close the pool.
  void close();
}
