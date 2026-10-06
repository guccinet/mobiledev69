from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from django.conf import settings

from oidc_provider.models import Client, RSAKey, ResponseType


def configure_public_oidc_client(
    *,
    owner=None,
    client_id=None,
    redirect_uri=None,
):
    configured_client_id = client_id or settings.OIDC_FLUTTER_CLIENT_ID
    configured_redirect_uri = redirect_uri or settings.OIDC_REDIRECT_URI
    response_type, _ = ResponseType.objects.get_or_create(
        value="code",
        defaults={"description": "Authorization Code Flow"},
    )
    client, _ = Client.objects.get_or_create(
        client_id=configured_client_id,
        defaults={
            "name": "MoveDaily Flutter",
            "owner": owner,
            "client_type": "public",
        },
    )
    client.name = "MoveDaily Flutter"
    client.owner = owner
    client.client_type = "public"
    client.client_secret = ""
    client.jwt_alg = "RS256"
    client.reuse_consent = True
    client.require_consent = True
    client.redirect_uris = [configured_redirect_uri]
    client.post_logout_redirect_uris = [configured_redirect_uri]
    client.scope = ["openid", "profile", "email"]
    client.save()
    client.response_types.set([response_type])

    if not RSAKey.objects.exists():
        private_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=2048,
        )
        pem = private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption(),
        )
        RSAKey.objects.create(key=pem.decode("ascii"))

    return client
