import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oidc/oidc.dart';
import 'package:oidc_default_store/oidc_default_store.dart';

Uri _configuredUri({
  required String configuredValue,
  required String localValue,
  required String sameOriginPath,
}) {
  if (configuredValue.isNotEmpty) return Uri.parse(configuredValue);
  if (kIsWeb && Uri.base.host != 'localhost' && Uri.base.host != '127.0.0.1') {
    return Uri.base.resolve(sameOriginPath);
  }
  return Uri.parse(localValue);
}

class OidcAuthService {
  OidcAuthService({
    Uri? issuer,
    Uri? discoveryDocumentUri,
    Uri? redirectUri,
    String? clientId,
  }) : _issuer =
           issuer ??
           _configuredUri(
             configuredValue: const String.fromEnvironment('OIDC_ISSUER_URL'),
             localValue: 'http://localhost:3000/oidc',
             sameOriginPath: '/oidc',
           ),
       _discoveryDocumentUri =
           discoveryDocumentUri ??
           _configuredUri(
             configuredValue: const String.fromEnvironment(
               'OIDC_DISCOVERY_URL',
             ),
             localValue:
                 'http://localhost:3000/oidc/.well-known/openid-configuration',
             sameOriginPath: '/oidc/.well-known/openid-configuration',
           ),
       _redirectUri =
           redirectUri ??
           _configuredUri(
             configuredValue: const String.fromEnvironment('OIDC_REDIRECT_URI'),
             localValue: 'http://localhost:50000/redirect.html',
             sameOriginPath: '/static/app/redirect.html',
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
