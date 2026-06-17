class BillingPlan {
  const BillingPlan({
    required this.id,
    required this.name,
    required this.licenseType,
    required this.billingCycle,
    required this.price,
    required this.currency,
  });

  final String id;
  final String name;
  final String licenseType;
  final String billingCycle;
  final num price;
  final String currency;

  factory BillingPlan.fromJson(Map<String, dynamic> json) {
    return BillingPlan(
      id: _stringValue(json['id']),
      name: _stringValue(json['name']),
      licenseType: _stringValue(json['licenseType'] ?? json['license_type']),
      billingCycle: _stringValue(json['billingCycle'] ?? json['billing_cycle']),
      price: _numValue(json['price']),
      currency: _stringValue(json['currency'], fallback: 'EUR'),
    );
  }

  static String _stringValue(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  static num _numValue(Object? value) {
    if (value is num) {
      return value;
    }
    if (value is String) {
      return num.tryParse(value.replaceAll(',', '.')) ?? 0;
    }
    return 0;
  }
}
