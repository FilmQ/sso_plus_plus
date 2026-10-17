import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth/session_token.dart';
import 'config.dart';
import 'controller/appointment_controller.dart';
import 'controller/insured_form_controller.dart';
import 'controller/notification_controller.dart';
import 'controller/treatment_controller.dart';
import 'db/db_connector.dart';
import 'http/auth_routes.dart';
import 'http/cors.dart';
import 'http/json.dart';
import 'http/schedule_routes.dart';
import 'http/session_middleware.dart';
import 'http/u1_routes.dart';
import 'http/u2_routes.dart';
import 'http/u3_routes.dart';
import 'http/u4_routes.dart';
import 'job/auto_cancel_job.dart';
import 'model/appointment_model.dart';
import 'model/claim_model.dart';
import 'model/insured_person_model.dart';
import 'model/notification_model.dart';
import 'model/treatment_model.dart';
import 'repository/appointment_repository.dart';
import 'repository/claim_repository.dart';
import 'repository/insured_person_repository.dart';
import 'repository/notification_repository.dart';
import 'repository/treatment_repository.dart';
import 'repository/user_account_repository.dart';
import 'storage/file_storage.dart';

/// Connects the HTTP routes to the Controllers. Repositories have no state,
/// so one of each is enough; Models and Controllers are made per request.
class App {
  App(this.config, this.db)
      : tokens = SessionToken(config.sessionSecret),
        storage = LocalFileStorage(config.storageDir);

  final Config config;
  final DBConnector db;
  final SessionToken tokens;
  final FileStorage storage;

  late final accounts = UserAccountRepository(db);
  late final people = InsuredPersonRepository(db);
  late final claims = ClaimRepository(db);
  late final notifications = NotificationRepository(db);
  late final appointments = AppointmentRepository(db);
  late final treatments = TreatmentRepository(db);

  InsuredFormController insuredFormController() => InsuredFormController(
        db: db,
        personModel: InsuredPersonModel(people),
        claimModel: ClaimModel(claims, storage),
        accounts: accounts,
        tokens: tokens,
      );

  NotificationController notificationController(Request r) =>
      NotificationController(sessionOf(r), notifications, claims);

  AppointmentController appointmentController(Request r) => AppointmentController(
      sessionOf(r), db, AppointmentModel(appointments), NotificationModel(notifications));

  /// [r] is null for [AutoCancelJob], which has no session.
  TreatmentController treatmentController([Request? r]) =>
      TreatmentController(r == null ? null : sessionOf(r), db, TreatmentModel(treatments));

  /// U4.3: QU4.3 every day (D-043).
  AutoCancelJob autoCancelJob() => AutoCancelJob(treatmentController);

  Handler get handler {
    final router = Router()
      ..get('/health', (Request _) async {
        await db.performQuery('SELECT 1');
        return jsonOk({'status': 'ok'});
      });
    addAuthRoutes(router, accounts, tokens);
    addU1Routes(router, insuredFormController);
    addU2Routes(router, notificationController);
    addU3Routes(router, appointmentController);
    addU4Routes(router, treatmentController);
    addScheduleRoutes(router, appointmentController, treatmentController);
    return const Pipeline()
        .addMiddleware(cors())
        .addMiddleware(errorMiddleware())
        .addMiddleware(sessionMiddleware(tokens))
        .addHandler(router.call);
  }
}
