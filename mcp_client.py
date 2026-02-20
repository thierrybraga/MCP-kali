#!/usr/bin/env python3
"""
MCP Server API Client
Author: Thierry Braga
Description: Python client for interacting with Kali MCP Server
"""

import requests
import json
from typing import Dict, List, Optional

class MCPClient:
    """Client for Kali MCP Server API"""
    
    def __init__(self, base_url: str = "http://localhost:3000"):
        """
        Initialize MCP Client
        
        Args:
            base_url: Base URL of the MCP server
        """
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()
    
    def _post(self, endpoint: str, data: Dict, timeout: int = 300) -> Dict:
        """
        Make POST request to API
        
        Args:
            endpoint: API endpoint
            data: Request data
            timeout: Request timeout in seconds
        
        Returns:
            Response JSON
        """
        url = f"{self.base_url}{endpoint}"
        try:
            response = self.session.post(url, json=data, timeout=timeout)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            return {"error": str(e), "success": False}
    
    def _get(self, endpoint: str, timeout: int = 30) -> Dict:
        """
        Make GET request to API
        
        Args:
            endpoint: API endpoint
            timeout: Request timeout in seconds
        
        Returns:
            Response JSON
        """
        url = f"{self.base_url}{endpoint}"
        try:
            response = self.session.get(url, timeout=timeout)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            return {"error": str(e), "success": False}
    
    def health_check(self) -> Dict:
        """Check if server is healthy"""
        return self._get("/health")
    
    def list_tools(self) -> Dict:
        """List available tools"""
        return self._get("/api/tools/list")

    def tools_run(self, tool: str, target: Optional[str] = None, options: str = "",
                  stream: bool = False, timeout: int = 900) -> Dict:
        data = {"tool": tool, "options": options, "stream": stream}
        if target:
            data["target"] = target
        return self._post("/api/tools/run", data, timeout=timeout)

    def tools_dry_run(self, tool: str, target: Optional[str] = None, options: str = "") -> Dict:
        data = {"tool": tool, "options": options}
        if target:
            data["target"] = target
        return self._post("/api/tools/dry-run", data, timeout=60)

    def tools_pipeline(self, steps: List[Dict]) -> Dict:
        return self._post("/api/tools/pipeline", {"steps": steps}, timeout=1800)
    
    # ==================== SCANNING ====================
    
    def nmap_scan(self, target: str, options: str = "-sV -sC", 
                  output: str = "normal") -> Dict:
        """
        Run nmap scan
        
        Args:
            target: Target IP/network
            options: Nmap options
            output: Output format
        
        Returns:
            Scan results
        """
        return self._post("/api/scan/nmap", {
            "target": target,
            "options": options,
            "output": output
        }, timeout=600)
    
    def masscan(self, target: str, ports: str = "1-65535", 
                rate: str = "1000") -> Dict:
        """
        Run masscan
        
        Args:
            target: Target IP/network
            ports: Port range
            rate: Scan rate
        
        Returns:
            Scan results
        """
        return self._post("/api/scan/masscan", {
            "target": target,
            "ports": ports,
            "rate": rate
        }, timeout=600)
    
    # ==================== BRUTE FORCE ====================
    
    def hydra_bruteforce(self, target: str, service: str,
                         username: Optional[str] = None,
                         userlist: Optional[str] = None,
                         password: Optional[str] = None,
                         passlist: Optional[str] = None,
                         port: Optional[int] = None,
                         options: str = "") -> Dict:
        """
        Run Hydra brute force attack
        
        Args:
            target: Target IP/hostname
            service: Service to attack
            username: Single username
            userlist: Username wordlist path
            password: Single password
            passlist: Password wordlist path
            port: Custom port
            options: Additional options
        
        Returns:
            Attack results
        """
        data = {
            "target": target,
            "service": service,
            "options": options
        }
        
        if username:
            data["username"] = username
        if userlist:
            data["userlist"] = userlist
        if password:
            data["password"] = password
        if passlist:
            data["passlist"] = passlist
        if port:
            data["port"] = port
        
        return self._post("/api/bruteforce/hydra", data, timeout=900)
    
    # ==================== WEB TESTING ====================
    
    def sqlmap(self, url: str, options: str = "--batch --risk=1 --level=1") -> Dict:
        """
        Run SQLMap
        
        Args:
            url: Target URL
            options: SQLMap options
        
        Returns:
            Scan results
        """
        return self._post("/api/web/sqlmap", {
            "url": url,
            "options": options
        }, timeout=900)
    
    def wpscan(self, url: str, options: str = "--enumerate p,t,u") -> Dict:
        """
        Run WPScan
        
        Args:
            url: WordPress URL
            options: WPScan options
        
        Returns:
            Scan results
        """
        return self._post("/api/web/wpscan", {
            "url": url,
            "options": options
        }, timeout=900)
    
    def nikto(self, host: str, port: int = 80, ssl: bool = False) -> Dict:
        """
        Run Nikto web scanner
        
        Args:
            host: Target host
            port: Target port
            ssl: Use SSL
        
        Returns:
            Scan results
        """
        return self._post("/api/web/nikto", {
            "host": host,
            "port": port,
            "ssl": ssl
        }, timeout=900)
    
    def dirb(self, url: str, wordlist: str = "/usr/share/wordlists/dirb/common.txt") -> Dict:
        """
        Run Dirb directory brute force
        
        Args:
            url: Target URL
            wordlist: Wordlist path
        
        Returns:
            Scan results
        """
        return self._post("/api/web/dirb", {
            "url": url,
            "wordlist": wordlist
        }, timeout=900)
    
    def gobuster(self, url: str, 
                 wordlist: str = "/usr/share/wordlists/dirb/common.txt",
                 mode: str = "dir",
                 extensions: str = "") -> Dict:
        """
        Run Gobuster
        
        Args:
            url: Target URL
            wordlist: Wordlist path
            mode: Scan mode (dir/dns/vhost)
            extensions: File extensions
        
        Returns:
            Scan results
        """
        return self._post("/api/web/gobuster", {
            "url": url,
            "wordlist": wordlist,
            "mode": mode,
            "extensions": extensions
        }, timeout=900)
    
    # ==================== EXPLOITATION ====================
    
    def metasploit(self, commands: List[str]) -> Dict:
        """
        Run Metasploit commands
        
        Args:
            commands: List of msfconsole commands
        
        Returns:
            Execution results
        """
        return self._post("/api/exploit/msfconsole", {
            "commands": commands
        }, timeout=1800)
    
    # ==================== REPORTS ====================
    
    def list_reports(self) -> Dict:
        """List all reports"""
        return self._get("/api/reports")
    
    def get_report(self, filename: str) -> Dict:
        """
        Get specific report
        
        Args:
            filename: Report filename
        
        Returns:
            Report content
        """
        return self._get(f"/api/reports/{filename}")

    def get_report_summary(self, filename: str) -> Dict:
        return self._get(f"/api/reports/summary/{filename}")

    def list_artifacts(self, tool: Optional[str] = None, target: Optional[str] = None,
                       artifact_type: Optional[str] = None) -> Dict:
        query = []
        if tool:
            query.append(f"tool={tool}")
        if target:
            query.append(f"target={target}")
        if artifact_type:
            query.append(f"type={artifact_type}")
        suffix = f"?{'&'.join(query)}" if query else ""
        return self._get(f"/api/artifacts{suffix}")


# ==================== EXAMPLE USAGE ====================

def example_usage():
    """Example usage of MCP Client"""
    
    # Initialize client
    client = MCPClient("http://localhost:3000")
    
    # Health check
    print("=== Health Check ===")
    health = client.health_check()
    print(json.dumps(health, indent=2))
    
    # List tools
    print("\n=== Available Tools ===")
    tools = client.list_tools()
    print(json.dumps(tools, indent=2))
    
    # Example: Nmap scan
    print("\n=== Nmap Scan ===")
    nmap_result = client.nmap_scan(
        target="scanme.nmap.org",
        options="-F"  # Fast scan
    )
    print(f"Success: {nmap_result.get('success')}")
    if nmap_result.get('success'):
        print(f"Report: {nmap_result.get('report')}")
    
    # Example: Nikto scan
    print("\n=== Nikto Scan ===")
    nikto_result = client.nikto(
        host="example.com",
        port=80,
        ssl=False
    )
    print(f"Success: {nikto_result.get('success')}")
    
    # Example: List reports
    print("\n=== Reports ===")
    reports = client.list_reports()
    print(json.dumps(reports, indent=2))


if __name__ == "__main__":
    example_usage()
