#!/usr/bin/env bash
set -euo pipefail

HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-18080}"
CALLBACK_PATH="${CALLBACK_PATH:-/catalog/push}"
LOG_FILE="${LOG_FILE:-/tmp/on_publish_callback.log}"

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required. Install it with: sudo apt install -y python3"
  exit 1
fi

mkdir -p "$(dirname "${LOG_FILE}")"
: > "${LOG_FILE}"

echo "Listening for catalog/on_publish callbacks"
echo "  bind: ${HOST}:${PORT}"
echo "  path: ${CALLBACK_PATH}"
echo "  log:  ${LOG_FILE}"
echo
echo "Public callback URL to use in catalog subscription:"
echo "  https://baptest.remiges.tech${CALLBACK_PATH}"
echo
echo "If you use Caddy from scripts/setup-caddy.sh, rerun it after pulling the latest repo so /catalog/push is proxied."
echo

python3 - "${HOST}" "${PORT}" "${CALLBACK_PATH}" "${LOG_FILE}" <<'PY'
import json
import sys
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer

host, port, callback_path, log_file = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4]
callback_path = callback_path.rstrip('/') or '/'

class Handler(BaseHTTPRequestHandler):
    server_version = "OnPublishConfirm/1.0"

    def log_message(self, fmt, *args):
        return

    def _write_json(self, status_code, payload):
        body = json.dumps(payload, indent=2).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if (self.path.rstrip('/') or '/') != callback_path:
            self._write_json(404, {"error": "not found", "expectedPath": callback_path})
            return
        self._write_json(200, {
            "status": "listening",
            "path": callback_path,
            "logFile": log_file,
        })

    def do_POST(self):
        normalized_path = self.path.rstrip('/') or '/'
        length = int(self.headers.get("Content-Length", "0") or 0)
        body = self.rfile.read(length) if length else b""
        now = datetime.now(timezone.utc).isoformat()

        with open(log_file, "ab") as f:
            f.write(f"\n=== {now} {self.command} {self.path} ===\n".encode("utf-8"))
            for key, value in self.headers.items():
                f.write(f"{key}: {value}\n".encode("utf-8"))
            f.write(b"\n")
            f.write(body)
            f.write(b"\n")

        print(f"\n=== {now} {self.command} {self.path} ===")
        try:
            decoded = json.loads(body.decode("utf-8") or "{}")
            print(json.dumps(decoded, indent=2))
        except Exception:
            print(body.decode("utf-8", errors="replace"))

        if normalized_path != callback_path:
            self._write_json(404, {"error": "unexpected path", "expectedPath": callback_path, "actualPath": self.path})
            return

        try:
            payload = json.loads(body.decode("utf-8") or "{}")
        except Exception as exc:
            self._write_json(400, {"error": "invalid json", "details": str(exc)})
            return

        action = payload.get("context", {}).get("action")
        results = payload.get("message", {}).get("results", [])
        summary = {
            "action": action,
            "resultCount": len(results),
            "statuses": [r.get("status") for r in results if isinstance(r, dict)],
            "catalogIds": [r.get("catalogId") for r in results if isinstance(r, dict)],
        }

        self._write_json(200, {
            "message": {"ack": {"status": "ACK"}},
            "received": summary,
        })

HTTPServer((host, port), Handler).serve_forever()
PY
