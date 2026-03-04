#!/usr/bin/env python3
"""
Tarkov RPG Web 版本本地测试服务器
使用: python serve_web.py [port]
默认端口: 8000
"""

import http.server
import socketserver
import sys
import os

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
WEB_DIR = "web_export"

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # 添加必要的 CORS 和 COOP/COEP 头，用于 Godot Web 导出
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Cross-Origin-Resource-Policy', 'cross-origin')
        super().end_headers()
    
    def guess_type(self, path):
        # 确保 .wasm 文件使用正确的 MIME 类型
        if path.endswith('.wasm'):
            return 'application/wasm'
        if path.endswith('.pck'):
            return 'application/octet-stream'
        return super().guess_type(path)

def main():
    # 切换到 web 导出目录
    if os.path.exists(WEB_DIR):
        os.chdir(WEB_DIR)
        print(f"Serving from: {os.path.abspath('.')}")
    else:
        print(f"Warning: {WEB_DIR} directory not found. Serving from current directory.")
    
    with socketserver.TCPServer(("", PORT), MyHTTPRequestHandler) as httpd:
        print(f"Server running at: http://localhost:{PORT}/")
        print("Press Ctrl+C to stop")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServer stopped.")

if __name__ == "__main__":
    main()
