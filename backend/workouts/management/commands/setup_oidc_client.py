from django.conf import settings
from django.core.management.base import BaseCommand

from workouts.oidc_setup import configure_public_oidc_client


class Command(BaseCommand):
    help = "Create or update the public Flutter OIDC client without a demo account."

    def handle(self, *args, **options):
        configure_public_oidc_client()
        self.stdout.write(
            self.style.SUCCESS(
                f"Public OIDC client {settings.OIDC_FLUTTER_CLIENT_ID} is ready "
                f"for {settings.OIDC_REDIRECT_URI}."
            )
        )
