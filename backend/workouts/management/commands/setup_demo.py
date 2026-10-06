import getpass
import os
import sys

from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError

from workouts.oidc_setup import configure_public_oidc_client


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

        configure_public_oidc_client(
            owner=user,
            client_id=options["client_id"],
            redirect_uri=options["redirect_uri"],
        )

        self.stdout.write(
            self.style.SUCCESS(
                "Demo OIDC setup is ready. "
                f"User: {email}; client: {options['client_id']}; "
                f"redirect URI: {options['redirect_uri']}."
            )
        )