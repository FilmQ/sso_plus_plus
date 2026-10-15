import 'repository.dart';
import 'sql/infrastructure_sql.dart';

/// Table UserAccount (infrastructure, D-003). Not in the SA report.
class UserAccountRepository extends Repository {
  UserAccountRepository(super.db);

  final String table = 'UserAccount';

  /// The account when the login name and the password are correct, else null.
  Future<Row?> findAccountByLogin(String loginName, String password) async =>
      (await query(InfrastructureSql.findAccountByLogin, {
        'login_name': loginName,
        'password': password,
      }))
          .firstOrNull;

  /// Makes the login account of a new user (U1). Gives the account_id.
  Future<int> insertUserAccount({
    required String loginName,
    required String password,
    required int insuredId,
  }) async {
    final rs = await query(InfrastructureSql.insertUserAccount, {
      'login_name': loginName,
      'password': password,
      'insured_id': insuredId,
    });
    return rs.rows.single['account_id'] as int;
  }

  /// The data of the Profile page (P-1) of a user, or null.
  Future<Row?> findUserProfile(int insuredId) async =>
      (await query(InfrastructureSql.findUserProfile, {'insured_id': insuredId})).firstOrNull;
}
