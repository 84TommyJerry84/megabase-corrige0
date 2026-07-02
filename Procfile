web: python3 -c "import http.server, os; http.server.HTTPServer(('0.0.0.0', int(os.environ.get('PORT', 8080))), http.server.BaseHTTPRequestHandler).serve_forever()"
worker: python main.py 69