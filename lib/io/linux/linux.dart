import 'package:on_chain_bridge/io/io_platforms.dart';
import 'package:on_chain_bridge/io/linux/application_id/path.dart';
import 'package:on_chain_bridge/models/biometric/types.dart';
import 'package:on_chain_bridge/models/device/models/device_info.dart';
import 'package:on_chain_bridge/models/path/path.dart';

class IoLinuxPlatformInterface extends IoPlatformInterface {
  @override
  Future<AppPath> path(String applicationId) {
    return LinuxPathUtils.getPath(applicationId);
  }

  @override
  Future<DeviceInfo> getDeviceInfo() async {
    return DeviceInfo();
  }

  @override
  Future<TouchIdStatus> touchIdStatus() async {
    return TouchIdStatus.notAvailable;
  }
}
