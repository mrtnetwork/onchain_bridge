import 'package:blockchain_utils/cbor/serialization/cbor/tag.dart';

enum OnChainBrdigeSerializationIdentifier implements SerializationIdentifier {
  tableStructARead(id: 12001),
  tableStructAData(id: 12002),
  tableStructAStorageColumn(id: 12003),
  tableStructAStorageData(id: 12004),

  storageActionWrite(id: 12005),
  storageActionRemove(id: 12006),
  storageActionRead(id: 12007),
  storageActionReadAll(id: 12008),
  storageActionEvent(id: 12009),
  storageActionCleanNullableObject(id: 12010),
  bridgePluginError(id: 12011),
  databaseError(id: 12012),
  barcodeError(id: 12013),
  digestAuthError(id: 12014),
  netSdkError(id: 12015),
  serializationError(id: 12016),
  binarySerialization(id: 12017),
  stringSerialization(id: 12018),
  booleanSerialization(id: 12019),
  bigintSerialization(id: 12019),
  tableActionDrop(id: 12020),
  tableActionReadAll(id: 12021),

  netSdkNetDigestAuthenticated(id: 12022),
  netSdkNetHttpHeader(id: 12023),
  netSdkNetConfigTor(id: 12024),
  netSdkNetConfigHttp(id: 12025),
  netSdkNetConfigRawSocket(id: 12026),
  netSdkNetConfigRequest(id: 12027),

  netRequestGrpcUnary(id: 12028),
  netRequestGrpcStream(id: 12029),
  netRequestGrpcUnsubscribe(id: 12030),
  netHttpRetryConfig(id: 12031),
  netRequestHttp(id: 12032),
  netRequestSocketSend(id: 12033),
  netRequestSocket(id: 12034),
  netRequestInitTor(id: 12035),
  netRequestTorInited(id: 12036),
  netRequestCloseTransport(id: 12037),
  netResponseSocketStatus(id: 12038),
  netRequestGrpc(id: 12039),
  netRequestKind(id: 12040),
  netRequest(id: 12041),
  netResponseStreamData(id: 12042),
  netResponseStreamClose(id: 12043),
  netResponseStreamError(id: 12044),
  netResponseHttp(id: 12045),
  netResponseGrpcSubscribe(id: 12046),
  netResponseGrpcUnsubscribe(id: 12047),
  netResponseGrpcUnary(id: 12048),
  netResponseError(id: 12049),
  netResponseClosed(id: 12050),
  netResponseTorInited(id: 12051),
  netResponse(id: 12052),
  netRequestSocketSubscribe(id: 12053),
  netRequestSocketUnsubscribe(id: 12054),
  netResponseKind(id: 12055),
  netCreateInstanceConfig(id: 12056),
  netWorkerRequest(id: 12057),
  logMessage(id: 12058),

  tableStructAColumn(id: 12059),

  loggingConfig(id: 12060),
  widgetReact(id: 12061);

  @override
  final int id;
  const OnChainBrdigeSerializationIdentifier({
    required this.id,
  });

  @override
  bool isValid(int? tag) {
    return tag == id;
  }
}
