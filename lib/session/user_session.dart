/// The signed-in person, as the server sends it (server: UserSession).
class UserSession {
  const UserSession({
    required this.role,
    required this.displayName,
    required this.firstName,
    this.insuredId,
    this.officerId,
    this.consultantId,
  });

  final String role;
  final String displayName;
  final String firstName;
  final int? insuredId;
  final int? officerId;
  final int? consultantId;

  bool get isUser => role == 'USER';
  bool get isOfficer => role == 'OFFICER';
  bool get isConsultant => role == 'CONSULTANT';

  factory UserSession.fromJson(Map<String, Object?> json) => UserSession(
        role: json['role'] as String,
        displayName: json['display_name'] as String,
        firstName: json['first_name'] as String,
        insuredId: json['insured_id'] as int?,
        officerId: json['officer_id'] as int?,
        consultantId: json['consultant_id'] as int?,
      );
}
