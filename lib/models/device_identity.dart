class DeviceIdentity {
  const DeviceIdentity({
    required this.identifierHash,
    required this.kind,
    required this.platform,
  });

  final String identifierHash;
  final String kind;
  final String platform;
}
