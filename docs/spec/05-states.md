# State machines (from the state diagrams in SA report section 2.19)

Status columns: `InjuryClaim.claim_status`, `Appointment.appointment_status`, `Treatment.treatment_status`. ConsultationReport has no status column: its state is read from `signed_at`, `delivered_at` and `read_at`.

## InjuryClaim

States: `Awaiting verification`, `Register unavailable`, `Covered`, `Not covered`, `Rejected`, `No treatment required`, `Withdrawn`

| From | To | Condition | Event | Use case | SQL |
|---|---|---|---|---|---|
| (start) | Awaiting verification | register_result = 'Covered' | submitInjuryForm | U1 Submit Injury Application | Q1.6: `INSERT InjuryClaim (claim_status = 'Awaiting verification')` |
| (start) | Register unavailable | register_result <> 'Covered' | submitInjuryForm | U1 Submit Injury Application | Q1.6: `INSERT InjuryClaim (claim_status = 'Register unavailable')` |
| Awaiting verification | Covered | officer selects Confirm | confirmResult | O2 Approve Injury Application | QO2.1: `UPDATE InjuryClaim SET claim_status = 'Covered'` |
| Register unavailable | Covered | officer selects Confirm | confirmResult | O2 Approve Injury Application | QO2.1: `UPDATE InjuryClaim SET claim_status = 'Covered'` |
| Awaiting verification | Not covered | officer selects Not Covered | rejectApplication | O3 Reject Injury Application | QO3.1: `UPDATE InjuryClaim SET claim_status = 'Not covered'` |
| Register unavailable | Not covered | officer selects Not Covered | rejectApplication | O3 Reject Injury Application | QO3.1: `UPDATE InjuryClaim SET claim_status = 'Not covered'` |
| Not covered | Rejected | reason_code chosen | rejectApplication | O3 Reject Injury Application | QO3.2: `UPDATE InjuryClaim SET claim_status = 'Rejected'` |
| Covered | No treatment required | report says no treatment | closeWithoutTreatment | O5.2 No Treatment Required | QO5.4: `UPDATE InjuryClaim SET claim_status = 'No treatment required'` |
| Covered | Withdrawn | user selects I cannot attend | cancelAppointment | U3.3 Appointment Confirmation (I cannot attend) | Q3.6: `UPDATE InjuryClaim SET claim_status = 'Withdrawn'` (in the same statement as the appointment's Cancelled, with a ClaimStatusHistory row) |

`No treatment required`, `Rejected` and `Withdrawn` are final. A `Withdrawn` claim is not listed by QO4.1 (it lists `Covered` claims without an open appointment), so the officer does not schedule it again.

## Appointment

States: `Pending`, `Confirmed`, `Rescheduled`, `Cancelled`

| From | To | Condition | Event | Use case | SQL |
|---|---|---|---|---|---|
| (start) | Pending | slot is free | offerAppointment | O4 Schedule Appointment | QO4.3: `INSERT Appointment (appointment_status = 'Pending')` |
| (start) | Confirmed | replaces a rescheduled row | reschedule | U3.2 Request Another Date | Q3.5: `INSERT Appointment (appointment_status = 'Confirmed')` |
| Pending | Confirmed | appointment_status = 'Pending' | confirmAppointment | U3.1 Confirm Appointment | Q3.3: `UPDATE Appointment SET appointment_status = 'Confirmed'` |
| Pending | Rescheduled | new slot is free | reschedule | U3.2 Request Another Date | Q3.5: `UPDATE Appointment SET appointment_status = 'Rescheduled'` |
| Confirmed | Rescheduled | new slot is free | reschedule | U3.2 Request Another Date | Q3.5: `UPDATE Appointment SET appointment_status = 'Rescheduled'` |
| Pending | Cancelled | user confirms the cancel | cancelAppointment | U3.3 I cannot attend | Q3.6: `UPDATE Appointment SET appointment_status = 'Cancelled'` |
| Confirmed | Cancelled | user confirms the cancel | cancelAppointment | U3.3 I cannot attend | Q3.6: `UPDATE Appointment SET appointment_status = 'Cancelled'` |

## Treatment

States: `Pending`, `Accepted`, `Cancelled`

| From | To | Condition | Event | Use case | SQL |
|---|---|---|---|---|---|
| (start) | Pending | slot is free | bookTreatment | O5.1 Book Treatment | QO5.3: `INSERT Treatment (treatment_status = 'Pending')` |
| Pending | Pending | treatment_status = 'Pending' | changeDate | U4.2 Change Date | QU4.2: `UPDATE Treatment SET scheduled_date = :new_date` |
| Pending | Accepted | treatment_status = 'Pending' | acceptTreatment | U4.1 Accept Case | QU4.1: `UPDATE Treatment SET treatment_status = 'Accepted'` |
| Pending | Cancelled | scheduled_date <= CURRENT_DATE | onDeadlineReached | U4.3 Reject | QU4.3: `UPDATE Treatment SET treatment_status = 'Cancelled'` |

## ConsultationReport

States: `Draft`, `Signed`, `Filed`, `Viewed`

| From | To | Condition | Event | Use case | SQL |
|---|---|---|---|---|---|
| (start) | Draft | no report for the session | saveDraft | C2.1 Amend the Draft | QC2.4: `INSERT ConsultationReport (signed_at = NULL)` |
| Draft | Draft | delivered_at IS NULL | saveDraft | C2.1 Amend the Draft | QC2.5: `UPDATE ConsultationReport SET report_content = :report_content` |
| Draft | Signed | report_content IS NOT NULL | signReport | C2.2 Sign the Signature | QC2.6: `UPDATE ConsultationReport SET signed_at = NOW()` |
| Signed | Draft | delivered_at IS NULL | saveDraft | C2.1 Amend the Draft | QC2.5: `UPDATE ConsultationReport SET signed_at = NULL` |
| Signed | Filed | signed_at IS NOT NULL | fileReport | C2.3 File the Report | QC2.7: `UPDATE ConsultationReport SET delivered_at = NOW()` |
| Filed | Viewed | read_at IS NULL | viewReport | O6 View Consultation Report | QO6.3: `UPDATE ConsultationReport SET read_at = NOW()` |
