import 'package:intl/intl.dart';

class Traveller {
  String fullName;
  String? gender; // e.g. male/female
  DateTime? dateOfBirth;
  String? passportNo;
  DateTime? passportIssueDate;
  DateTime? passportExpiryDate;
  bool isChild;
  int? familyMemberId;

  Traveller({
    this.fullName = '',
    this.gender,
    this.dateOfBirth,
    this.passportNo,
    this.passportIssueDate,
    this.passportExpiryDate,
    this.isChild = false,
    this.familyMemberId,
  });

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'gender': gender,
        'dob': _format(dateOfBirth),
        'passport_no': passportNo,
        'passport_issue_date': _format(passportIssueDate),
        'passport_expiry_date': _format(passportExpiryDate),
        'type': isChild ? 'child' : 'adult',
        'family_member_id': familyMemberId,
        'familyMemberId': familyMemberId,
      };

  static String? _format(DateTime? dt) =>
      dt == null ? null : DateFormat('yyyy-MM-dd').format(dt);
}
