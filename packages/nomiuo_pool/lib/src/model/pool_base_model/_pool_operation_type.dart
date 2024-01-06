import 'dart:async';

import '_pool_resource.dart';

typedef OperationOnResource<PoolResourceType extends Object, ReturnType>
    = FutureOr<ReturnType> Function(
        PoolResource<PoolResourceType> poolResource);
