/// A document that the claim checklist demands (BR-03).
enum DocumentType {
  medicalCertificate('Medical certificate'),
  employerStatement('Employer accident statement'),
  identification('National ID card');

  const DocumentType(this.label);

  final String label;
}

/// One line of the required-document checklist on screen M3.
class ClaimDocument {
  const ClaimDocument({required this.type, this.fileName});

  final DocumentType type;

  /// The name of the attached file. It is null while nothing is attached.
  final String? fileName;

  bool get isAttached => fileName != null && fileName!.isNotEmpty;

  /// The second line of the checklist row.
  String get statusText => isAttached ? fileName! : 'Not attached · required';

  ClaimDocument copyWith({DocumentType? type, String? fileName}) {
    return ClaimDocument(
      type: type ?? this.type,
      fileName: fileName ?? this.fileName,
    );
  }

  /// Removes the attached file from this row.
  ClaimDocument detached() => ClaimDocument(type: type);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClaimDocument &&
          other.type == type &&
          other.fileName == fileName;

  @override
  int get hashCode => Object.hash(type, fileName);
}
