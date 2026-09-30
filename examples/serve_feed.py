#!/usr/bin/env python3
"""Serve the example notification JSON to KOReader on a trusted LAN."""

from argparse import ArgumentParser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


FEED_PATH = Path(__file__).with_name("notifications.json")


class FeedHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/healthz":
            body = b"ok\n"
            content_type = "text/plain; charset=utf-8"
        elif self.path == "/notifications.json":
            try:
                body = FEED_PATH.read_bytes()
            except OSError as error:
                self.send_error(500, f"Cannot read feed: {error}")
                return
            content_type = "application/json; charset=utf-8"
        else:
            self.send_error(404, "Use /notifications.json")
            return

        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format_string, *args):
        print(f"{self.client_address[0]} - {format_string % args}")


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="0.0.0.0", help="listen address (default: all interfaces)")
    parser.add_argument("--port", type=int, default=8765)
    args = parser.parse_args()

    server = ThreadingHTTPServer((args.host, args.port), FeedHandler)
    print(f"Serving {FEED_PATH} at http://{args.host}:{args.port}/notifications.json")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("Stopping notification feed server")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
