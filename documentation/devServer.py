# Python-Script to start an HTTPs Server for Development
from http.server import SimpleHTTPRequestHandler
import time
import os
import shutil

PORT = 8000

def embeds():
    if os.path.isdir("./embeds/docs"):
        if len(os.listdir("./embeds/docs")) > 0: 
            shutil.rmtree("./embeds/docs")
        else:
            os.rmdir("./embeds/docs")
    shutil.copytree("../docs/build", "./embeds/docs")

class NoCacheHTTPRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '-1')
        SimpleHTTPRequestHandler.end_headers(self)

if __name__ == '__main__':
    embeds()
    from http.server import HTTPServer
    server_address = ('', PORT)
    httpd = HTTPServer(server_address, NoCacheHTTPRequestHandler)
    print(f"Development Server running at http://localhost:{PORT}/")
    httpd.serve_forever()
