#!/usr/bin/env python3
"""AIRE Agent MCP Server - JSON-RPC over stdio.

A thin MCP server that dispatches tool calls to shell scripts in tools/.
Speaks JSON-RPC over stdio (one request per line, one response per line).
Stdlib only - no external packages required.
"""
import json
import os
import subprocess
import sys

# ── Constants ─────────────────────────────────────────────────────────────────

REPO_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS_DIR = os.path.join(REPO_DIR, "tools")
SCRIPTS_DIR = os.path.join(REPO_DIR, "scripts")

SUBPROCESS_TIMEOUT = 60  # seconds

# ── Tool definitions (MCP schema) ────────────────────────────────────────────

TOOLS = [
    {
        "name": "submit_job",
        "description": "Submit a Slurm batch job script to the AIRE HPC queue.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "script": {
                    "type": "string",
                    "description": "Path to the job script to submit",
                },
            },
            "required": ["script"],
        },
    },
    {
        "name": "check_queue",
        "description": "Check the Slurm job queue. Shows pending and running jobs.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "all_users": {
                    "type": "boolean",
                    "description": "Show jobs for all users (default: current user only)",
                },
            },
            "required": [],
        },
    },
    {
        "name": "cancel_job",
        "description": "Cancel one or more Slurm jobs by job ID.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "job_ids": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "One or more job IDs to cancel",
                },
            },
            "required": ["job_ids"],
        },
    },
    {
        "name": "job_status",
        "description": "Show detailed status of a Slurm job.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "job_id": {
                    "type": "string",
                    "description": "The job ID to query",
                },
            },
            "required": ["job_id"],
        },
    },
    {
        "name": "job_efficiency",
        "description": "Show efficiency report for a completed Slurm job.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "job_id": {
                    "type": "string",
                    "description": "The job ID to query",
                },
            },
            "required": ["job_id"],
        },
    },
    {
        "name": "generate_script",
        "description": "Generate an SBATCH job script with the specified resources and framework.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "time": {
                    "type": "string",
                    "description": "Wall time (e.g., 1h, 4h, 1d, 01:00:00)",
                },
                "gpu": {
                    "type": "integer",
                    "description": "Number of GPUs (default: 0, CPU job)",
                },
                "cpus": {
                    "type": "integer",
                    "description": "CPUs per task",
                },
                "mem": {
                    "type": "string",
                    "description": "Memory allocation (e.g., 8G, 16G)",
                },
                "partition": {
                    "type": "string",
                    "description": "Partition name (auto: gpu if --gpu >0, cpu otherwise)",
                },
                "framework": {
                    "type": "string",
                    "description": "Framework: pytorch, tensorflow, or none",
                    "enum": ["pytorch", "tensorflow", "none"],
                },
                "job_name": {
                    "type": "string",
                    "description": "Job name (default: job)",
                },
                "email": {
                    "type": "string",
                    "description": "Email address for notifications",
                },
                "array": {
                    "type": "string",
                    "description": "Array job range (e.g., 1-10, 1-100%5)",
                },
            },
            "required": ["time"],
        },
    },
    {
        "name": "validate_script",
        "description": "Validate an SBATCH job script for common errors and best practices.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "script": {
                    "type": "string",
                    "description": "Path to the job script to validate",
                },
            },
            "required": ["script"],
        },
    },
    {
        "name": "search_docs",
        "description": "Search the AIRE knowledge base and documentation for a query string.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": "Search query string",
                },
            },
            "required": ["query"],
        },
    },
    {
        "name": "list_modules",
        "description": "List available software modules on AIRE. Optionally filter by keyword.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "filter": {
                    "type": "string",
                    "description": "Optional keyword to filter modules",
                },
            },
            "required": [],
        },
    },
    {
        "name": "system_info",
        "description": "Display AIRE HPC system specifications including nodes, GPUs, storage, and network.",
        "inputSchema": {
            "type": "object",
            "properties": {},
            "required": [],
        },
    },
    {
        "name": "check_quota",
        "description": "Check disk quota usage on AIRE (home and scratch directories).",
        "inputSchema": {
            "type": "object",
            "properties": {},
            "required": [],
        },
    },
    {
        "name": "node_availability",
        "description": "Show current AIRE node availability and partition status.",
        "inputSchema": {
            "type": "object",
            "properties": {},
            "required": [],
        },
    },
    {
        "name": "log_experiment",
        "description": "Log an experiment run to the local experiment tracker.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "name": {
                    "type": "string",
                    "description": "Experiment name (e.g., bert_finetune_v2)",
                },
                "job_id": {
                    "type": "string",
                    "description": "Slurm job ID (defaults to $SLURM_JOB_ID)",
                },
                "metrics": {
                    "type": "string",
                    "description": "Metrics as JSON string, e.g. '{\"loss\": 0.5}'",
                },
                "params": {
                    "type": "string",
                    "description": "Hyperparameters as JSON string, e.g. '{\"lr\": 0.001}'",
                },
                "notes": {
                    "type": "string",
                    "description": "Free-text notes about this run",
                },
            },
            "required": ["name"],
        },
    },
    {
        "name": "query_experiments",
        "description": "Query and display logged experiments from the tracker.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "last": {
                    "type": "integer",
                    "description": "Show last N experiments (default: 20)",
                },
                "filter": {
                    "type": "string",
                    "description": "Filter experiments by field=value",
                },
                "json_output": {
                    "type": "boolean",
                    "description": "Output raw JSONL format",
                },
            },
            "required": [],
        },
    },
    {
        "name": "sync_docs",
        "description": "Synchronise AIRE documentation from upstream sources.",
        "inputSchema": {
            "type": "object",
            "properties": {},
            "required": [],
        },
    },
]


# ── Tool dispatch ─────────────────────────────────────────────────────────────

def _build_args_submit_job(arguments):
    args = []
    if arguments.get("script"):
        args.append(arguments["script"])
    return args


def _build_args_check_queue(arguments):
    args = []
    if arguments.get("all_users"):
        args.append("--all")
    return args


def _build_args_cancel_job(arguments):
    return arguments.get("job_ids", [])


def _build_args_job_status(arguments):
    args = []
    if arguments.get("job_id"):
        args.append(arguments["job_id"])
    return args


def _build_args_job_efficiency(arguments):
    args = []
    if arguments.get("job_id"):
        args.append(arguments["job_id"])
    return args


def _build_args_generate_script(arguments):
    args = ["--time", arguments.get("time", "1h")]
    if arguments.get("gpu"):
        args.extend(["--gpu", str(arguments["gpu"])])
    if arguments.get("cpus"):
        args.extend(["--cpus", str(arguments["cpus"])])
    if arguments.get("mem"):
        args.extend(["--mem", arguments["mem"]])
    if arguments.get("partition"):
        args.extend(["--partition", arguments["partition"]])
    if arguments.get("framework"):
        args.extend(["--framework", arguments["framework"]])
    if arguments.get("job_name"):
        args.extend(["--job-name", arguments["job_name"]])
    if arguments.get("email"):
        args.extend(["--email", arguments["email"]])
    if arguments.get("array"):
        args.extend(["--array", arguments["array"]])
    return args


def _build_args_validate_script(arguments):
    args = []
    if arguments.get("script"):
        args.append(arguments["script"])
    return args


def _build_args_search_docs(arguments):
    args = []
    if arguments.get("query"):
        args.append(arguments["query"])
    return args


def _build_args_list_modules(arguments):
    args = []
    if arguments.get("filter"):
        args.append(arguments["filter"])
    return args


def _build_args_none(arguments):
    return []


def _build_args_log_experiment(arguments):
    args = ["--name", arguments.get("name", "unnamed")]
    if arguments.get("job_id"):
        args.extend(["--job", arguments["job_id"]])
    if arguments.get("metrics"):
        args.extend(["--metrics", arguments["metrics"]])
    if arguments.get("params"):
        args.extend(["--params", arguments["params"]])
    if arguments.get("notes"):
        args.extend(["--notes", arguments["notes"]])
    return args


def _build_args_query_experiments(arguments):
    args = []
    if arguments.get("last"):
        args.extend(["--last", str(arguments["last"])])
    if arguments.get("filter"):
        args.extend(["--filter", arguments["filter"]])
    if arguments.get("json_output"):
        args.append("--json")
    return args


# Maps tool name -> (script_path, arg_builder)
TOOL_DISPATCH = {
    "submit_job": (os.path.join(TOOLS_DIR, "submit-job.sh"), _build_args_submit_job),
    "check_queue": (os.path.join(TOOLS_DIR, "check-queue.sh"), _build_args_check_queue),
    "cancel_job": (os.path.join(TOOLS_DIR, "cancel-job.sh"), _build_args_cancel_job),
    "job_status": (os.path.join(TOOLS_DIR, "job-status.sh"), _build_args_job_status),
    "job_efficiency": (os.path.join(TOOLS_DIR, "job-efficiency.sh"), _build_args_job_efficiency),
    "generate_script": (os.path.join(TOOLS_DIR, "generate-script.sh"), _build_args_generate_script),
    "validate_script": (os.path.join(TOOLS_DIR, "validate-script.sh"), _build_args_validate_script),
    "search_docs": (os.path.join(TOOLS_DIR, "search-docs.sh"), _build_args_search_docs),
    "list_modules": (os.path.join(TOOLS_DIR, "list-modules.sh"), _build_args_list_modules),
    "system_info": (os.path.join(TOOLS_DIR, "system-info.sh"), _build_args_none),
    "check_quota": (os.path.join(TOOLS_DIR, "check-quota.sh"), _build_args_none),
    "node_availability": (os.path.join(TOOLS_DIR, "node-availability.sh"), _build_args_none),
    "log_experiment": (os.path.join(TOOLS_DIR, "log-experiment.sh"), _build_args_log_experiment),
    "query_experiments": (os.path.join(TOOLS_DIR, "query-experiments.sh"), _build_args_query_experiments),
    "sync_docs": (os.path.join(SCRIPTS_DIR, "sync.sh"), _build_args_none),
}


# ── Core functions ────────────────────────────────────────────────────────────

def run_tool(name, arguments):
    """Execute a shell script for the given tool and return its output."""
    if name not in TOOL_DISPATCH:
        return {"error": True, "text": f"Unknown tool: {name}"}

    script_path, arg_builder = TOOL_DISPATCH[name]

    if not os.path.exists(script_path):
        return {"error": True, "text": f"Script not found: {script_path}"}

    cmd = ["bash", script_path] + arg_builder(arguments or {})

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=SUBPROCESS_TIMEOUT,
            cwd=REPO_DIR,
        )
        output = result.stdout
        if result.returncode != 0 and result.stderr:
            output = output + "\n" + result.stderr if output else result.stderr
        return {"error": False, "text": output.strip() if output else "(no output)"}
    except subprocess.TimeoutExpired:
        return {"error": True, "text": f"Tool '{name}' timed out after {SUBPROCESS_TIMEOUT}s"}
    except Exception as exc:
        return {"error": True, "text": f"Error running tool '{name}': {exc}"}


def handle_request(request):
    """Process a JSON-RPC request and return a response dict."""
    req_id = request.get("id")
    method = request.get("method", "")
    params = request.get("params", {})

    if method == "initialize":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {
                    "tools": {"listChanged": False},
                },
                "serverInfo": {
                    "name": "aire-agent",
                    "version": "0.1.0",
                },
            },
        }

    if method == "notifications/initialized":
        # Acknowledgement, no response needed
        return None

    if method == "tools/list":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "tools": TOOLS,
            },
        }

    if method == "tools/call":
        tool_name = params.get("name", "")
        arguments = params.get("arguments", {})
        tool_result = run_tool(tool_name, arguments)

        if tool_result.get("error"):
            return {
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {
                    "content": [{"type": "text", "text": tool_result["text"]}],
                    "isError": True,
                },
            }

        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "content": [{"type": "text", "text": tool_result["text"]}],
            },
        }

    # Unknown method
    return {
        "jsonrpc": "2.0",
        "id": req_id,
        "error": {
            "code": -32601,
            "message": f"Method not found: {method}",
        },
    }


def main():
    """Read JSON-RPC requests from stdin, dispatch, write responses to stdout."""
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue

        try:
            request = json.loads(line)
        except json.JSONDecodeError as exc:
            response = {
                "jsonrpc": "2.0",
                "id": None,
                "error": {
                    "code": -32700,
                    "message": f"Parse error: {exc}",
                },
            }
            sys.stdout.write(json.dumps(response) + "\n")
            sys.stdout.flush()
            continue

        response = handle_request(request)
        if response is not None:
            sys.stdout.write(json.dumps(response) + "\n")
            sys.stdout.flush()


if __name__ == "__main__":
    main()
