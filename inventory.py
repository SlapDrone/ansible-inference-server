#!/usr/bin/env python3
import os
import json
import argparse
from pathlib import Path
import sys

# 1) Load .env from repo root so ansible-playbook sees TARGET_HOST_* automatically
dotenv = Path(__file__).parent / '.env'
if dotenv.exists():
    for line in dotenv.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if '=' in line:
            key, val = line.split('=', 1)
            # do not override env vars already set
            os.environ.setdefault(key.strip(), val.strip())
# The file mode has been changed to executable.

def get_inventory_from_env():
    """
    Generates Ansible inventory JSON from environment variables.
    Expects:
    TARGET_HOST_IP: The IP address or hostname of the target server.
    TARGET_SSH_USER: The SSH username for the target server.
    """
    # allow pointing at a real IP/hostname *or* an SSH‑config alias
    host_name = os.environ.get('TARGET_HOST_IP') or os.environ.get('TARGET_HOST_ALIAS')
    ssh_user = os.environ.get('TARGET_SSH_USER')

    if not host_name:
        raise ValueError("Set TARGET_HOST_IP or TARGET_HOST_ALIAS to your host (e.g. ‘pt’).")
    if not ssh_user:
        # send warnings to stderr so we don’t break JSON output
        print("Warning: Environment variable TARGET_SSH_USER not set, using default.", file=sys.stderr)
        # Or raise ValueError("Environment variable TARGET_SSH_USER is not set.")

    inventory = {
        "llm_servers": {
            "hosts": [host_name],
            "vars": {} # Add group-level vars here if needed
        },
        "_meta": {
            "hostvars": {
                host_name: {
                    # ansible_host defaults to the host key (host_ip)
                    # Only add ansible_user if it's set
                }
            }
        }
    }

    if ssh_user:
        inventory["_meta"]["hostvars"][host_name]["ansible_user"] = ssh_user
        # Optionally add other vars like private key file if needed from env vars
        # key_file = os.environ.get('TARGET_SSH_KEY')
        # if key_file:
        #    inventory["_meta"]["hostvars"][host_ip]["ansible_ssh_private_key_file"] = key_file

    return inventory

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--list', action='store_true')
    parser.add_argument('--host', action='store')
    args = parser.parse_args()

    if args.list:
        try:
            inv = get_inventory_from_env()
            print(json.dumps(inv, indent=4))
        except ValueError as e:
            print(json.dumps({"_meta": {"hostvars": {}}}, indent=4)) # Output empty on error
            import sys
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
    elif args.host:
        # Required by Ansible, but we can return empty if not needed for --host lookup
        print(json.dumps({}))
    else:
        # Default case if no arguments are passed (e.g., manual testing)
        inv = get_inventory_from_env()
        print(json.dumps(inv, indent=4))
