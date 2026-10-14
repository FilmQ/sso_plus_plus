/// The role of a member of staff in the console.
enum StaffRole {
  evaluationOfficer('Evaluation Officer'),
  consultant('Consultant');

  const StaffRole(this.label);

  final String label;
}

/// The person who uses the console.
///
/// The rail names this person, and their identity goes on every decision
/// they make (BR-06, BR-13, BR-16 and BR-29).
///
/// The rail shows the work of both roles at all times, so this person does
/// not filter the rail. The repository holds the access control (BR-22).
class StaffMember {
  const StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.office,
    this.consultantId,
  });

  final String id;
  final String name;
  final StaffRole role;

  /// The office or the area, for example `Bangkok 3`.
  final String office;

  /// The consultant record of this person, if they are a consultant.
  final String? consultantId;

  /// The two letters that the avatar shows, for example `PC`.
  String get initials {
    final List<String> parts = name
        .replaceAll('Dr. ', '')
        .split(RegExp(r'[ .]'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffMember &&
          other.id == id &&
          other.name == name &&
          other.role == role &&
          other.office == office &&
          other.consultantId == consultantId;

  @override
  int get hashCode => Object.hash(id, name, role, office, consultantId);
}
