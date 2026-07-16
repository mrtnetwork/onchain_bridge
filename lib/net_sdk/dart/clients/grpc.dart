import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/net_sdk/dart/core/clients.dart';
import 'package:on_chain_bridge/net_sdk/dart/grpc/gprc.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';

class GrpcClient implements IClient<PlatformGrpc>, IGrpcClient {
  final NetConfig config;
  PlatformGrpc? _client;
  final _lock = SafeAtomicLock();
  GrpcClient._(this.config);
  factory GrpcClient(NetConfig config) {
    return GrpcClient._(config);
  }

  @override
  Future<Result<PlatformGrpc, NetResultStatus>> connect(
      {Duration? timeout}) async {
    return _lock.run(() async {
      try {
        PlatformGrpc? client = _client;
        if (client != null) return Ok(client);
        final channel = await DartGrpcClient.client(config.address);
        return channel.map((client) {
          _client = client;
          return client;
        });
      } on UnsupportedError catch (_) {
        return Err(NetResultStatus.connectionError);
      }
    });
  }

  @override
  Future<Result<Stream<List<int>>, NetResultStatus>> stream(
      List<int> buffer, String methodName) async {
    final client = await connect();
    return client.andThenAsync((client) async {
      return await client.stream(buffer, methodName);
    });
  }

  @override
  Future<Result<List<int>, Result<AppGrpcError, NetResultStatus>>> unary(
      List<int> buffer, String methodName) async {
    final client = await connect();
    return client
        .mapErr<Result<AppGrpcError, NetResultStatus>>((e) => Err(e))
        .andThenAsync((client) async {
      return await client.unary(buffer, methodName);
    });
  }

  @override
  Future<Result<void, NetResultStatus>> close() async {
    await _lock.run(() async {
      final client = _client;
      _client == null;
      client?.close();
    });
    return Ok(null);
  }
}
