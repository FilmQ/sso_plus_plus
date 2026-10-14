/// The roles of the login accounts (D-003).
abstract final class Role {
  static const user = 'USER';
  static const officer = 'OFFICER';
  static const consultant = 'CONSULTANT';
}

/// The signed-in person (SA report 2.18: Page.session, Controller.session).
class UserSession {
  const UserSession({
    required this.accountId,
    required this.role,
    required this.displayName,
    required this.firstName,
    this.insuredId,
    this.officerId,
    this.consultantId,
  });

  final int accountId;
  final String role;
  final String displayName;
  final String firstName;
  final int? insuredId;
  final int? officerId;
  final int? consultantId;

  factory UserSession.fromRow(Map<String, Object?> row) => UserSession(
        accountId: row['account_id'] as int,
        role: row['role'] as String,
        displayName: row['display_name'] as String,
        firstName: row['first_name'] as String,
        insuredId: row['insured_id'] as int?,
        officerId: row['officer_id'] as int?,
        consultantId: row['consultant_id'] as int?,
      );

  factory UserSession.fromJson(Map<String, Object?> json) => UserSession(
        accountId: json['account_id'] as int,
        role: json['role'] as String,
        displayName: json['display_name'] as String,
        firstName: json['first_name'] as String,
        insuredId: json['insured_id'] as int?,
        officerId: json['officer_id'] as int?,
        consultantId: json['consultant_id'] as int?,
      );

  Map<String, Object?> toJson() => {
        'account_id': accountId,
        'role': role,
        'display_name': displayName,
        'first_name': firstName,
        'insured_id': insuredId,
        'officer_id': officerId,
        'consultant_id': consultantId,
      };
}
