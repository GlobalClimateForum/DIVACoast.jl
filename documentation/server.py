from http.server import SimpleHTTPRequestHandler
import time

class NoCacheHTTPRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '-1')
        SimpleHTTPRequestHandler.end_headers(self)

if __name__ == '__main__':
    from http.server import HTTPServer
    server_address = ('', 4000)
    httpd = HTTPServer(server_address, NoCacheHTTPRequestHandler)
    print("Server running at http://localhost:8000/")
    httpd.serve_forever()