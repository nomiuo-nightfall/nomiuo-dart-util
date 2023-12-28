import 'dart:async';

import 'pool_resource.dart';

typedef OperationOnResource<PoolResourceType extends Object> = FutureOr<void>
    Function(PoolResource<PoolResourceType> poolResource);
