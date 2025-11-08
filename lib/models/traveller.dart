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
  bool useAccountDetails;

  Traveller({
    this.fullName = '',
    this.gender,
    this.dateOfBirth,
    this.passportNo,
    this.passportIssueDate,
    this.passportExpiryDate,
    this.isChild = false,
    this.familyMemberId,
    this.useAccountDetails = false,
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

  Traveller copyWith({
    String? fullName,
    String? gender,
    DateTime? dateOfBirth,
    String? passportNo,
    DateTime? passportIssueDate,
    DateTime? passportExpiryDate,
    bool? isChild,
    int? familyMemberId,
    bool? useAccountDetails,
  }) {
    return Traveller(
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      passportNo: passportNo ?? this.passportNo,
      passportIssueDate: passportIssueDate ?? this.passportIssueDate,
      passportExpiryDate: passportExpiryDate ?? this.passportExpiryDate,
      isChild: isChild ?? this.isChild,
      familyMemberId: familyMemberId ?? this.familyMemberId,
      useAccountDetails: useAccountDetails ?? this.useAccountDetails,
    );
  }

  static String? _format(DateTime? dt) =>
      dt == null ? null : DateFormat('yyyy-MM-dd').format(dt);
}
