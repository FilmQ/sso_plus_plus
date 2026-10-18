import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../controller/verification_controller.dart';
import 'json.dart';

/// O1 View Injury Application, O2 Approve and O3 Reject Injury Application.
void addVerificationRoutes(
  Router router,
  VerificationController Function(Request) verification,
) {
  const claim = '/o1/claims/<claim|[0-9]+>';

  router
    // QO1.1, QO1.2
    ..get('/o1/claims', (Request r) async => jsonOk(await verification(r).getVerificationList()))
    // QO1.3, QO1.4, QO1.5
    ..get(claim, (Request r, String id) async => jsonOk(await verification(r).getClaimDetail(int.parse(id))))
    // O1 step 6: the file of a QO1.4 row (no SQL)
    ..get('$claim/documents/<name>', (Request r, String id, String name) async {
      final file = await verification(r).openFile(int.parse(id), Uri.decodeComponent(name));
      return Response.ok(file.bytes, headers: {'content-type': file.mimeType});
    })
    // QO1.6
    ..get('/o3/rejection-reasons', (Request r) async =>
        jsonOk({'reasons': await verification(r).getRejectionReasons()}))
    // QO2.1, QN.1
    ..post('/o2/claims/<claim|[0-9]+>/confirm', (Request r, String id) async {
      final body = await readJson(r);
      return jsonOk(await verification(r)
          .confirmResult(int.parse(id), overrideReason: body['override_reason'] as String?));
    })
    // QO3.1, QO3.2, QN.2
    ..post('/o3/claims/<claim|[0-9]+>/reject', (Request r, String id) async {
      final body = await readJson(r);
      return jsonOk(await verification(r).rejectApplication(
        int.parse(id),
        reasonCode: (body['reason_code'] as String?) ?? '',
        officerMessage: body['officer_message'] as String?,
        overrideReason: body['override_reason'] as String?,
      ));
    });
}
