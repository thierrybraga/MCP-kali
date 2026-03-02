import http.server
import socketserver
import threading
import subprocess
import time
import os
import sys
import json
import requests

# Configuration
MOCK_GATEWAY_PORT = 9999
MCP_SERVER_PORT = 3001
GATEWAY_URL = f"http://localhost:{MOCK_GATEWAY_PORT}"
REGISTER_ENDPOINT = "/api/mcp/register"
HEARTBEAT_ENDPOINT = "/api/mcp/heartbeat"

events = {
    "register": False,
    "heartbeat": False
}

class MockGatewayHandler(http.server.SimpleHTTPRequestHandler):
    def do_POST(self):
        if self.path == REGISTER_ENDPOINT:
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data)
            print(f"\n[MockGateway] Received REGISTER: {data}")
            
            if data.get("name") == "kali-mcp" and "url" in data:
                events["register"] = True
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "registered", "id": "mock-id"}).encode())
            else:
                self.send_response(400)
                self.end_headers()
                
        elif self.path == HEARTBEAT_ENDPOINT:
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data)
            print(f"\n[MockGateway] Received HEARTBEAT: {data}")
            
            if data.get("status") == "healthy":
                events["heartbeat"] = True
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "ok"}).encode())
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        return # Silence logs

def start_mock_gateway():
    with socketserver.TCPServer(("", MOCK_GATEWAY_PORT), MockGatewayHandler) as httpd:
        print(f"[Test] Mock Gateway running on port {MOCK_GATEWAY_PORT}")
        httpd.serve_forever()

def main():
    # 1. Start Mock Gateway
    gateway_thread = threading.Thread(target=start_mock_gateway, daemon=True)
    gateway_thread.start()
    
    # 2. Start MCP Server with Gateway Config
    env = os.environ.copy()
    env["OPENCLAW_GATEWAY_URL"] = GATEWAY_URL
    env["MCP_PORT"] = str(MCP_SERVER_PORT)
    env["OPENCLAW_HEARTBEAT_INTERVAL_MS"] = "1000" # Fast heartbeat for testing
    
    print(f"[Test] Starting MCP Server on port {MCP_SERVER_PORT}...")
    server_process = subprocess.Popen(
        ["node", "server.js"],
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )

    try:
        # 3. Wait for events
        print("[Test] Waiting for registration and heartbeat...")
        timeout = 15
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            if events["register"] and events["heartbeat"]:
                break
            time.sleep(1)
            
            # Check if server died
            if server_process.poll() is not None:
                print("[Test] MCP Server died unexpectedly!")
                print(server_process.stdout.read())
                print(server_process.stderr.read())
                sys.exit(1)

        # 4. Verify results
        if events["register"]:
            print("✅ Registration SUCCESS")
        else:
            print("❌ Registration FAILED")

        if events["heartbeat"]:
            print("✅ Heartbeat SUCCESS")
        else:
            print("❌ Heartbeat FAILED")

        if events["register"] and events["heartbeat"]:
            print("\n[Test] Integration Verification PASSED")
            sys.exit(0)
        else:
            print("\n[Test] Integration Verification FAILED")
            sys.exit(1)

    finally:
        print("[Test] Cleaning up...")
        server_process.terminate()
        server_process.wait()

if __name__ == "__main__":
    main()
