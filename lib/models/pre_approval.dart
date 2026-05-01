class PreApproval {
  final int? id;
  final String visitorName;
  final String mobile;
  final String visitorType;
  final String? purpose;
  final int numberOfPersons;
  final String validFrom;
  final String validTo;
  final String status;
  final String? requestedByName;
  final String? passId;

  PreApproval({
    this.id,
    required this.visitorName,
    required this.mobile,
    this.visitorType = 'guest',
    this.purpose,
    this.numberOfPersons = 1,
    required this.validFrom,
    required this.validTo,
    this.status = 'pending',
    this.requestedByName,
    this.passId,
  });

  factory PreApproval.fromJson(Map<String, dynamic> json) {
    return PreApproval(
      id: json['id'],
      visitorName: json['visitor_name'],
      mobile: json['mobile'],
      visitorType: json['visitor_type'] ?? 'guest',
      purpose: json['purpose'],
      numberOfPersons: json['number_of_persons'] ?? 1,
      validFrom: json['valid_from'],
      validTo: json['valid_to'],
      status: json['status'] ?? 'pending',
      requestedByName: json['requested_by_name'],
      passId: json['pass_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'visitor_name': visitorName,
      'mobile': mobile,
      'visitor_type': visitorType,
      'purpose': purpose,
      'number_of_persons': numberOfPersons,
      'valid_from': validFrom,
      'valid_to': validTo,
    };
  }
}
