class DeviceModel {
  final String name;
  final String os;
  final int battery;
  final String storageLabel; // e.g. "24 GB Free / 128 GB"
  final double storageUsedPercent; // e.g. 0.81 (81%)
  final String ramLabel;

  DeviceModel({
    required this.name,
    required this.os,
    required this.battery,
    required this.storageLabel,
    required this.storageUsedPercent,
    this.ramLabel = "4 GB",
  });
}