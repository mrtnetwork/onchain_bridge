
import 'dart:io';

Future<Map<String, String>> _getOsRelease() async {
  final osReleasePath = '/etc/os-release';
  final osReleaseFile = File(osReleasePath);
  if (await osReleaseFile.exists()) {
    final content = await osReleaseFile.readAsString();
    final lines = content.split('\n');
    final Map<String, String> osInfo = {};
    for (var line in lines) {
      final parts = line.split('=');
      if (parts.length == 2) {
        osInfo[parts[0].trim()] = parts[1].trim().replaceAll('"', '');
      }
    }
    return osInfo;
  }
  return {};
}

Future<Map<String, String>> _getLsbRelease() async {
  final lsbReleasePath = '/etc/lsb-release';
  final lsbReleaseFile = File(lsbReleasePath);
  if (await lsbReleaseFile.exists()) {
    final content = await lsbReleaseFile.readAsString();
    final lines = content.split('\n');
    final Map<String, String> lsbInfo = {};
    for (var line in lines) {
      final parts = line.split('=');
      if (parts.length == 2) {
        lsbInfo[parts[0].trim()] = parts[1].trim().replaceAll('"', '');
      }
    }
    return lsbInfo;
  }
  return {};
}

Future<String?> _getMachineId() async {
  final machineIdPath = '/etc/machine-id';
  final machineIdFile = File(machineIdPath);
  if (await machineIdFile.exists()) {
    final content = await machineIdFile.readAsString();
    return content.trim();
  }
  return null;
}
