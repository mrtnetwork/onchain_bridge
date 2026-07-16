// import 'package:blockchain_utils/utils/types/result.dart';
// import 'package:on_chain_bridge/exception/exception.dart';
// import 'package:on_chain_bridge/net_sdk/types/config.dart';
// import 'package:on_chain_bridge/net_sdk/types/request.dart';
// import 'package:on_chain_bridge/net_sdk/types/response.dart';
// import 'package:on_chain_bridge/net_sdk/types/status.dart';

// sealed class NetSdkWorkerMessage {
//   final int id;
//   const NetSdkWorkerMessage({required this.id});
//   T cast<T extends NetSdkWorkerMessage>() {
//     if (this is! T) {
//       throw OnChainBridgeException.unexpectedError;
//     }
//     return this as T;
//   }
// }

// sealed class NetSdkWorkerResponse extends NetSdkWorkerMessage {
//   const NetSdkWorkerResponse({required super.id});
// }

// class NetSdkWorkerMessageTransport extends NetSdkWorkerResponse {
//   final Result<int, NetResultStatus> transportId;
//   const NetSdkWorkerMessageTransport({required this.transportId, required super.id});
//   @override
//   String toString() {
//     return "NetResponseStream({id:$id, result:$transportId})";
//   }
// }

// class NetSdkWorkerMessageStream extends NetSdkWorkerResponse {
//   final NetResponseStream messages;
//   final int transportId;
//   const NetSdkWorkerMessageStream(
//       {required this.messages, required super.id, required this.transportId});
//   @override
//   String toString() {
//     return "NetResponseStream({id:$id, result:$messages})";
//   }
// }

// class NetSdkWorkerMessageRequest extends NetSdkWorkerResponse {
//   final Result<NetResponse, NetResultStatus> result;
//   const NetSdkWorkerMessageRequest({required super.id, required this.result});
//   @override
//   String toString() {
//     return "NetSdkWorkerMessageRequest({id:$id, result:$result})";
//   }
// }

// sealed class NetSdkWorkerRequest<T extends Object> extends NetSdkWorkerMessage {
//   final T request;
//   const NetSdkWorkerRequest({required super.id, required this.request});
// }

// class NetSdkWorkerRequestTransport extends NetSdkWorkerRequest<NetConfigRequest> {
//   NetSdkWorkerRequestTransport({required super.id, required super.request});
// }

// class NetSdkWorkerRequestRequest extends NetSdkWorkerRequest<NetRequest> {
//   NetSdkWorkerRequestRequest({required super.id, required super.request});
// }
