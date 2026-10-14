# Classes (from the class diagrams in SA report section 2.18)

Every object of every sequence diagram became a class. Four abstract base classes give the MVC layers; every repository reaches PostgreSQL through one `DBConnector`. Method names come from the sequence diagram messages; `{Qx.y}` is the SQL a repository method runs. Keep these names in the code so the code can be traced back to the report.

## Abstract base classes

### Page

Attributes: `# title: String`, `# session: UserSession`

Methods: `+ render()`, `+ navigate(page: Page)`, `+ showMessage(text: String)`, `+ showConfirmationCard()`, `+ closeConfirmationCard()`

### Controller

Attributes: `# session: UserSession`

Methods: `# authorize(role: String): boolean`, `# handleError(e: Exception)`

### Model

Attributes: `# errors: List<String>`

Methods: `+ isValid(): boolean`

### Repository

Attributes: `# db: DBConnector`

Methods: `# query(sql: String, params: Map): ResultSet`, `# execute(sql: String, params: Map): int`

Relationships: Page uses Controller; Controller 1 -> 1..* Model; Model 1 -> 1..* Repository; Repository 1..* aggregates 1 DBConnector.

## Page (boundary)

### AppointmentPage

Used in: U3.1, U3.2, U3.3

Attributes: `- claimId: int`, `- appointment: Appointment`, `- freeSlots: List<Time>`

Methods:

- `+ open(claim_id)`
- `+ clickConfirmAppointment()`
- `+ clickRequestAnotherDate()`
- `+ showDatePicker()`
- `+ selectDate(slot_date)`
- `+ clickCancel()`
- `+ backToAppointmentPage()`
- `+ pickTimeAndConfirm(slot_time)`
- `+ clickCannotAttend()`
- `+ showCancelWarning()`
- `+ clickGoBack()`
- `+ clickConfirmCancel()`

### ConsultationReportPage

Used in: O6

Attributes: `- reportId: int`, `- report: ReportDetail`

Methods:

- `+ open(report_id)`
- `+ clickView()`
- `+ showFile(file)`
- `+ showTextField(header, body)`

### CreateReportPage

Used in: C2.1, C2.2, C2.3

Attributes: `- appointmentId: int`, `- reportId: int`, `- reportContent: String`, `- attachment: File`, `- signature: Image`

Methods:

- `+ clickCreateReport()`
- `+ selectConsultation(appointment_id)`
- `+ clickAmendDraft()`
- `+ enableDraftEditing()`
- `+ clickAttach()`
- `+ openFileExplorer()`
- `+ chooseFile(file)`
- `+ showFileAttached()`
- `+ finishDraft(report_content)`
- `+ clickSign()`
- `+ showSignatureCard()`
- `+ clickDelete()`
- `+ clearSignature()`
- `+ confirmSignature(signature)`
- `+ clickFileReport()`

### EligibilityDecisionPage

Used in: O1, O2, O3

Attributes: `- claimId: int`, `- result: String`, `- reasonCode: String`, `- officerMessage: String`

Methods:

- `+ open(claim_id)`
- `+ clickView(document)`
- `+ openFile(file_uri)`
- `+ confirmResult(result)`
- `+ showConfirmationCard()`
- `+ clickCancel()`
- `+ closeConfirmationCard()`
- `+ clickConfirm()`

### HomePage

Used in: U2

Attributes: `- insuredId: int`, `- unreadCount: int`

Methods:

- `+ open()`
- `+ clickBellIcon()`
- `+ selectNotification(notification_id)`

### InjuryFormPage

Used in: U1

Attributes: `- form: InjuryForm`, `- files: List<File>`, `- errors: List<String>`

Methods:

- `+ redirect()`
- `+ submitForms(form, files)`

### NotificationPage

Used in: U3.1

Attributes: `- notifications: List<Notification>`

Methods:

- `+ clickNotification(claim_id)`

### RegisterPage

Used in: U1

Attributes: `- nationalId: String`, `- phoneNo: String`

Methods:

- `+ clickRegister()`

### ReportListPage

Used in: O6

Attributes: `- reports: List<ReportSummary>`

Methods:

- `+ clickConsultationReports()`
- `+ selectReport(report_id)`

### ScheduleAppointmentPage

Used in: O4

Attributes: `- claimId: int`, `- slotDate: Date`, `- selectedSlot: Slot`

Methods:

- `+ clickScheduling()`
- `+ selectDate(slot_date)`
- `+ offerSlot(slot)`
- `+ showConfirmationCard()`
- `+ clickCancel()`
- `+ closeConfirmationCard()`
- `+ clickConfirm()`

### SchedulePage

Used in: U5, U6, C1

Attributes: `- appointments: List<Appointment>`, `- treatments: List<Treatment>`, `- activeTab: String`

Methods:

- `+ clickSchedulePage()`

### ScheduleTreatmentPage

Used in: O5.1, O5.2

Attributes: `- claimId: int`, `- reportId: int`, `- facility: String`, `- selectedSlot: Slot`

Methods:

- `+ clickTreatment()`
- `+ enterDetails(type, duration, facility)`
- `+ bookSlot(slot)`
- `+ showConfirmationCard()`
- `+ clickCancel()`
- `+ closeConfirmationCard()`
- `+ clickConfirm()`
- `+ clickNoTreatmentRequired()`

### TreatmentPage

Used in: U4.1, U4.2

Attributes: `- treatment: Treatment`, `- availableDates: List<Date>`

Methods:

- `+ clickAccept()`
- `+ clickRequestAnotherDate()`
- `+ showAvailableDates()`
- `+ selectDate(new_date)`

### VerificationPage

Used in: O1

Attributes: `- claims: List<ClaimSummary>`, `- statusCounts: Map<String, int>`

Methods:

- `+ clickVerification()`
- `+ clickOpen(claim_id)`

## Controller

### AppointmentController

Used in: U3.1, U3.2, U3.3, U5, O4, C1

Attributes: `- appointmentModel: AppointmentModel`, `- notificationModel: NotificationModel`

Methods:

- `+ getAppointment(claim_id, insured_id)`
- `+ confirmAppointment(appointment_id)`
- `+ getFreeSlots(consultant_id, slot_date)`
- `+ reschedule(appointment_id, new_date, new_time)`
- `+ cancelAppointment(appointment_id)`
- `+ getAppointmentSchedule(insured_id)`
- `+ getClaimsToSchedule()`
- `+ getAvailability(slot_date)`
- `+ offerAppointment(claim_id, consultant_id, slot)`
- `+ getSchedule(consultant_id)`

### InsuredFormController

Used in: U1

Attributes: `- personModel: InsuredPersonModel`, `- claimModel: ClaimModel`

Methods:

- `+ submitInjuryForm(form, files)`

### NotificationController

Used in: U2

Attributes: `- repository: NotificationRepository`

Methods:

- `+ checkUnreadNotifications(insured_id)`
- `+ getNotifications(insured_id)`
- `+ markAsRead(notification_id)`

### PopUpController

Used in: U2

Attributes: `- items: List<Notification>`

Methods:

- `+ showPopup(list)`

### ReportController

Used in: O6, C2.1, C2.2, C2.3

Attributes: `- reportModel: ReportModel`

Methods:

- `+ getReportList()`
- `+ getReport(report_id)`
- `+ viewReport(report_id)`
- `+ getPendingConsultations(consultant_id)`
- `+ openReport(appointment_id)`
- `+ saveDraft(session_id, report_content)`
- `+ signReport(report_id)`
- `+ fileReport(report_id)`

### TreatmentController

Used in: U4.1, U4.2, U4.3, U6, O5.1, O5.2

Attributes: `- treatmentModel: TreatmentModel`, `- claimModel: ClaimModel`, `- notificationModel: NotificationModel`

Methods:

- `+ acceptTreatment(treatment_id, claim_id)`
- `+ changeDate(treatment_id, claim_id, new_date)`
- `+ cancelUnacceptedTreatments()`
- `+ getTreatmentSchedule(insured_id)`
- `+ getClaimsForTreatment()`
- `+ getAvailableTimes(facility, dates)`
- `+ bookTreatment(claim_id, report_id, details)`
- `+ closeWithoutTreatment(claim_id)`

### VerificationController

Used in: O1, O2, O3

Attributes: `- claimModel: ClaimModel`, `- notificationModel: NotificationModel`

Methods:

- `+ getVerificationList()`
- `+ getClaimDetail(claim_id)`
- `+ confirmResult(claim_id, result)`
- `+ rejectApplication(claim_id, result)`

## Model (entity)

### AppointmentModel

Used in: U3.1, U3.2, U3.3, U5, O4, C1

Attributes: `- appointmentId: int`, `- claimId: int`, `- consultantId: int`, `- scheduleDate: Date`, `- scheduleTime: Time`, `- appointmentStatus: String`

Methods:

- `+ getAppointmentDetail(claim_id, insured_id)`
- `+ confirm(appointment_id)`
- `+ getFreeSlots(consultant_id, slot_date)`
- `+ reschedule(appointment_id, new_date, new_time)`
- `+ cancel(appointment_id)`
- `+ getUpcomingAppointments(insured_id)`
- `+ getClaimsToSchedule()`
- `+ getConsultantSlots(slot_date)`
- `+ createAppointment(claim_id, consultant_id, slot)`
- `+ getConsultantSchedule(consultant_id)`

### ClaimModel

Used in: U1, O1, O2, O3, O5.2

Attributes: `- claimId: int`, `- claimNo: String`, `- insuredId: int`, `- injuryDatetime: DateTime`, `- claimStatus: String`

Methods:

- `+ createClaim(insured_id, form, files)`
- `+ getPendingApplications()`
- `+ getClaimDetail(claim_id)`
- `+ confirmResult(claim_id, result)`
- `+ rejectApplication(claim_id, result)`
- `+ closeWithoutTreatment(claim_id)`

### InsuredPersonModel

Used in: U1

Attributes: `- insuredId: int`, `- nationalId: String`, `- firstName: String`, `- lastName: String`, `- dateOfBirth: Date`, `- phoneNo: String`

Methods:

- `+ register(form)`
- `+ validateFields(form)`

### NotificationModel

Used in: U3.1, U3.2, U3.3, O2, O3, O4, O5.1, O5.2

Attributes: `- notificationId: int`, `- claimId: int`, `- subject: String`, `- body: String`, `- sentAt: DateTime`

Methods:

- `+ markRead(notification_id)`
- `+ notifyUser(claim_id, subject, body)`
- `+ notifyRejection(claim_id)`
- `+ notifyUserAndConsultant(appointment_id)`
- `+ notifyNoTreatment(claim_id)`

### ReportModel

Used in: O6, C2.1, C2.2, C2.3

Attributes: `- reportId: int`, `- sessionId: int`, `- versionNo: int`, `- reportContent: String`, `- signedAt: DateTime`, `- deliveredAt: DateTime`

Methods:

- `+ getReportList()`
- `+ getReport(report_id)`
- `+ markViewed(report_id)`
- `+ getPendingConsultations(consultant_id)`
- `+ openReport(appointment_id)`
- `+ saveDraft(session_id, report_content)`
- `+ signReport(report_id)`
- `+ fileReport(report_id)`

### TreatmentModel

Used in: U4.1, U4.2, U4.3, U6, O5.1

Attributes: `- treatmentId: int`, `- claimId: int`, `- facilityName: String`, `- scheduledDate: Date`, `- treatmentStatus: String`

Methods:

- `+ accept(treatment_id, claim_id)`
- `+ changeDate(treatment_id, claim_id, new_date)`
- `+ cancelExpired()`
- `+ getUpcomingTreatments(insured_id)`
- `+ getClaimsForTreatment()`
- `+ getFacilitySlots(facility, dates)`
- `+ bookTreatment(claim_id, report_id, details)`

## Repository

### AppointmentRepository

Used in: U3.1, U3.2, U3.3, U5, O4, C1

Attributes: `- table: String = "Appointment"`

Methods:

- `+ findLatestAppointment(claim_id, insured_id) {Q3.2}`
- `+ confirmAppointment(appointment_id) {Q3.3}`
- `+ findFreeSlots(consultant_id, slot_date) {Q3.4}`
- `+ rescheduleAppointment(appointment_id, new_date, new_time) {Q3.5}`
- `+ cancelAppointment(appointment_id) {Q3.6}`
- `+ findUpcomingAppointments(insured_id) {QU5.1}`
- `+ findClaimsToSchedule() {QO4.1}`
- `+ findConsultantSlots(slot_date, officer_id) {QO4.2}`
- `+ insertAppointment(appointment) {QO4.3}`
- `+ findConfirmedAppointments(consultant_id) {QC1.1}`

### ClaimRepository

Used in: U1, O1, O2, O3, O5.2

Attributes: `- table: String = "InjuryClaim"`

Methods:

- `+ insertClaim(insured_id, injury) {Q1.6}`
- `+ assignClaimNo(claim_id) {Q1.7}`
- `+ insertDocument(claim_id, file) {Q1.8}`
- `+ insertAutoEligibility(claim_id, coverage_id) {Q1.9}`
- `+ insertFirstStatus(claim_id) {Q1.10}`
- `+ findPendingClaims() {QO1.1}`
- `+ countByStatus() {QO1.2}`
- `+ findClaimSummary(claim_id) {QO1.3}`
- `+ findDocuments(claim_id) {QO1.4}`
- `+ findAutoEligibility(claim_id) {QO1.5}`
- `+ saveResult(claim_id, result) {QO2.1, QO3.1}`
- `+ insertRejection(claim_id, reason_code, message) {QO3.2}`
- `+ updateNoTreatment(claim_id) {QO5.4}`
- `+ findRejectionReasons() {QO1.6}`

### InsuredPersonRepository

Used in: U1

Attributes: `- table: String = "InsuredPerson"`

Methods:

- `+ findInSSORegister(national_id) {Q1.1}`
- `+ countByNationalId(national_id) {Q1.2}`
- `+ insertInsuredPerson(form) {Q1.3}`
- `+ upsertEmployer(employer) {Q1.4}`
- `+ insertCoverage(insured_id, employer_id) {Q1.5}`

### NotificationRepository

Used in: U2, U3.1, U3.2, U3.3, O2, O3, O4, O5.1, O5.2

Attributes: `- table: String = "Notification"`

Methods:

- `+ countUnread(insured_id)`
- `+ findNotifications(insured_id)`
- `+ markAsRead(notification_id, insured_id)`
- `+ markRead(notification_id, insured_id) {Q3.7}`
- `+ insertNotification(claim_id, subject, body) {QN.1}`
- `+ insertRejectionNotice(claim_id) {QN.2}`
- `+ insertAppointmentNotices(appointment_id) {QN.3}`
- `+ insertNoTreatmentNotice(claim_id) {QN.4}`

### ReportRepository

Used in: O6, C2.1, C2.2, C2.3

Attributes: `- table: String = "ConsultationReport"`

Methods:

- `+ findFiledReports() {QO6.1}`
- `+ findReport(report_id) {QO6.2}`
- `+ updateReadAt(report_id) {QO6.3}`
- `+ findConsultationsAwaitingReport(consultant_id) {QC2.1}`
- `+ insertSessionIfMissing(appointment_id) {QC2.2}`
- `+ findReportPage(appointment_id) {QC2.3}`
- `+ updateDraft(report_id, report_content) {QC2.5}`
- `+ insertDraft(session_id, report_content) {QC2.4}`
- `+ updateSignedAt(report_id) {QC2.6}`
- `+ updateDeliveredAt(report_id) {QC2.7}`

### TreatmentRepository

Used in: U4.1, U4.2, U4.3, U6, O5.1

Attributes: `- table: String = "Treatment"`

Methods:

- `+ updateStatusAccepted(treatment_id, claim_id) {QU4.1}`
- `+ updateScheduledDate(treatment_id, claim_id, new_date) {QU4.2}`
- `+ cancelExpiredAndNotifyUser() {QU4.3}`
- `+ findUpcomingTreatments(insured_id) {Q6.1}`
- `+ findClaimsWithFiledReport() {QO5.1}`
- `+ findFacilitySlots(facility, dates, officer_id) {QO5.2}`
- `+ insertTreatment(treatment) {QO5.3}`

## DB connector

### DBConnector

Used in: U1, U2, U3.1, U3.2, U3.3, U4.1, U4.2, U4.3, U5, U6, O1, O2, O3, O4, O5.1, O5.2, O6, C1, C2.1, C2.2, C2.3

Attributes: `- url: String`, `- username: String`, `- pool: ConnectionPool`

Methods:

- `+ performQuery(sql, params)`
- `+ connect()`
- `+ beginTransaction()`
- `+ commit()`
- `+ rollback()`
- `+ close()`

## Scheduled job

### AutoCancelJob

Used in: U4.3

Attributes: `- cronExpression: String`, `- lastRunAt: DateTime`

Methods:

- `+ onDeadlineReached()`
