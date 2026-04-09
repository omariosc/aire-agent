"""Tests for the aire-agent MCP server."""
import json
import subprocess
import sys
import os

REPO_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SERVER_PATH = os.path.join(REPO_DIR, "mcp", "server.py")


def send_mcp_request(method, params=None, req_id=1):
    """Send a JSON-RPC request to the MCP server and return the response."""
    request = {"jsonrpc": "2.0", "id": req_id, "method": method}
    if params:
        request["params"] = params
    proc = subprocess.run(
        [sys.executable, SERVER_PATH],
        input=json.dumps(request) + "\n",
        capture_output=True,
        text=True,
        timeout=10,
    )
    lines = [l for l in proc.stdout.strip().split("\n") if l.strip()]
    if lines:
        return json.loads(lines[-1])
    return None


def test_server_exists():
    assert os.path.exists(SERVER_PATH)


def test_initialize():
    resp = send_mcp_request("initialize", {
        "protocolVersion": "2024-11-05",
        "capabilities": {},
        "clientInfo": {"name": "test", "version": "1.0"},
    })
    assert resp is not None
    assert "result" in resp
    assert "capabilities" in resp["result"]


def test_tools_list():
    resp = send_mcp_request("tools/list")
    assert resp is not None
    assert "result" in resp
    tools = resp["result"]["tools"]
    tool_names = [t["name"] for t in tools]
    assert "system_info" in tool_names
    assert "search_docs" in tool_names
    assert "validate_script" in tool_names
    assert "generate_script" in tool_names


def test_system_info_tool():
    resp = send_mcp_request("tools/call", {
        "name": "system_info",
        "arguments": {},
    })
    assert resp is not None
    assert "result" in resp
    content = resp["result"]["content"][0]["text"]
    assert "AIRE" in content
    assert "L40S" in content


def test_search_docs_tool():
    resp = send_mcp_request("tools/call", {
        "name": "search_docs",
        "arguments": {"query": "GPU"},
    })
    assert resp is not None
    assert "result" in resp
    content = resp["result"]["content"][0]["text"]
    assert "GPU" in content


def test_unknown_method():
    resp = send_mcp_request("nonexistent/method")
    assert resp is not None
    assert "error" in resp
