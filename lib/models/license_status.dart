class LicenseStatus {
  const LicenseStatus({
    required this.plan,
    required this.companyName,
    required this.email,
    required this.licenseType,
    required this.billingCycle,
    required this.price,
    required this.endDate,
    required this.maxDevices,
    required this.activatedDevices,
    required this.monthlySimpleDocumentsLimit,
    required this.monthlyRiskAnalysisLimit,
    required this.usedSimpleDocumentsThisMonth,
    required this.usedRiskAnalysisThisMonth,
    required this.allowedFeatures,
    required this.isActive,
  });

  final String plan;
  final String companyName;
  final String email;
  final String licenseType;
  final String billingCycle;
  final int? price;
  final DateTime? endDate;
  final int? maxDevices;
  final int? activatedDevices;
  final int? monthlySimpleDocumentsLimit;
  final int? monthlyRiskAnalysisLimit;
  final int usedSimpleDocumentsThisMonth;
  final int usedRiskAnalysisThisMonth;
  final List<String> allowedFeatures;
  final bool isActive;

  bool get isExpired {
    final value = endDate;
    if (value == null) {
      return false;
    }
    return value.isBefore(DateTime.now());
  }

  factory LicenseStatus.inactive() {
    return const LicenseStatus(
      plan: '',
      companyName: '',
      email: '',
      licenseType: '',
      billingCycle: '',
      price: null,
      endDate: null,
      maxDevices: null,
      activatedDevices: null,
      monthlySimpleDocumentsLimit: null,
      monthlyRiskAnalysisLimit: null,
      usedSimpleDocumentsThisMonth: 0,
      usedRiskAnalysisThisMonth: 0,
      allowedFeatures: [],
      isActive: false,
    );
  }

  factory LicenseStatus.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['license'] ?? json['status'] ?? json;
    final source = rawStatus is Map<String, dynamic> ? rawStatus : json;
    return LicenseStatus(
      plan: _stringValue(source['plan']),
      companyName: _stringValue(source['companyName'] ?? source['company']),
      email: _stringValue(
        json['email'] ?? source['email'] ?? source['userEmail'],
      ),
      licenseType: _stringValue(
        source['licenseType'] ?? source['type'] ?? source['seatType'],
      ),
      billingCycle: _stringValue(
        source['billingCycle'] ?? source['cycle'] ?? source['interval'],
      ),
      price: _intValue(source['price'] ?? source['monthlyPrice']),
      endDate: _dateValue(
        source['endDate'] ?? source['expiresAt'] ?? source['expirationDate'],
      ),
      maxDevices: _intValue(source['maxDevices'] ?? source['deviceLimit']),
      activatedDevices: _intValue(
        source['activatedDevices'] ??
            source['usedDevices'] ??
            source['devicesUsed'],
      ),
      monthlySimpleDocumentsLimit: _intValue(
        source['monthlySimpleDocumentsLimit'] ?? source['simpleDocumentsLimit'],
      ),
      monthlyRiskAnalysisLimit: _intValue(
        source['monthlyRiskAnalysisLimit'] ?? source['riskAnalysisLimit'],
      ),
      usedSimpleDocumentsThisMonth:
          _intValue(
            source['usedSimpleDocumentsThisMonth'] ??
                source['usedSimpleDocuments'],
          ) ??
          0,
      usedRiskAnalysisThisMonth:
          _intValue(
            source['usedRiskAnalysisThisMonth'] ?? source['usedRiskAnalyses'],
          ) ??
          0,
      allowedFeatures: _stringList(source['allowedFeatures']),
      isActive: _boolValue(source['isActive'] ?? source['active']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan': plan,
      'companyName': companyName,
      'email': email,
      'licenseType': licenseType,
      'billingCycle': billingCycle,
      'price': price,
      'endDate': endDate?.toIso8601String(),
      'maxDevices': maxDevices,
      'activatedDevices': activatedDevices,
      'monthlySimpleDocumentsLimit': monthlySimpleDocumentsLimit,
      'monthlyRiskAnalysisLimit': monthlyRiskAnalysisLimit,
      'usedSimpleDocumentsThisMonth': usedSimpleDocumentsThisMonth,
      'usedRiskAnalysisThisMonth': usedRiskAnalysisThisMonth,
      'allowedFeatures': allowedFeatures,
      'isActive': isActive,
    };
  }

  static String _stringValue(Object? value) {
    if (value is String) {
      return value.trim();
    }
    return '';
  }

  static int? _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static bool _boolValue(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  static DateTime? _dateValue(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value.trim());
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
