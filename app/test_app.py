import json
import os
import unittest
from unittest import mock

import app


def call(path, headers=None):
    captured = {}

    def start_response(status, response_headers):
        captured["status"] = status
        captured["headers"] = dict(response_headers)

    environ = {"PATH_INFO": path}
    environ.update(headers or {})
    body = b"".join(app.app(environ, start_response)).decode("utf-8")
    return captured["status"], captured["headers"], body


class AppTests(unittest.TestCase):
    def test_unknown_path_returns_404(self):
        status, _, _ = call("/missing")
        self.assertTrue(status.startswith("404"))

    @mock.patch.dict(os.environ, {"APP_ENVIRONMENT": "test"}, clear=True)
    def test_health_without_vault_is_unhealthy(self):
        status, headers, body = call("/health")
        self.assertTrue(status.startswith("503"))
        self.assertEqual(headers["Content-Type"], "application/json")
        self.assertEqual(json.loads(body)["status"], "unhealthy")

    @mock.patch("app.check_key_vault", return_value=(True, "access granted"))
    def test_health_with_vault_is_healthy(self, _):
        status, _, body = call("/health")
        self.assertTrue(status.startswith("200"))
        self.assertTrue(json.loads(body)["keyVault"]["ok"])

    @mock.patch("app.check_key_vault", return_value=(True, "access granted"))
    def test_page_escapes_user_name(self, _):
        status, _, body = call("/", {"HTTP_X_MS_CLIENT_PRINCIPAL_NAME": "<script>"})
        self.assertTrue(status.startswith("200"))
        self.assertIn("&lt;script&gt;", body)
        self.assertNotIn("<script>", body)


if __name__ == "__main__":
    unittest.main()
