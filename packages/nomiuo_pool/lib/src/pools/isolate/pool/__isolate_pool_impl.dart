import 'dart:io';

import '../../../../nomiuo_pool_model.dart';
import '../../../model/exceptions/isolate_exceptions.dart';
import '../../../model/pool_base_model/_pool_object.dart';
import '../../resource/_resource_manager.dart';
import '../executor/isolate_executor.dart';
import 'isolate_pool.dart';

class IsolateExecutorResource extends PoolResource<IsolateExecutor> {
  IsolateExecutorResource(super.resource);
}

class IsolatePoolImpl implements IsolatePool {
  late final ResourceManager<IsolateExecutor> _resourceManager;

  bool isClosed = false;

  Future<void> init() async {
    _resourceManager = await ResourceManager.createOrderedResourceManager(
        PoolMeta(maxSize: -1, minSize: Platform.numberOfProcessors),
        poolObjectFactory: () async =>
            IsolateExecutorResource(await IsolateExecutor.create()));
  }

  @override
  Future<IsolateExecutor> borrow() async {
    if (isClosed) {
      throw IsolateStatusNotValidException('Pool is closed.');
    }
    return (await _resourceManager.borrowAvailableResource()).resource.resource;
  }

  @override
  void returnBack(IsolateExecutor executor) {
    if (isClosed) {
      throw IsolateStatusNotValidException('Pool is closed.');
    }
    if (!executor.isFree) {
      throw IsolateStatusNotValidException('Executor is not free.');
    }
    _resourceManager.addFreeResource(
        PoolObject<IsolateExecutor>(IsolateExecutorResource(executor)));
  }

  @override
  void close() {
    isClosed = true;
    _resourceManager
        .getAllPoolResources()
        .forEach((IsolateExecutor isolateExecutor) {
      isolateExecutor.close();
    });
  }
}
