import re

from django.http import HttpResponseBadRequest

from oidc_provider.models import Client


PKCE_S256_CHALLENGE = re.compile(r"^[A-Za-z0-9_-]{43}$")


class RequirePublicClientPKCE:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if request.path.rstrip("/") == "/oidc/authorize":
            params = request.GET if request.method == "GET" else request.POST
            client_id = params.get("client_id")
            if (
                client_id
                and params.get("response_type") == "code"
                and Client.objects.filter(
                    client_id=client_id,
                    client_type="public",
                ).exists()
                and (
                    params.get("code_challenge_method") != "S256"
                    or not PKCE_S256_CHALLENGE.fullmatch(
                        params.get("code_challenge", "")
                    )
                )
            ):
                return HttpResponseBadRequest(
                    "Public authorization-code clients must use PKCE S256."
                )
        return self.get_response(request)
