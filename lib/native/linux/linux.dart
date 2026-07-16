import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/native/io_platforms.dart';
import 'package:on_chain_bridge/native/linux/application_id/path.dart';
import 'package:on_chain_bridge/models/biometric/types.dart';
import 'package:on_chain_bridge/models/device/models/device_info.dart';
import 'package:on_chain_bridge/models/path/path.dart';

class IoLinuxPlatformInterface extends IoPlatformInterface {
  @override
  Future<Result<AppPath, IException>> path(String applicationId) async {
    return await LinuxPathUtils.getPath(applicationId);
  }

  @override
  Future<Result<DeviceInfo, IException>> getDeviceInfo() async {
    return Ok(DeviceInfo());
  }

  @override
  Future<Result<TouchIdStatus, IException>> touchIdStatus() async {
    return Ok(TouchIdStatus.notAvailable);
  }
}
