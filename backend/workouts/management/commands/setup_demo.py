import getpass
import os
import sys

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError

from oidc_provider.models import Client, RSAKey, ResponseType


class Command(BaseCommand):
    help = "Create or update the demo user and public OIDC PKCE client."

    def add_arguments(self, parser):
        parser.add_argument(
            "--email",
            default=os.environ.get("DEMO_USER_EMAIL", "demo@example.com"),
        )
        parser.add_argument("--client-id", default=settings.OIDC_FLUTTER_CLIENT_ID)
        parser.add_argument("--redirect-uri", default=settings.OIDC_REDIRECT_URI)

    def handle(self, *args, **options):
        email = options["email"].strip().lower()
        User = get_user_model()
        user = User.objects.filter(username=email).first()
        password = os.environ.get("DEMO_USER_PASSWORD")
        if user is None and not password and sys.stdin.isatty():
            password = getpass.getpass("Set the demo account password: ")
            if not password:
                raise CommandError("A non-empty demo account password is required.")
        if user is None and not password:
            raise CommandError(
                "Set DEMO_USER_PASSWORD or run this command interactively to create "
                "the demo account."
            )

        if user is None:
            user = User.objects.create_user(username=email, email=email)
        elif user.email != email:
            user.email = email
            user.save(update_fields=["email"])

        if password:
            user.set_password(password)
            user.save(update_fields=["password"])

        response_type, _ = ResponseType.objects.get_or_create(
            value="code",
            defaults={"description": "Authorization Code Flow"},
        )
        client, _ = Client.objects.get_or_create(
            client_id=options["client_id"],
            defaults={
                "name": "MoveDaily Flutter",
                "owner": user,
                "client_type": "public",
                "jwt_alg": "RS256",
                "reuse_consent": True,
                "require_consent": True,
            },
        )
        client.name = "MoveDaily Flutter"
        client.owner = user
        client.client_type = "public"
        client.client_secret = ""
        client.jwt_alg = "RS256"
        client.reuse_consent = True
        client.require_consent = True
        client.redirect_uris = [options["redirect_uri"]]
        client.post_logout_redirect_uris = [options["redirect_uri"]]
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

        self.stdout.write(
            self.style.SUCCESS(
                "Demo OIDC setup is ready. "
                f"User: {email}; client: {options['client_id']}; "
                f"redirect URI: {options['redirect_uri']}."
            )
        )