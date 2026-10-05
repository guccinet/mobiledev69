import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oidc/oidc.dart';
import 'package:oidc_default_store/oidc_default_store.dart';

class OidcAuthService {
  OidcAuthService({
    Uri? issuer,
    Uri? discoveryDocumentUri,
    Uri? redirectUri,
    String? clientId,
  }) : _issuer =
           issuer ??
           Uri.parse(
             const String.fromEnvironment(
               'OIDC_ISSUER_URL',
               defaultValue: 'http://localhost:3000/oidc',
             ),
           ),
       _discoveryDocumentUri =
           discoveryDocumentUri ??
           Uri.parse(
             const String.fromEnvironment(
               'OIDC_DISCOVERY_URL',
               defaultValue:
                   'http://localhost:3000/oidc/.well-known/openid-configuration',
             ),
           ),
       _redirectUri =
           redirectUri ??
           Uri.parse(
             const String.fromEnvironment(
               'OIDC_REDIRECT_URI',
               defaultValue: 'http://localhost:50000/redirect.html',
             ),
           ),
       _clientId =
           clientId ??
           const String.fromEnvironment(
             'OIDC_CLIENT_ID',
             defaultValue: 'movedaily-flutter',
           );

  final Uri _issuer;
  final Uri _discoveryDocumentUri;
  final Uri _redirectUri;
  final String _clientId;
  OidcUserManager? _manager;

  bool get isAuthenticated => _manager?.currentUser != null;

  Future<void> initialize() async {
    if (_manager != null) return;

    final manager = OidcUserManager.lazy(
      discoveryDocumentUri: _discoveryDocumentUri,
      clientCredentials: OidcClientAuthentication.none(clientId: _clientId),
      store: OidcDefaultStore(
        secureStorageInstance: const FlutterSecureStorage(),
        webSessionManagementLocation:
            OidcDefaultStoreWebSessionManagementLocation.localStorage,
      ),
      settings: OidcUserManagerSettings(
        redirectUri: _redirectUri,
        postLogoutRedirectUri: _redirectUri,
        scope: const ['openid', 'profile', 'email'],
        expectedIssuer: _issuer,
        strictIssuerValidation: true,
        initMode: OidcInitMode.blockingValidate,
        revokeTokensOnLogout: true,
      ),
    );
    await manager.init();
    _manager = manager;
  }

  Future<void> signIn() async {
    final manager = _requireManager();
    await manager.loginAuthorizationCodeFlow();
  }

  Future<void> signOut() async {
    final manager = _requireManager();
    await manager.logout();
  }

  Future<String?> getAccessToken() async {
    final manager = _requireManager();
    return manager.getAccessToken();
  }

  OidcUserManager _requireManager() {
    final manager = _manager;
    if (manager == null) {
      throw StateError('OIDC authentication has not been initialized.');
    }
    return manager;
  }
}