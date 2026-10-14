/// The state of a slot in the calendar of a consultant.
///
/// BR-12 says that a slot may be held against one claim only. BR-19 says
/// that a released slot returns to the pool at once.
enum SlotState { open, held, booked, released }

/// One free period in the calendar of a consultant or a facility.
class AppointmentSlot {
  const AppointmentSlot({
    required this.id,
    required this.consultantId,
    required this.start,
    required this.end,
    this.state = SlotState.open,
    this.heldForClaim,
    this.facility = '',
    this.room = '',
    this.isTreatment = false,
  });

  final String id;
  final String consultantId;
  final DateTime start;
  final DateTime end;
  final SlotState state;

  /// The claim that holds this slot. It is null while the slot is free.
  final String? heldForClaim;

  final String facility;
  final String room;

  /// True for a treatment slot, false for a consultation slot.
  final bool isTreatment;

  bool get isFree => state == SlotState.open || state == SlotState.released;

  AppointmentSlot copyWith({
    SlotState? state,
    String? heldForClaim,
    String? facility,
    String? room,
  }) {
    return AppointmentSlot(
      id: id,
      consultantId: consultantId,
      start: start,
      end: end,
      state: state ?? this.state,
      heldForClaim: heldForClaim ?? this.heldForClaim,
      facility: facility ?? this.facility,
      room: room ?? this.room,
      isTreatment: isTreatment,
    );
  }

  /// Returns the slot to the pool (BR-19).
  AppointmentSlot released() => AppointmentSlot(
    id: id,
    consultantId: consultantId,
    start: start,
    end: end,
    state: SlotState.released,
    facility: facility,
    room: room,
    isTreatment: isTreatment,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentSlot &&
          other.id == id &&
          other.consultantId == consultantId &&
          other.start == start &&
          other.end == end &&
          other.state == state &&
          other.heldForClaim == heldForClaim &&
          other.facility == facility &&
          other.room == room &&
          other.isTreatment == isTreatment;

  @override
  int get hashCode => Object.hash(
    id,
    consultantId,
    start,
    end,
    state,
    heldForClaim,
    facility,
    room,
    isTreatment,
  );
}
