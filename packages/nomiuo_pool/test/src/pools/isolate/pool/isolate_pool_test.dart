import 'package:nomiuo_pool/src/model/exceptions/isolate_exceptions.dart';
import 'package:nomiuo_pool/src/pools/isolate/executor/isolate_executor.dart';
import 'package:nomiuo_pool/src/pools/isolate/messages/cancellable_controller.dart';
import 'package:nomiuo_pool/src/pools/isolate/pool/isolate_pool.dart';
import 'package:test/test.dart';

void main() async {
  late IsolatePool isolatePool;

  setUp(() async => isolatePool = await IsolatePool.create());

  tearDown(() => isolatePool.close());

  test('Borrow and return.', () async {
    final IsolateExecutor executor = await isolatePool.borrow();
    final CancellableController<int> execute = executor.execute(() => 1);
    await execute.future;
    isolatePool.returnBack(executor);
  });

  test('Close.', () async {
    final IsolateExecutor executor = await isolatePool.borrow();
    executor.close();
    expect(() => isolatePool.returnBack(executor),
        throwsA(isA<IsolateStatusNotValidException>()));
  });

  test('Close pool.', () async {
    final IsolateExecutor isolateExecutor = await isolatePool.borrow();
    isolatePool.close();
    expect(() => isolatePool.borrow(),
        throwsA(isA<IsolateStatusNotValidException>()));
    expect(() => isolatePool.returnBack(isolateExecutor),
        throwsA(isA<IsolateStatusNotValidException>()));
  });
}
