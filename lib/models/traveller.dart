class Traveller {
  String fullName;
  String? passportNo;
  String? dob; // YYYY-MM-DD

  Traveller({required this.fullName, this.passportNo, this.dob});

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'passport_no': passportNo,
        'dob': dob,
      };
}
