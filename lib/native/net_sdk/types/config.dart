import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';

class NetCreateInstanceConfig with AppSerialization {
  final bool logging;
  final int? instanceId;
  final NetConfigTor? torConifg;
  final LoggerMode mode;
  final bool freshStart;
  const NetCreateInstanceConfig(
      {required this.logging,
      this.instanceId,
      this.torConifg,
      this.mode = LoggerMode.debug,
      this.freshStart = false});

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netCreateInstanceConfig;

  @override
  List<CborObject?> get serializationItems => [
        logging.toCbor(),
        instanceId?.toCbor(),
        torConifg?.toCbor(),
        mode.value.toCbor(),
        freshStart.toCbor()
      ];
}
