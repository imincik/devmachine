"""Simple web service counting visits in PostgreSQL database."""

import os
from http.server import BaseHTTPRequestHandler, HTTPServer

import psycopg

PG_URI = os.environ.get("PG_URI", "postgres://app@localhost/app")
APP_HOST = os.environ.get("APP_HOST", "127.0.0.1")
APP_PORT = int(os.environ.get("APP_PORT", "8000"))


def init_db():
    with psycopg.connect(PG_URI) as conn:
        conn.execute(
            "CREATE TABLE IF NOT EXISTS visits ("
            " id serial PRIMARY KEY,"
            " visited_at timestamptz NOT NULL DEFAULT now())"
        )


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/":
            self.send_error(404)
            return

        with psycopg.connect(PG_URI) as conn:
            conn.execute("INSERT INTO visits DEFAULT VALUES")
            (count,) = conn.execute("SELECT count(*) FROM visits").fetchone()

        body = f"Hello from devmachine, visit number {count}\n".encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    init_db()
    server = HTTPServer((APP_HOST, APP_PORT), Handler)
    print(f"Serving on http://{APP_HOST}:{APP_PORT}")
    server.serve_forever()
