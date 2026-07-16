import 'package:blockchain_utils/helper/helper.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';

typedef DARTTRANSPORTCALLBACK = void Function(NetResponseKind);

enum GrpcErrorCode {
  ok(0),
  cancelled(1),
  unknown(2),
  invalidArgument(3),
  deadlineExceeded(4),
  notFound(5),
  alreadyExists(6),
  permissionDenied(7),
  resourceExhausted(8),
  failedPrecondition(9),
  aborted(10),
  outOfRange(11),
  unimplemented(12),
  internal(13),
  unavailable(14),
  dataLoss(15),
  unauthenticated(16);

  final int code;

  const GrpcErrorCode(this.code);

  static GrpcErrorCode? fromValue(int code) {
    return values.firstWhereNullable((e) => e.code == code);
  }
}
