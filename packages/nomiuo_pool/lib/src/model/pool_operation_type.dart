import 'dart:async';

import 'pool_resource.dart';

typedef OperationOnResource<PoolResourceType extends Object, ReturnType>
    = FutureOr<ReturnType> Function(
        PoolResource<PoolResourceType> poolResource);
