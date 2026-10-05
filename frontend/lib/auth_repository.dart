import 'data_result.dart';
import 'oidc_auth_service.dart';

class AuthRepository {
  const AuthRepository(this._service);

  final OidcAuthService _service;

  bool get isAuthenticated => _service.isAuthenticated;

  Future<DataResult<bool>> initialize() async {
    try {
      await _service.initialize();
      return DataSuccess(_service.isAuthenticated);
    } on Exception catch (error, stackTrace) {
      return DataFailure(error, stackTrace);
    }
  }

  Future<DataResult<void>> signIn() async {
    try {
      await _service.signIn();
      return const DataSuccess(null);
    } on Exception catch (error, stackTrace) {
      return DataFailure(error, stackTrace);
    }
  }

  Future<DataResult<void>> signOut() async {
    try {
      await _service.signOut();
      return const DataSuccess(null);
    } on Exception catch (error, stackTrace) {
      return DataFailure(error, stackTrace);
    }
  }
}