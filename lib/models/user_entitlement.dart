class UserEntitlement {
  const UserEntitlement({
    required this.productId,
    required this.productType,
    required this.active,
    this.expiresAt,
  });

  final String productId;
  final String productType;
  final bool active;
  final DateTime? expiresAt;

  factory UserEntitlement.fromMap(Map<String, dynamic> map) {
    final expiresAtText = map['expires_at'] as String?;

    return UserEntitlement(
      active: (map['active'] as bool?) ?? false,
      expiresAt:
          expiresAtText == null ? null : DateTime.tryParse(expiresAtText),
      productId: map['product_id'] as String,
      productType: map['product_type'] as String,
    );
  }
}
