class GatePass {
  final int? id;
  final String? passId;
  final String visitorName;
  final String visitorPhone;
  final String validFrom;
  final String validTo;
  final String? purpose;
  final int numberOfPersons;
  final String? qrCodeUrl;
  final bool isActive;

  GatePass({
    this.id,
    this.passId,
    required this.visitorName,
    required this.visitorPhone,
    required this.validFrom,
    required this.validTo,
    this.purpose,
    this.numberOfPersons = 1,
    this.qrCodeUrl,
    this.isActive = true,
  });

  factory GatePass.fromJson(Map<String, dynamic> json) {
    return GatePass(
      id: json['id'],
      passId: json['pass_id'],
      visitorName: json['visitor_name'] ?? '',
      visitorPhone: json['visitor_phone'] ?? '',
      validFrom: json['valid_from'],
      validTo: json['valid_to'],
      purpose: json['purpose'],
      numberOfPersons: json['number_of_persons'] ?? 1,
      qrCodeUrl: json['qr_code'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'visitor_name': visitorName,
      'visitor_phone': visitorPhone,
      'valid_from': validFrom,
      'valid_to': validTo,
      'purpose': purpose,
      'number_of_persons': numberOfPersons,
    };
  }
}
