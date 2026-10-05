"""SITS demo application: one page and a health check.

The page shows the environment, the package version, the signed-in user, the result of the
Key Vault access check, and the application state. Secret values are never shown or logged.
"""

import html
import json
import os
import sys
import time
from socketserver import ThreadingMixIn
from wsgiref.simple_server import WSGIServer, make_server

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Python dependencies are part of the package (built on the build agent), App Service does not build it
sys.path.insert(0, os.path.join(BASE_DIR, "packages"))


def load_version():
    try:
        with open(os.path.join(BASE_DIR, "version.json"), encoding="utf-8") as file:
            return json.load(file)
    except (OSError, ValueError):
        return {"version": "local", "commit": "unknown"}


def check_key_vault():
    """Reads secret metadata from the application vault with the application identity (SDK)."""
    vault_uri = os.environ.get("KEY_VAULT_URI")
    if not vault_uri:
        return False, "KEY_VAULT_URI is not set"

    try:
        from azure.identity import DefaultAzureCredential
        from azure.keyvault.secrets import SecretClient
    except ImportError as error:
        return False, f"Azure SDK is not available: {error.name}"

    started = time.monotonic()
    try:
        client = SecretClient(
            vault_url=vault_uri,
            credential=DefaultAzureCredential(exclude_interactive_browser_credential=True),
            connection_timeout=5,
            read_timeout=5,
        )
        count = sum(1 for _ in client.list_properties_of_secrets())
    except Exception as error:  # the type and message help diagnose DNS, network, and role problems
        return False, f"{type(error).__name__}: {str(error).splitlines()[0][:200]}"

    elapsed = int((time.monotonic() - started) * 1000)
    return True, f"access granted, {count} secret(s) visible, {elapsed} ms"


def respond(start_response, status, content_type, body):
    data = body.encode("utf-8")
    start_response(
        status,
        [
            ("Content-Type", content_type),
            ("Content-Length", str(len(data))),
            ("Cache-Control", "no-store"),
        ],
    )
    return [data]


def health(environ, start_response):
    vault_ok, vault_detail = check_key_vault()
    body = json.dumps(
        {
            "status": "healthy" if vault_ok else "unhealthy",
            "environment": os.environ.get("APP_ENVIRONMENT", "unknown"),
            "version": load_version().get("version"),
            "keyVault": {"ok": vault_ok, "detail": vault_detail},
        }
    )
    status = "200 OK" if vault_ok else "503 Service Unavailable"
    return respond(start_response, status, "application/json", body)


def page(environ, start_response):
    version = load_version()
    vault_ok, vault_detail = check_key_vault()
    user = environ.get("HTTP_X_MS_CLIENT_PRINCIPAL_NAME", "not signed in")
    host = environ.get("HTTP_X_FORWARDED_HOST", environ.get("HTTP_HOST", ""))
    rows = [
        ("Environment", os.environ.get("APP_ENVIRONMENT", "unknown")),
        ("Package version", version.get("version", "unknown")),
        ("Source commit", version.get("commit", "unknown")),
        ("Signed-in user", user),
        ("Requested host", host),
        ("Key Vault check", ("OK: " if vault_ok else "FAILED: ") + vault_detail),
        ("Application state", "running"),
    ]
    table = "\n".join(
        f"<tr><th>{html.escape(name)}</th><td>{html.escape(str(value))}</td></tr>" for name, value in rows
    )
    body = f"""<!DOCTYPE html>
<html lang="en">
<head><meta charset="utf-8"><title>SITS demo application</title>
<style>body{{font-family:sans-serif;margin:2rem}}th{{text-align:left;padding-right:1rem}}</style></head>
<body><h1>SITS demo application</h1><table>
{table}
</table></body></html>"""
    return respond(start_response, "200 OK", "text/html; charset=utf-8", body)


def app(environ, start_response):
    path = environ.get("PATH_INFO", "/")
    if path == "/health":
        return health(environ, start_response)
    if path == "/":
        return page(environ, start_response)
    return respond(start_response, "404 Not Found", "text/plain", "Not found")


class ThreadingWSGIServer(ThreadingMixIn, WSGIServer):
    daemon_threads = True


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8000"))
    with make_server("0.0.0.0", port, app, server_class=ThreadingWSGIServer) as server:
        print(f"Listening on port {port}", flush=True)
        server.serve_forever()
