import 'dart:js_interop';

import 'package:on_chain_bridge/net_sdk/net_sdk.dart';

extension NETSDKSTATUSJS on NetResultStatus {
  JSNumber get toJS => value.toJS;
}
