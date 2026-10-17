# Sequence flows (from the sequence diagrams in SA report section 2.13)

One numbered message list per use case, read top to bottom. Participants follow the report's MVC layering: Page (boundary) -> Controller -> Model -> Repository -> DB connector. `{Qx.y}` names the SQL the repository runs (see `database/queries.sql`). `alt [guard]` blocks are the alternate cases; `ref` reuses the first steps of another use case. The PNGs in `diagrams/sequence/` are the same diagrams as drawn in the report.

## U1: Submit Injury Application

Participants: User (actor), RegisterPage (ui), InjuryFormPage (ui), InsuredFormController (controller), InsuredPersonModel (model), ClaimModel (model), InsuredPersonRepository (repository), ClaimRepository (repository), DB connector (db)

1. User -> RegisterPage: click "Register"
2. RegisterPage -> InjuryFormPage: redirect()
3. User -> InjuryFormPage: fill in forms, upload files, click "Submit"
4. InjuryFormPage -> InsuredFormController: submitInjuryForm(form, files)
5. InsuredFormController -> InsuredPersonModel: register(form)
6. InsuredPersonModel -> InsuredPersonModel: validateFields(form)
7. InsuredPersonModel -> InsuredPersonRepository: findInSSORegister(national_id) {Q1.1}
8. InsuredPersonRepository -> DB connector: performs query {Q1.1}
9. DB connector --> InsuredPersonRepository: result rows
10. InsuredPersonRepository --> InsuredPersonModel: registerRow
11. InsuredPersonModel -> InsuredPersonRepository: countByNationalId(national_id) {Q1.2}
12. InsuredPersonRepository -> DB connector: performs query {Q1.2}
13. DB connector --> InsuredPersonRepository: result rows
14. InsuredPersonRepository --> InsuredPersonModel: cnt
- alt [Validation Failed]
  15. InsuredPersonModel --> InsuredFormController: error(validation messages)
  16. InsuredFormController --> InjuryFormPage: show validation errors
17. InsuredPersonModel -> InsuredPersonRepository: insertInsuredPerson(form) {Q1.3}
18. InsuredPersonRepository -> DB connector: performs query {Q1.3}
19. DB connector --> InsuredPersonRepository: insured_id
20. InsuredPersonRepository --> InsuredPersonModel: insured_id
21. InsuredPersonModel -> InsuredPersonRepository: upsertEmployer(employer) {Q1.4}
22. InsuredPersonRepository -> DB connector: performs query {Q1.4}
23. DB connector --> InsuredPersonRepository: employer_id
24. InsuredPersonRepository --> InsuredPersonModel: employer_id
25. InsuredPersonModel -> InsuredPersonRepository: insertCoverage(insured_id, employer_id) {Q1.5}
26. InsuredPersonRepository -> DB connector: performs query {Q1.5}
27. DB connector --> InsuredPersonRepository: coverage_id
28. InsuredPersonRepository --> InsuredPersonModel: coverage_id
29. InsuredPersonModel --> InsuredFormController: insured_id, employer_id, coverage_id
30. InsuredFormController -> ClaimModel: createClaim(insured_id, form, files)
31. ClaimModel -> ClaimRepository: insertClaim(insured_id, injury) {Q1.6}
32. ClaimRepository -> DB connector: performs query {Q1.6}
33. DB connector --> ClaimRepository: claim_id
34. ClaimRepository --> ClaimModel: claim_id
35. ClaimModel -> ClaimRepository: assignClaimNo(claim_id) {Q1.7}
36. ClaimRepository -> DB connector: performs query {Q1.7}
37. DB connector --> ClaimRepository: claim_no, submitted_at
38. ClaimRepository --> ClaimModel: claim_no, submitted_at
39. ClaimModel -> ClaimRepository: insertDocument(claim_id, file) {Q1.8}
40. ClaimRepository -> DB connector: performs query {Q1.8}
41. DB connector --> ClaimRepository: rows affected
42. ClaimRepository --> ClaimModel: ok
43. ClaimModel -> ClaimRepository: insertAutoEligibility(claim_id, coverage_id) {Q1.9}
44. ClaimRepository -> DB connector: performs query {Q1.9}
45. DB connector --> ClaimRepository: rows affected
46. ClaimRepository --> ClaimModel: ok
47. ClaimModel -> ClaimRepository: insertFirstStatus(claim_id) {Q1.10}
48. ClaimRepository -> DB connector: performs query {Q1.10}
49. DB connector --> ClaimRepository: rows affected
50. ClaimRepository --> ClaimModel: ok
51. ClaimModel --> InsuredFormController: claim_no, submitted_at
52. InsuredFormController --> InjuryFormPage: show submission complete (claim_no, submitted_at)

## U2: View Notify Message

Participants: User (actor), HomePage (ui), PopUpController (controller), NotificationController (controller), NotificationRepository (repository), ClaimRepository (repository), DB connector (db)

1. User -> HomePage: enters the homepage
2. HomePage -> NotificationController: checkUnreadNotifications(insured_id)
3. NotificationController -> NotificationRepository: countUnread(insured_id) {Q2.1}
4. NotificationRepository -> DB connector: performs query {Q2.1}
5. DB connector --> NotificationRepository: unread count
6. NotificationRepository --> NotificationController: unread count
- alt [unread = 0]
  7. NotificationController --> HomePage: shows bell icon without red dot
8. [unread > 0] NotificationController --> HomePage: shows bell icon with red dot
9. HomePage -> NotificationController: getHomeClaim(insured_id)
10. NotificationController -> ClaimRepository: findHomeClaim(insured_id) {Q2.4}
11. ClaimRepository -> DB connector: performs query {Q2.4}
12. DB connector --> ClaimRepository: claim card row
13. ClaimRepository --> NotificationController: latest claim, next appointment
14. NotificationController --> HomePage: show claim card
15. User -> HomePage: clicks the bell icon
16. HomePage -> NotificationController: getNotifications(insured_id)
17. NotificationController -> NotificationRepository: findNotifications(insured_id) {Q2.2}
18. NotificationRepository -> DB connector: performs query {Q2.2}
19. DB connector --> NotificationRepository: notification rows
20. NotificationRepository --> NotificationController: notifications (list, with is_read flag)
21. NotificationController --> PopUpController: show popup window with list
22. PopUpController --> HomePage: show popup window with list
23. User -> HomePage: select a specific notification
24. HomePage -> NotificationController: markAsRead(notification_id)
25. NotificationController -> NotificationRepository: markAsRead(notification_id, insured_id) {Q2.3}
26. NotificationRepository -> DB connector: performs query {Q2.3}
27. DB connector --> NotificationRepository: ack
28. NotificationRepository --> NotificationController: ack
29. NotificationController --> HomePage: show notification detail

## U3.1: Appointment Confirmation (Confirm Appointment)

Participants: User (actor), NotificationPage (ui), AppointmentPage (ui), AppointmentController (controller), AppointmentModel (model), NotificationModel (model), AppointmentRepository (repository), NotificationRepository (repository), DB connector (db)

1. User -> NotificationPage: click "Notifications"
2. NotificationPage -> AppointmentController: checkUnreadNotifications(insured_id)
3. AppointmentController -> NotificationModel: countUnread(insured_id)
4. NotificationModel -> NotificationRepository: countUnread(insured_id) {Q3.1}
5. NotificationRepository -> DB connector: performs query {Q3.1}
6. DB connector --> NotificationRepository: result rows
7. NotificationRepository --> NotificationModel: unread count
8. NotificationModel --> AppointmentController: unread count
9. AppointmentController -> NotificationModel: getNotifications(insured_id)
10. NotificationModel -> NotificationRepository: findNotifications(insured_id) {Q2.2}
11. NotificationRepository -> DB connector: performs query {Q2.2}
12. DB connector --> NotificationRepository: result rows
13. NotificationRepository --> NotificationModel: notifications
14. NotificationModel --> AppointmentController: notifications
15. AppointmentController --> NotificationPage: show messages, red dot on the new one
16. User -> NotificationPage: click notification (claim_id)
17. NotificationPage -> AppointmentPage: open(claim_id)
18. AppointmentPage -> AppointmentController: getAppointment(claim_id, insured_id)
19. AppointmentController -> AppointmentModel: getAppointmentDetail(claim_id, insured_id)
20. AppointmentModel -> AppointmentRepository: findLatestAppointment(claim_id, insured_id) {Q3.2}
21. AppointmentRepository -> DB connector: performs query {Q3.2}
22. DB connector --> AppointmentRepository: result rows
23. AppointmentRepository --> AppointmentModel: appointment
24. AppointmentModel --> AppointmentController: appointment
25. AppointmentController --> AppointmentPage: show appointment + 3 options
26. User -> AppointmentPage: click "Confirm Appointment"
27. AppointmentPage -> AppointmentController: confirmAppointment(appointment_id)
28. AppointmentController -> AppointmentModel: confirm(appointment_id)
29. AppointmentModel -> AppointmentRepository: confirmAppointment(appointment_id) {Q3.3}
30. AppointmentRepository -> DB connector: performs query {Q3.3}
31. DB connector --> AppointmentRepository: ok (committed)
32. AppointmentRepository --> AppointmentModel: ok
33. AppointmentModel --> AppointmentController: ok
34. AppointmentController -> NotificationModel: notifyConsultant(appointment_id)
35. NotificationModel -> NotificationRepository: insertConsultantMessage(appointment_id) {QN.5}
36. NotificationRepository -> DB connector: performs query {QN.5}
37. DB connector --> NotificationRepository: rows affected
38. NotificationRepository --> NotificationModel: ok
39. NotificationModel --> AppointmentController: ok
40. AppointmentController -> NotificationModel: markRead(notification_id)
41. NotificationModel -> NotificationRepository: markRead(notification_id, insured_id) {Q3.7}
42. NotificationRepository -> DB connector: performs query {Q3.7}
43. DB connector --> NotificationRepository: rows affected
44. NotificationRepository --> NotificationModel: ok
45. NotificationModel --> AppointmentController: ok
46. AppointmentController --> AppointmentPage: show reminder pop-up

## U3.2: Appointment Confirmation (Request another date)

Participants: User (actor), AppointmentPage (ui), AppointmentController (controller), AppointmentModel (model), NotificationModel (model), AppointmentRepository (repository), NotificationRepository (repository), DB connector (db)

- ref U3.1: Appointment Confirmation (steps 1-3)
1. User -> AppointmentPage: click "Request Another Date"
2. AppointmentPage -> AppointmentPage: showDatePicker()
3. User -> AppointmentPage: selectDate(slot_date)
4. AppointmentPage -> AppointmentController: getFreeSlots(consultant_id, slot_date)
5. AppointmentController -> AppointmentModel: getFreeSlots(consultant_id, slot_date)
6. AppointmentModel -> AppointmentRepository: findFreeSlots(consultant_id, slot_date) {Q3.4}
7. AppointmentRepository -> DB connector: performs query {Q3.4}
8. DB connector --> AppointmentRepository: result rows
9. AppointmentRepository --> AppointmentModel: slots
10. AppointmentModel --> AppointmentController: slots
11. AppointmentController --> AppointmentPage: show free times
- alt [Cancel]
  12. User -> AppointmentPage: click "Cancel"
  13. AppointmentPage -> AppointmentPage: backToAppointmentPage()
14. User -> AppointmentPage: pick time, click "Confirm"
15. AppointmentPage -> AppointmentController: reschedule(appointment_id, new_date, new_time)
16. AppointmentController -> AppointmentModel: reschedule(appointment_id, new_date, new_time)
17. AppointmentModel -> AppointmentRepository: rescheduleAppointment(appointment_id, new_date, new_time) {Q3.5}
18. AppointmentRepository -> DB connector: performs query {Q3.5}
19. DB connector --> AppointmentRepository: ok (committed)
20. AppointmentRepository --> AppointmentModel: new appointment_id
21. AppointmentModel --> AppointmentController: new appointment_id
22. AppointmentController -> NotificationModel: notifyConsultant(new appointment_id)
23. NotificationModel -> NotificationRepository: insertConsultantMessage(new appointment_id) {QN.5}
24. NotificationRepository -> DB connector: performs query {QN.5}
25. DB connector --> NotificationRepository: rows affected
26. NotificationRepository --> NotificationModel: ok
27. NotificationModel --> AppointmentController: ok
28. AppointmentController -> NotificationModel: markRead(notification_id)
29. NotificationModel -> NotificationRepository: markRead(notification_id, insured_id) {Q3.7}
30. NotificationRepository -> DB connector: performs query {Q3.7}
31. DB connector --> NotificationRepository: rows affected
32. NotificationRepository --> NotificationModel: ok
33. NotificationModel --> AppointmentController: ok
34. AppointmentController --> AppointmentPage: show date-changed notice

## U3.3: Appointment Confirmation (I cannot attend)

Participants: User (actor), AppointmentPage (ui), AppointmentController (controller), AppointmentModel (model), NotificationModel (model), AppointmentRepository (repository), NotificationRepository (repository), DB connector (db)

- ref U3.1: Appointment Confirmation (steps 1-3)
1. User -> AppointmentPage: click "I cannot attend"
2. AppointmentPage -> AppointmentPage: showCancelWarning()
- alt [Go Back]
  3. User -> AppointmentPage: click "Go Back"
  4. AppointmentPage -> AppointmentPage: backToAppointmentPage()
5. User -> AppointmentPage: click "Confirm Cancel Appointment"
6. AppointmentPage -> AppointmentController: cancelAppointment(appointment_id)
7. AppointmentController -> AppointmentModel: cancel(appointment_id)
8. AppointmentModel -> AppointmentRepository: cancelAppointment(appointment_id) {Q3.6}
9. AppointmentRepository -> DB connector: performs query {Q3.6}
10. DB connector --> AppointmentRepository: ok (committed)
11. AppointmentRepository --> AppointmentModel: ok (claim Withdrawn)
12. AppointmentModel --> AppointmentController: ok (claim Withdrawn)
13. AppointmentController -> NotificationModel: notifyConsultant(appointment_id)
14. NotificationModel -> NotificationRepository: insertConsultantMessage(appointment_id) {QN.5}
15. NotificationRepository -> DB connector: performs query {QN.5}
16. DB connector --> NotificationRepository: rows affected
17. NotificationRepository --> NotificationModel: ok
18. NotificationModel --> AppointmentController: ok
19. AppointmentController -> NotificationModel: markRead(notification_id)
20. NotificationModel -> NotificationRepository: markRead(notification_id, insured_id) {Q3.7}
21. NotificationRepository -> DB connector: performs query {Q3.7}
22. DB connector --> NotificationRepository: rows affected
23. NotificationRepository --> NotificationModel: ok
24. NotificationModel --> AppointmentController: ok
25. AppointmentController --> AppointmentPage: show cancelled notice

## U4.1: Treatment Confirmation (Accept Case)

Participants: User (actor), TreatmentPage (ui), TreatmentController (controller), TreatmentModel (model), TreatmentRepository (repository), DB connector (db)

1. User -> TreatmentPage: open "Confirm Treatment" (treatment_id)
2. TreatmentPage -> TreatmentController: getTreatment(treatment_id, insured_id)
3. TreatmentController -> TreatmentModel: getTreatmentDetail(treatment_id, insured_id)
4. TreatmentModel -> TreatmentRepository: findTreatmentDetail(treatment_id, insured_id) {QU4.4}
5. TreatmentRepository -> DB connector: performs query {QU4.4}
6. DB connector --> TreatmentRepository: result rows
7. TreatmentRepository --> TreatmentModel: treatment detail
8. TreatmentModel --> TreatmentController: treatment detail
9. TreatmentController --> TreatmentPage: show Confirm Treatment page
10. User -> TreatmentPage: click "Accept"
11. TreatmentPage -> TreatmentController: acceptTreatment(treatment_id, claim_id, insured_id)
12. TreatmentController -> TreatmentModel: accept(treatment_id, claim_id, insured_id)
13. TreatmentModel -> TreatmentRepository: updateStatusAccepted(treatment_id, claim_id, insured_id) {QU4.1}
14. TreatmentRepository -> DB connector: performs query {QU4.1}
15. DB connector --> TreatmentRepository: treatment_id
16. TreatmentRepository --> TreatmentModel: ok (Accepted)
17. TreatmentModel --> TreatmentController: ok (Accepted)
18. TreatmentController --> TreatmentPage: show accepted pop-up

## U4.2: Treatment Confirmation (Change Date)

Participants: User (actor), TreatmentPage (ui), TreatmentController (controller), TreatmentModel (model), TreatmentRepository (repository), DB connector (db)

- ref U4.1: Treatment Confirmation (steps 1-2)
1. User -> TreatmentPage: click "Request Another Date"
2. TreatmentPage -> TreatmentController: getAvailableDates(treatment_id, insured_id)
3. TreatmentController -> TreatmentModel: getAvailableDates(treatment_id, insured_id)
4. TreatmentModel -> TreatmentRepository: findAvailableDates(treatment_id, insured_id) {QU4.5}
5. TreatmentRepository -> DB connector: performs query {QU4.5}
6. DB connector --> TreatmentRepository: result rows
7. TreatmentRepository --> TreatmentModel: free weekdays
8. TreatmentModel --> TreatmentController: free weekdays
9. TreatmentController --> TreatmentPage: show "Choose another date"
10. User -> TreatmentPage: select date, click "Save date"
11. TreatmentPage -> TreatmentController: changeDate(treatment_id, claim_id, new_date, insured_id)
12. TreatmentController -> TreatmentModel: changeDate(treatment_id, claim_id, new_date, insured_id)
13. TreatmentModel -> TreatmentRepository: updateScheduledDate(treatment_id, claim_id, new_date, insured_id) {QU4.2}
14. TreatmentRepository -> DB connector: performs query {QU4.2}
15. DB connector --> TreatmentRepository: treatment_id, scheduled_date, scheduled_time
16. TreatmentRepository --> TreatmentModel: new date (Accepted)
17. TreatmentModel --> TreatmentController: new date (Accepted)
18. TreatmentController --> TreatmentPage: show date-changed message

## U4.3: Treatment Confirmation (Reject)

Participants: AutoCancelJob (ui), TreatmentController (controller), TreatmentModel (model), TreatmentRepository (repository), DB connector (db)

1. AutoCancelJob -> AutoCancelJob: onDeadlineReached()
2. AutoCancelJob -> TreatmentController: cancelUnacceptedTreatments()
3. TreatmentController -> TreatmentModel: cancelExpired()
4. TreatmentModel -> TreatmentRepository: cancelExpiredAndNotifyUser() {QU4.3}
5. TreatmentRepository -> DB connector: performs query {QU4.3}
6. DB connector --> TreatmentRepository: rows affected
7. TreatmentRepository --> TreatmentModel: cancelled treatments (claims Withdrawn)
8. TreatmentModel --> TreatmentController: cancelled treatments (claims Withdrawn)
9. TreatmentController --> AutoCancelJob: done

## U5: View Appointment Schedule

Participants: User (actor), SchedulePage (ui), AppointmentController (controller), AppointmentModel (model), AppointmentRepository (repository), DB connector (db)

1. User -> SchedulePage: click "Schedule Page"
2. SchedulePage -> AppointmentController: getAppointmentSchedule(insured_id)
3. AppointmentController -> AppointmentModel: getUpcomingAppointments(insured_id)
4. AppointmentModel -> AppointmentRepository: findUpcomingAppointments(insured_id) {QU5.1}
5. AppointmentRepository -> DB connector: performs query {QU5.1}
6. DB connector --> AppointmentRepository: result rows
7. AppointmentRepository --> AppointmentModel: appointments
8. AppointmentModel --> AppointmentController: appointments
9. AppointmentController --> SchedulePage: show appointment list

## U6: View Treatment Schedule

Participants: User (actor), SchedulePage (ui), TreatmentController (controller), TreatmentModel (model), TreatmentRepository (repository), DB connector (db)

1. User -> SchedulePage: click "Schedule Page"
2. SchedulePage -> TreatmentController: getTreatmentSchedule(insured_id)
3. TreatmentController -> TreatmentModel: getUpcomingTreatments(insured_id)
4. TreatmentModel -> TreatmentRepository: findUpcomingTreatments(insured_id) {Q6.1}
5. TreatmentRepository -> DB connector: performs query {Q6.1}
6. DB connector --> TreatmentRepository: result rows
7. TreatmentRepository --> TreatmentModel: treatments
8. TreatmentModel --> TreatmentController: treatments
9. TreatmentController --> SchedulePage: show treatment list

## O1: View Injury Application

Participants: Evaluation Officer (actor), VerificationPage (ui), EligibilityDecisionPage (ui), VerificationController (controller), ClaimModel (model), ClaimRepository (repository), DB connector (db)

1. Evaluation Officer -> VerificationPage: click "Verification"
2. VerificationPage -> VerificationController: getVerificationList()
3. VerificationController -> ClaimModel: getPendingApplications()
4. ClaimModel -> ClaimRepository: findPendingClaims() {QO1.1}
5. ClaimRepository -> DB connector: performs query {QO1.1}
6. DB connector --> ClaimRepository: result rows
7. ClaimRepository --> ClaimModel: pendingClaims
8. ClaimModel -> ClaimRepository: countByStatus() {QO1.2}
9. ClaimRepository -> DB connector: performs query {QO1.2}
10. DB connector --> ClaimRepository: result rows
11. ClaimRepository --> ClaimModel: statusCounts
12. ClaimModel --> VerificationController: pendingClaims, statusCounts
13. VerificationController --> VerificationPage: show list + status counts
14. Evaluation Officer -> VerificationPage: click "Open" (claim_id)
15. VerificationPage -> EligibilityDecisionPage: open(claim_id)
16. EligibilityDecisionPage -> VerificationController: getClaimDetail(claim_id)
17. VerificationController -> ClaimModel: getClaimDetail(claim_id)
18. ClaimModel -> ClaimRepository: findClaimSummary(claim_id) {QO1.3}
19. ClaimRepository -> DB connector: performs query {QO1.3}
20. DB connector --> ClaimRepository: result rows
21. ClaimRepository --> ClaimModel: header, summary
22. ClaimModel -> ClaimRepository: findDocuments(claim_id) {QO1.4}
23. ClaimRepository -> DB connector: performs query {QO1.4}
24. DB connector --> ClaimRepository: result rows
25. ClaimRepository --> ClaimModel: documents
26. ClaimModel -> ClaimRepository: findAutoEligibility(claim_id) {QO1.5}
27. ClaimRepository -> DB connector: performs query {QO1.5}
28. DB connector --> ClaimRepository: result rows
29. ClaimRepository --> ClaimModel: section33Result
30. ClaimModel --> VerificationController: claimDetail
31. VerificationController --> EligibilityDecisionPage: show EligibilityDecisionPage
32. Evaluation Officer -> EligibilityDecisionPage: click "View" (document)
33. EligibilityDecisionPage -> EligibilityDecisionPage: openFile(file_uri)

## O2: Approve Injury Application

Participants: Evaluation Officer (actor), EligibilityDecisionPage (ui), VerificationController (controller), ClaimModel (model), NotificationModel (model), ClaimRepository (repository), NotificationRepository (repository), DB connector (db)

- ref O1: View Injury Application (steps 1-4)
1. Evaluation Officer -> EligibilityDecisionPage: select "Confirm", click "Confirm Result"
2. EligibilityDecisionPage -> EligibilityDecisionPage: showConfirmationCard()
- alt [Cancel]
  3. Evaluation Officer -> EligibilityDecisionPage: click "Cancel"
  4. EligibilityDecisionPage -> EligibilityDecisionPage: closeConfirmationCard()
5. [Confirm] Evaluation Officer -> EligibilityDecisionPage: click "Confirm"
6. EligibilityDecisionPage -> VerificationController: confirmResult(claim_id, 'Covered')
7. VerificationController -> ClaimModel: confirmResult(claim_id, 'Covered')
8. ClaimModel -> ClaimRepository: saveResult(claim_id, 'Covered') {QO2.1}
9. ClaimRepository -> DB connector: performs query {QO2.1}
10. DB connector --> ClaimRepository: ok (committed)
11. ClaimRepository --> ClaimModel: ok
12. ClaimModel --> VerificationController: ok
13. VerificationController -> NotificationModel: notifyUser(claim_id, subject, body)
14. NotificationModel -> NotificationRepository: insertNotification(claim_id, subject, body) {QN.1}
15. NotificationRepository -> DB connector: performs query {QN.1}
16. DB connector --> NotificationRepository: rows affected
17. NotificationRepository --> NotificationModel: ok
18. NotificationModel --> VerificationController: ok
19. VerificationController --> EligibilityDecisionPage: close card, show confirmed result

## O3: Reject Injury Application

Participants: Evaluation Officer (actor), EligibilityDecisionPage (ui), VerificationController (controller), ClaimModel (model), NotificationModel (model), ClaimRepository (repository), NotificationRepository (repository), DB connector (db)

- ref O1: View Injury Application (steps 1-4)
1. Evaluation Officer -> EligibilityDecisionPage: select "Not Covered", click "Confirm Result"
2. EligibilityDecisionPage -> EligibilityDecisionPage: showConfirmationCard()
- alt [Cancel]
  3. Evaluation Officer -> EligibilityDecisionPage: click "Cancel"
  4. EligibilityDecisionPage -> EligibilityDecisionPage: closeConfirmationCard()
5. [Confirm] Evaluation Officer -> EligibilityDecisionPage: click "Confirm"
6. EligibilityDecisionPage -> VerificationController: rejectApplication(claim_id, result)
7. VerificationController -> ClaimModel: rejectApplication(claim_id, result)
8. ClaimModel -> ClaimRepository: saveResult(claim_id, 'Not covered') {QO3.1}
9. ClaimRepository -> DB connector: performs query {QO3.1}
10. DB connector --> ClaimRepository: ok (committed)
11. ClaimRepository --> ClaimModel: ok
12. ClaimModel -> ClaimRepository: insertRejection(claim_id, reason_code, message) {QO3.2}
13. ClaimRepository -> DB connector: performs query {QO3.2}
14. DB connector --> ClaimRepository: ok (committed)
15. ClaimRepository --> ClaimModel: ok
16. ClaimModel --> VerificationController: ok
17. VerificationController -> NotificationModel: notifyRejection(claim_id)
18. NotificationModel -> NotificationRepository: insertRejectionNotice(claim_id) {QN.2}
19. NotificationRepository -> DB connector: performs query {QN.2}
20. DB connector --> NotificationRepository: rows affected
21. NotificationRepository --> NotificationModel: ok
22. NotificationModel --> VerificationController: ok
23. VerificationController --> EligibilityDecisionPage: close card, show rejected result

## O4: Schedule Appointment

Participants: Evaluation Officer (actor), ScheduleAppointmentPage (ui), AppointmentController (controller), AppointmentModel (model), NotificationModel (model), AppointmentRepository (repository), NotificationRepository (repository), DB connector (db)

1. Evaluation Officer -> ScheduleAppointmentPage: click "Scheduling"
2. ScheduleAppointmentPage -> AppointmentController: getClaimsToSchedule()
3. AppointmentController -> AppointmentModel: getClaimsToSchedule()
4. AppointmentModel -> AppointmentRepository: findClaimsToSchedule() {QO4.1}
5. AppointmentRepository -> DB connector: performs query {QO4.1}
6. DB connector --> AppointmentRepository: result rows
7. AppointmentRepository --> AppointmentModel: claims
8. AppointmentModel --> AppointmentController: claims
9. AppointmentController --> ScheduleAppointmentPage: show header (claim, name, verified date)
10. Evaluation Officer -> ScheduleAppointmentPage: selectDate(slot_date)
11. ScheduleAppointmentPage -> AppointmentController: getAvailability(slot_date)
12. AppointmentController -> AppointmentModel: getConsultantSlots(slot_date)
13. AppointmentModel -> AppointmentRepository: findConsultantSlots(slot_date, officer_id) {QO4.2}
14. AppointmentRepository -> DB connector: performs query {QO4.2}
15. DB connector --> AppointmentRepository: result rows
16. AppointmentRepository --> AppointmentModel: slots
17. AppointmentModel --> AppointmentController: slots
18. AppointmentController --> ScheduleAppointmentPage: show consultant availability
19. Evaluation Officer -> ScheduleAppointmentPage: select slot, click "Offer to the Consultant"
20. ScheduleAppointmentPage -> ScheduleAppointmentPage: showConfirmationCard()
- alt [Cancel]
  21. Evaluation Officer -> ScheduleAppointmentPage: click "Cancel"
  22. ScheduleAppointmentPage -> ScheduleAppointmentPage: closeConfirmationCard()
23. [Confirm] Evaluation Officer -> ScheduleAppointmentPage: click "Confirm"
24. ScheduleAppointmentPage -> AppointmentController: offerAppointment(claim_id, consultant_id, slot)
25. AppointmentController -> AppointmentModel: createAppointment(claim_id, consultant_id, slot)
26. AppointmentModel -> AppointmentRepository: insertAppointment(appointment) {QO4.3}
27. AppointmentRepository -> DB connector: performs query {QO4.3}
28. DB connector --> AppointmentRepository: appointment_id
29. AppointmentRepository --> AppointmentModel: appointment_id
30. AppointmentModel --> AppointmentController: appointment_id
31. AppointmentController -> NotificationModel: notifyUserAndConsultant(appointment_id)
32. NotificationModel -> NotificationRepository: insertAppointmentNotices(appointment_id) {QN.3}
33. NotificationRepository -> DB connector: performs query {QN.3}
34. DB connector --> NotificationRepository: rows affected
35. NotificationRepository --> NotificationModel: ok
36. NotificationModel --> AppointmentController: ok
37. AppointmentController --> ScheduleAppointmentPage: show "Appointment Scheduled"

## O5.1: Schedule Treatment (Book treatment)

Participants: Evaluation Officer (actor), ScheduleTreatmentPage (ui), TreatmentController (controller), TreatmentModel (model), NotificationModel (model), TreatmentRepository (repository), NotificationRepository (repository), DB connector (db)

1. Evaluation Officer -> ScheduleTreatmentPage: click "Treatment"
2. ScheduleTreatmentPage -> TreatmentController: getClaimsForTreatment()
3. TreatmentController -> TreatmentModel: getClaimsForTreatment()
4. TreatmentModel -> TreatmentRepository: findClaimsWithFiledReport() {QO5.1}
5. TreatmentRepository -> DB connector: performs query {QO5.1}
6. DB connector --> TreatmentRepository: result rows
7. TreatmentRepository --> TreatmentModel: claims, report
8. TreatmentModel --> TreatmentController: claims, report
9. TreatmentController --> ScheduleTreatmentPage: show header + report card
10. Evaluation Officer -> ScheduleTreatmentPage: enter type, duration, facility
11. ScheduleTreatmentPage -> TreatmentController: getAvailableTimes(facility, date_from, date_to)
12. TreatmentController -> TreatmentModel: getFacilitySlots(facility, date_from, date_to)
13. TreatmentModel -> TreatmentRepository: findFacilitySlots(facility, date_from, date_to, officer_id) {QO5.2}
14. TreatmentRepository -> DB connector: performs query {QO5.2}
15. DB connector --> TreatmentRepository: result rows
16. TreatmentRepository --> TreatmentModel: slots
17. TreatmentModel --> TreatmentController: slots
18. TreatmentController --> ScheduleTreatmentPage: show available times
19. Evaluation Officer -> ScheduleTreatmentPage: select slot, click "Book treatment"
20. ScheduleTreatmentPage -> ScheduleTreatmentPage: showConfirmationCard()
- alt [Cancel]
  21. Evaluation Officer -> ScheduleTreatmentPage: click "Cancel"
  22. ScheduleTreatmentPage -> ScheduleTreatmentPage: closeConfirmationCard()
23. [Confirm] Evaluation Officer -> ScheduleTreatmentPage: click "Confirm"
24. ScheduleTreatmentPage -> TreatmentController: bookTreatment(claim_id, report_id, details)
25. TreatmentController -> TreatmentModel: bookTreatment(claim_id, report_id, details)
26. TreatmentModel -> TreatmentRepository: insertTreatment(treatment) {QO5.3}
27. TreatmentRepository -> DB connector: performs query {QO5.3}
28. DB connector --> TreatmentRepository: treatment_id
29. TreatmentRepository --> TreatmentModel: treatment_id
30. TreatmentModel --> TreatmentController: treatment_id
31. TreatmentController -> NotificationModel: notifyUser(claim_id, subject, body)
32. NotificationModel -> NotificationRepository: insertNotification(claim_id, subject, body) {QN.1}
33. NotificationRepository -> DB connector: performs query {QN.1}
34. DB connector --> NotificationRepository: rows affected
35. NotificationRepository --> NotificationModel: ok
36. NotificationModel --> TreatmentController: ok
37. TreatmentController --> ScheduleTreatmentPage: show "Treatment Booked"

## O5.2: Schedule Treatment (No treatment require)

Participants: Evaluation Officer (actor), ScheduleTreatmentPage (ui), TreatmentController (controller), ClaimModel (model), NotificationModel (model), ClaimRepository (repository), NotificationRepository (repository), DB connector (db)

- ref O5.1: Schedule Treatment (steps 1-2)
1. Evaluation Officer -> ScheduleTreatmentPage: click "No treatment require"
2. ScheduleTreatmentPage -> ScheduleTreatmentPage: showConfirmationCard()
- alt [Cancel]
  3. Evaluation Officer -> ScheduleTreatmentPage: click "Cancel"
  4. ScheduleTreatmentPage -> ScheduleTreatmentPage: closeConfirmationCard()
5. [Confirm] Evaluation Officer -> ScheduleTreatmentPage: click "Confirm"
6. ScheduleTreatmentPage -> TreatmentController: closeWithoutTreatment(claim_id)
7. TreatmentController -> ClaimModel: closeWithoutTreatment(claim_id)
8. ClaimModel -> ClaimRepository: updateNoTreatment(claim_id) {QO5.4}
9. ClaimRepository -> DB connector: performs query {QO5.4}
10. DB connector --> ClaimRepository: ok (committed)
11. ClaimRepository --> ClaimModel: ok
12. ClaimModel --> TreatmentController: ok
13. TreatmentController -> NotificationModel: notifyNoTreatment(claim_id)
14. NotificationModel -> NotificationRepository: insertNoTreatmentNotice(claim_id) {QN.4}
15. NotificationRepository -> DB connector: performs query {QN.4}
16. DB connector --> NotificationRepository: rows affected
17. NotificationRepository --> NotificationModel: ok
18. NotificationModel --> TreatmentController: ok
19. TreatmentController --> ScheduleTreatmentPage: show "No Treatment Required"

## O6: View Consultant Report

Participants: Evaluation Officer (actor), ReportListPage (ui), ConsultationReportPage (ui), ReportController (controller), ReportModel (model), ReportRepository (repository), DB connector (db)

1. Evaluation Officer -> ReportListPage: click "Consultation Reports"
2. ReportListPage -> ReportController: getReportList()
3. ReportController -> ReportModel: getReportList()
4. ReportModel -> ReportRepository: findFiledReports() {QO6.1}
5. ReportRepository -> DB connector: performs query {QO6.1}
6. DB connector --> ReportRepository: result rows
7. ReportRepository --> ReportModel: reports
8. ReportModel --> ReportController: reports
9. ReportController --> ReportListPage: show report list
10. Evaluation Officer -> ReportListPage: selectReport(report_id)
11. ReportListPage -> ConsultationReportPage: open(report_id)
12. ConsultationReportPage -> ReportController: getReport(report_id)
13. ReportController -> ReportModel: getReport(report_id)
14. ReportModel -> ReportRepository: findReport(report_id) {QO6.2}
15. ReportRepository -> DB connector: performs query {QO6.2}
16. DB connector --> ReportRepository: result rows
17. ReportRepository --> ReportModel: report
18. ReportModel --> ReportController: report
19. ReportController --> ConsultationReportPage: show report page
20. Evaluation Officer -> ConsultationReportPage: click "View"
21. ConsultationReportPage -> ReportController: viewReport(report_id)
22. ReportController -> ReportModel: markViewed(report_id)
23. ReportModel -> ReportRepository: updateReadAt(report_id) {QO6.3}
24. ReportRepository -> DB connector: performs query {QO6.3}
25. DB connector --> ReportRepository: rows affected
26. ReportRepository --> ReportModel: ok
27. ReportModel --> ReportController: ok
28. ReportController --> ConsultationReportPage: ok
- alt [File]
  29. ConsultationReportPage -> ConsultationReportPage: showFile(report file)
30. [Text field] ConsultationReportPage -> ConsultationReportPage: showTextField(header, body)

## C1: View Appointment Schedule

Participants: Consultant (actor), SchedulePage (ui), AppointmentController (controller), AppointmentModel (model), AppointmentRepository (repository), DB connector (db)

1. Consultant -> SchedulePage: click "Schedule Page"
2. SchedulePage -> AppointmentController: getSchedule(consultant_id)
3. AppointmentController -> AppointmentModel: getConsultantSchedule(consultant_id)
4. AppointmentModel -> AppointmentRepository: findConfirmedAppointments(consultant_id) {QC1.1}
5. AppointmentRepository -> DB connector: performs query {QC1.1}
6. DB connector --> AppointmentRepository: result rows
7. AppointmentRepository --> AppointmentModel: appointments
8. AppointmentModel --> AppointmentController: appointments
9. AppointmentController --> SchedulePage: show schedule list

## C2.1: Create Consultant Report (Amend the draft)

Participants: Consultant (actor), CreateReportPage (ui), ReportController (controller), ReportModel (model), ReportRepository (repository), DB connector (db)

1. Consultant -> CreateReportPage: click "Create Consultation Report"
2. CreateReportPage -> ReportController: getPendingConsultations(consultant_id)
3. ReportController -> ReportModel: getPendingConsultations(consultant_id)
4. ReportModel -> ReportRepository: findConsultationsAwaitingReport(consultant_id) {QC2.1}
5. ReportRepository -> DB connector: performs query {QC2.1}
6. DB connector --> ReportRepository: result rows
7. ReportRepository --> ReportModel: consultations
8. ReportModel --> ReportController: consultations
9. ReportController --> CreateReportPage: show consultations
10. Consultant -> CreateReportPage: selectConsultation(appointment_id)
11. CreateReportPage -> ReportController: openReport(appointment_id)
12. ReportController -> ReportModel: openReport(appointment_id)
13. ReportModel -> ReportRepository: insertSessionIfMissing(appointment_id) {QC2.2}
14. ReportRepository -> DB connector: performs query {QC2.2}
15. DB connector --> ReportRepository: rows affected
16. ReportRepository --> ReportModel: ok
17. ReportModel -> ReportRepository: findReportPage(appointment_id) {QC2.3}
18. ReportRepository -> DB connector: performs query {QC2.3}
19. DB connector --> ReportRepository: result rows
20. ReportRepository --> ReportModel: reportPage
21. ReportModel --> ReportController: reportPage
22. ReportController --> CreateReportPage: show report page
23. Consultant -> CreateReportPage: click "Amend the draft"
24. CreateReportPage -> CreateReportPage: enableDraftEditing()
- alt [Attach file]
  25. Consultant -> CreateReportPage: click "Attach"
  26. CreateReportPage -> CreateReportPage: openFileExplorer()
  27. Consultant -> CreateReportPage: choose file, click "Open"
  28. CreateReportPage -> CreateReportPage: showFileAttached()
29. Consultant -> CreateReportPage: type report, click "Finish the draft"
30. CreateReportPage -> ReportController: saveDraft(session_id, report_content)
31. ReportController -> ReportModel: saveDraft(session_id, report_content)
- alt [Draft already saved]
  32. ReportModel -> ReportRepository: updateDraft(report_id, report_content) {QC2.5}
  33. ReportRepository -> DB connector: performs query {QC2.5}
  34. DB connector --> ReportRepository: rows affected
  35. ReportRepository --> ReportModel: ok
  36. ReportModel --> ReportController: ok
  37. ReportController --> CreateReportPage: update text field
38. ReportModel -> ReportRepository: insertDraft(session_id, report_content) {QC2.4}
39. ReportRepository -> DB connector: performs query {QC2.4}
40. DB connector --> ReportRepository: report_id
41. ReportRepository --> ReportModel: report_id
42. ReportModel --> ReportController: report_id
43. ReportController --> CreateReportPage: update text field

## C2.2: Create Consultant Report (Sign the signature)

Participants: Consultant (actor), CreateReportPage (ui), ReportController (controller), ReportModel (model), ReportRepository (repository), DB connector (db)

- ref C2.1: Create Consultant Report (steps 1-2)
1. Consultant -> CreateReportPage: click "Sign the signature"
2. CreateReportPage -> CreateReportPage: showSignatureCard()
- alt [Delete]
  3. Consultant -> CreateReportPage: click "Delete"
  4. CreateReportPage -> CreateReportPage: clearSignature()
5. Consultant -> CreateReportPage: sign, click "Confirm"
6. CreateReportPage -> ReportController: signReport(report_id)
7. ReportController -> ReportModel: signReport(report_id)
8. ReportModel -> ReportRepository: updateSignedAt(report_id) {QC2.6}
9. ReportRepository -> DB connector: performs query {QC2.6}
10. DB connector --> ReportRepository: rows affected
11. ReportRepository --> ReportModel: ok
12. ReportModel --> ReportController: ok
13. ReportController --> CreateReportPage: show status "Signed"

## C2.3: Create Consultant Report (File the report)

Participants: Consultant (actor), CreateReportPage (ui), ReportController (controller), ReportModel (model), ReportRepository (repository), DB connector (db)

- ref C2.1: Create Consultant Report (steps 1-2)
1. Consultant -> CreateReportPage: click "File the report"
2. CreateReportPage -> ReportController: fileReport(report_id)
3. ReportController -> ReportModel: fileReport(report_id)
4. ReportModel -> ReportRepository: updateDeliveredAt(report_id) {QC2.7}
5. ReportRepository -> DB connector: performs query {QC2.7}
6. DB connector --> ReportRepository: report_id
7. ReportRepository --> ReportModel: report_id / no row
- alt [Validation Failed]
  8. ReportModel --> ReportController: error(not written or not signed)
  9. ReportController --> CreateReportPage: show validation message
10. ReportModel --> ReportController: filed
11. ReportController --> CreateReportPage: show "Report filed"
