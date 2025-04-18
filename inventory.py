import os
import json
import argparse

def get_inventory_from_env():
    """
    Generates Ansible inventory JSON from environment variables.
    Expects:
    TARGET_HOST_IP: The IP address or hostname of the target server.
    TARGET_SSH_USER: The SSH username for the target server.
    """
    host_ip = os.environ.get('TARGET_HOST_IP')
    ssh_user = os.environ.get('TARGET_SSH_USER')

    if not host_ip:
        raise ValueError("Environment variable TARGET_HOST_IP is not set.")
    if not ssh_user:
        print("Warning: Environment variable TARGET_SSH_USER not set, using default.")
        # Or raise ValueError("Environment variable TARGET_SSH_USER is not set.")

    inventory = {
        "llm_servers": {
            "hosts": [host_ip],
            "vars": {} # Add group-level vars here if needed
        },
        "_meta": {
            "hostvars": {
                host_ip: {
                    # ansible_host defaults to the host key (host_ip)
                    # Only add ansible_user if it's set
                }
            }
        }
    }

    if ssh_user:
        inventory["_meta"]["hostvars"][host_ip]["ansible_user"] = ssh_user
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
         try:
            inv = get_inventory_from_env()
            print(json.dumps(inv, indent=4))
         except ValueError as e:
             print(json.dumps({"_meta": {"hostvars": {}}}, indent=4)) # Output empty on error
             import sys
             print(f"Error: {e}", file=sys.stderr)
             sys.exit(1)
