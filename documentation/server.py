# Python-Script to start an HTTPs Server for Development
from http.server import SimpleHTTPRequestHandler
import time
import os
import shutil

PORT = 8000

def provide_dev_templates():
    if os.path.isdir("./templates/docs"):
        if len(os.listdir("./templates/docs")) > 0: 
            shutil.rmtree("./templates/docs")
        else:
            os.rmdir("./templates/docs")
    shutil.copytree("../docs/build", "./templates/docs")

class NoCacheHTTPRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '-1')
        SimpleHTTPRequestHandler.end_headers(self)

if __name__ == '__main__':
    from http.server import HTTPServer
    server_address = ('', PORT)
    httpd = HTTPServer(server_address, NoCacheHTTPRequestHandler)
    print(f"Development Server running at http://localhost:{PORT}/")
    provide_dev_templates()
    httpd.serve_forever()
