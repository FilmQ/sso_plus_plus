import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/claim_document.dart';
import '../models/injury_details.dart';
import '../use-cases/uc_01_submit_injury_application.dart';
import 'appointment_providers.dart';
import 'claim_providers.dart';
import 'notice_providers.dart';
import 'person_provider.dart';
import 'use_case_providers.dart';

/// What the person has entered for a new claim so far.
///
/// Screens M2 and M3 are two steps of one claim, so they share this state.
class NewClaimState {
  const NewClaimState({
    required this.injury,
    required this.documents,
    this.busy = false,
  });

  /// An empty form with the three documents that BR-03 demands.
  factory NewClaimState.initial(String employer) => NewClaimState(
    injury: InjuryDetails(employer: employer),
    documents: const <ClaimDocument>[
      ClaimDocument(type: DocumentType.medicalCertificate),
      ClaimDocument(type: DocumentType.employerStatement),
      ClaimDocument(type: DocumentType.identification),
    ],
  );

  final InjuryDetails injury;
  final List<ClaimDocument> documents;

  /// True while the application sends the claim.
  final bool busy;

  bool get hasAllDocuments =>
      documents.every((ClaimDocument d) => d.isAttached);

  NewClaimState copyWith({
    InjuryDetails? injury,
    List<ClaimDocument>? documents,
    bool? busy,
  }) {
    return NewClaimState(
      injury: injury ?? this.injury,
      documents: documents ?? this.documents,
      busy: busy ?? this.busy,
    );
  }
}

/// Holds the draft of a new claim and sends it.
///
/// The notifier holds no rule of its own. It calls UC-01 and then makes the
/// read models stale.
class NewClaimNotifier extends Notifier<NewClaimState> {
  @override
  NewClaimState build() {
    return NewClaimState.initial(ref.watch(currentPersonProvider).employer);
  }

  void setInjury(InjuryDetails injury) {
    state = state.copyWith(injury: injury);
  }

  /// Attaches a file to one line of the checklist.
  void attach(DocumentType type, String fileName) {
    state = state.copyWith(
      documents: <ClaimDocument>[
        for (final ClaimDocument document in state.documents)
          if (document.type == type)
            document.copyWith(fileName: fileName)
          else
            document,
      ],
    );
  }

  /// Removes the file from one line of the checklist.
  void detach(DocumentType type) {
    state = state.copyWith(
      documents: <ClaimDocument>[
        for (final ClaimDocument document in state.documents)
          if (document.type == type) document.detached() else document,
      ],
    );
  }

  /// Runs UC-01.
  Future<SubmitResult> submit() async {
    state = state.copyWith(busy: true);
    try {
      final SubmitResult result = await ref
          .read(submitInjuryApplicationProvider)
          .call(
            person: ref.read(currentPersonProvider),
            injury: state.injury,
            documents: state.documents,
          );
      _refreshReadModels();
      return result;
    } finally {
      if (ref.mounted) {
        state = state.copyWith(busy: false);
      }
    }
  }

  /// Empties the form for the next claim.
  void reset() {
    state = NewClaimState.initial(ref.read(currentPersonProvider).employer);
  }

  void _refreshReadModels() {
    ref.invalidate(claimsProvider);
    ref.invalidate(noticesProvider);
    ref.invalidate(unreadNoticeCountProvider);
    ref.invalidate(appointmentsProvider);
    ref.invalidate(appointmentAwaitingReplyProvider);
  }
}

final NotifierProvider<NewClaimNotifier, NewClaimState> newClaimProvider =
    NotifierProvider<NewClaimNotifier, NewClaimState>(NewClaimNotifier.new);
