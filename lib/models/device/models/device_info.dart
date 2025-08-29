class DeviceInfo {
  DeviceInfo.fromJson(Map<String, dynamic> json)
      : brand = json["brand"],
        device = json["device"],
        display = json["display"],
        id = json["id"],
        model = json["model"],
        product = json["product"],
        appVersion = json["app_version"],
        androidSdkVersion = json["sdk_version"];
  final String? brand;
  final String? device;
  final String? display;
  final String? id;
  final String? model;
  final String? product;
  final String? appVersion;
  final int? androidSdkVersion;
  const DeviceInfo(
      {this.brand,
      this.device,
      this.display,
      this.id,
      this.model,
      this.product,
      this.appVersion,
      this.androidSdkVersion});

  Map<String, dynamic> toJson() {
    return {
      "brand": brand,
      "device": device,
      "display": display,
      "id": id,
      "model": model,
      "product": product,
      "app_version": appVersion,
      "sdk_version": androidSdkVersion
    };
  }

  @override
  String toString() {
    return "DeviceInfo{${toJson()}}";
  }
}
