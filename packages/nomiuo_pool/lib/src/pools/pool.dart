import 'dart:async';
import 'dart:collection';

import 'package:synchronized/synchronized.dart';

import '../block/block.dart';
import '../model/exceptions/block_exceptions.dart';
import '../model/exceptions/pool_exceptions.dart';
import '../model/pool_base_model/pool_base_model.dart';

part '../model/pool_base_model/inner/pool_object.dart';
part 'operation/operation_pool.dart';
part 'operation/ordered_pool.dart';
part 'resource/ordered_resource_manager.dart';
part 'resource/resource_manager.dart';

class _GetResourceFromPoolFailed implements Exception {
  const _GetResourceFromPoolFailed(this.message);
  final String message;
}
