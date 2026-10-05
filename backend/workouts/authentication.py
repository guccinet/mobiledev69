from django.conf import settings
from django.utils import timezone
from rest_framework.authentication import BaseAuthentication, get_authorization_header
from rest_framework.exceptions import AuthenticationFailed

from oidc_provider.lib.utils.common import get_issuer
from oidc_provider.models import Token


class OIDCAccessTokenAuthentication(BaseAuthentication):
    keyword = b"bearer"

    def authenticate(self, request):
        parts = get_authorization_header(request).split()
        if not parts or parts[0].lower() != self.keyword:
            return None
        if len(parts) != 2:
            raise AuthenticationFailed("Invalid bearer token.")

        try:
            access_token = parts[1].decode("ascii")
        except UnicodeDecodeError as exc:
            raise AuthenticationFailed("Invalid bearer token.") from exc

        try:
            token = Token.objects.select_related("user", "client").get(
                access_token=access_token
            )
        except Token.DoesNotExist as exc:
            raise AuthenticationFailed("Invalid bearer token.") from exc

        claims = token.id_token
        audience = claims.get("aud") if claims else None
        audiences = audience if isinstance(audience, list) else [audience]
        expected_client_id = settings.OIDC_FLUTTER_CLIENT_ID
        expires_at = claims.get("exp") if claims else None
        valid_expiry = (
            isinstance(expires_at, (int, float))
            and not isinstance(expires_at, bool)
            and expires_at > timezone.now().timestamp()
        )
        if (
            token.has_expired()
            or not token.user_id
            or not token.user.is_active
            or token.client.client_id != expected_client_id
            or "openid" not in token.scope
            or not claims
            or claims.get("iss") != get_issuer()
            or expected_client_id not in audiences
            or not valid_expiry
        ):
            raise AuthenticationFailed("Invalid or expired bearer token.")

        return token.user, token

    def authenticate_header(self, request):
        return "Bearer"