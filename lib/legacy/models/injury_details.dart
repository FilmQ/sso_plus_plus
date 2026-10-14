/// The category of the injury.
///
/// The category selects the specialty of the consultant (BR-11).
enum InjuryCategory {
  fracture('Fracture', 'Orthopaedics'),
  laceration('Laceration', 'General surgery'),
  burn('Burn', 'Plastic surgery'),
  sprain('Sprain or strain', 'Orthopaedics'),
  eyeInjury('Eye injury', 'Ophthalmology'),
  other('Other', 'General medicine');

  const InjuryCategory(this.label, this.specialty);

  final String label;

  /// The consultant specialty that matches this category.
  final String specialty;
}

/// One choice in the "Part of body affected" list.
///
/// The part of the body decides the category, and the category decides the
/// specialty of the consultant (BR-11). The person therefore chooses from a
/// list instead of writing free text.
class BodyPartOption {
  const BodyPartOption(this.label, this.category);

  final String label;
  final InjuryCategory category;
}

/// The parts of the body that the form offers.
const List<BodyPartOption> bodyPartOptions = <BodyPartOption>[
  BodyPartOption('Left forearm', InjuryCategory.fracture),
  BodyPartOption('Right forearm', InjuryCategory.fracture),
  BodyPartOption('Left hand', InjuryCategory.fracture),
  BodyPartOption('Right hand', InjuryCategory.fracture),
  BodyPartOption('Left ankle', InjuryCategory.sprain),
  BodyPartOption('Right ankle', InjuryCategory.sprain),
  BodyPartOption('Lower back', InjuryCategory.sprain),
  BodyPartOption('Left eye', InjuryCategory.eyeInjury),
  BodyPartOption('Right eye', InjuryCategory.eyeInjury),
  BodyPartOption('Hand or arm, burn', InjuryCategory.burn),
  BodyPartOption('Face or neck, cut', InjuryCategory.laceration),
  BodyPartOption('Other', InjuryCategory.other),
];

/// What the worker tells the application about the injury.
///
/// The person enters these fields on screen M2 (UC-01, step 2).
class InjuryDetails {
  const InjuryDetails({
    this.date,
    this.time,
    this.place = '',
    this.cause = '',
    this.bodyPart = '',
    this.employer = '',
    this.category,
  });

  final DateTime? date;
  final String? time;
  final String place;
  final String cause;
  final String bodyPart;
  final String employer;
  final InjuryCategory? category;

  /// The names of the fields that are still empty.
  ///
  /// UC-01 step 2a stops the submission while this list is not empty.
  List<String> get missingFields {
    return <String>[
      if (date == null) 'Date of injury',
      if (time == null || time!.isEmpty) 'Time of injury',
      if (place.isEmpty) 'Place of injury',
      if (cause.isEmpty) 'Cause of injury',
      if (bodyPart.isEmpty) 'Part of body affected',
      if (employer.isEmpty) 'Employer',
    ];
  }

  bool get isComplete => missingFields.isEmpty;

  InjuryDetails copyWith({
    DateTime? date,
    String? time,
    String? place,
    String? cause,
    String? bodyPart,
    String? employer,
    InjuryCategory? category,
  }) {
    return InjuryDetails(
      date: date ?? this.date,
      time: time ?? this.time,
      place: place ?? this.place,
      cause: cause ?? this.cause,
      bodyPart: bodyPart ?? this.bodyPart,
      employer: employer ?? this.employer,
      category: category ?? this.category,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InjuryDetails &&
          other.date == date &&
          other.time == time &&
          other.place == place &&
          other.cause == cause &&
          other.bodyPart == bodyPart &&
          other.employer == employer &&
          other.category == category;

  @override
  int get hashCode =>
      Object.hash(date, time, place, cause, bodyPart, employer, category);
}
