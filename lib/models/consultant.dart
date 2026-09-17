/// An examining medical practitioner.
///
/// BR-11 says that the specialty of the consultant must match the injury
/// category on the claim. The scheduling screen filters on this field.
class Consultant {
  const Consultant({
    required this.id,
    required this.name,
    required this.specialty,
    required this.facility,
    required this.area,
  });

  final String id;
  final String name;
  final String specialty;
  final String facility;

  /// The part of the city, for example `Bangkok 3`.
  final String area;

  /// The two letters that the avatar shows, for example `AW`.
  String get initials {
    final List<String> parts = name
        .replaceAll('Dr. ', '')
        .split(' ')
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
      other is Consultant &&
          other.id == id &&
          other.name == name &&
          other.specialty == specialty &&
          other.facility == facility &&
          other.area == area;

  @override
  int get hashCode => Object.hash(id, name, specialty, facility, area);
}
