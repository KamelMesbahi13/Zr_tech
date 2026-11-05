import http.server
import socketserver
import os
import sys
import webbrowser

PORT = 8080
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))

candidates = [
    os.path.join(CURRENT_DIR, "zr_tech_app", "build", "web"),
    os.path.join(CURRENT_DIR, "Zr_tech-main", "zr_tech_app", "build", "web"),
    os.path.join(CURRENT_DIR, "..", "Zr_tech-main", "zr_tech_app", "build", "web"),
]

DIRECTORY = None
for c in candidates:
    if os.path.exists(c):
        DIRECTORY = os.path.abspath(c)
        break

class SPAHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_GET(self):
        local_path = self.translate_path(self.path)
        if not os.path.exists(local_path) and not any(self.path.endswith(ext) for ext in [
            '.js', '.css', '.png', '.jpg', '.jpeg', '.svg', '.json', '.wasm', '.ttf', '.otf', '.ico'
        ]):
            self.path = '/index.html'
        return super().do_GET()

if __name__ == '__main__':
    if not DIRECTORY:
        print(f"Error: Build directory not found in: {candidates}")
        print("Please run build_web.bat first to build the Flutter web app.")
        sys.exit(1)

    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", PORT), SPAHandler) as httpd:
        url = f"http://localhost:{PORT}"
        print("=" * 55)
        print(f"  ZR Tech App is running at: {url}")
        print(f"  Directory: {DIRECTORY}")
        print(f"  Press Ctrl+C to stop the server.")
        print("=" * 55)
        webbrowser.open(url)
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServer stopped.")
