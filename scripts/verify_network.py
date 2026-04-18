#!/usr/bin/env python3
"""
verify_network.py — Automated verification script for BGP/OSPF lab
Usage: python3 scripts/verify_network.py
       Set R1/R2/R3 IPs and KEY_PATH before running.
"""

import paramiko
import sys
import time

# ── CONFIG ──────────────────────────────────────────────────────────────────
KEY_PATH = "~/.ssh/bgp-ospf-key.pem"
SSH_USER = "ec2-user"

ROUTERS = {
    "R1": "100.31.196.80",
    "R2": "3.237.239.253",
    "R3": "3.231.24.87",
}

PING_TARGETS = {
    "R1": ["10.0.1.13", "10.0.2.5"],  # ping R2 and R3
    "R2": ["10.0.1.8"],               # ping R1
    "R3": ["10.0.1.8"],               # ping R1
}
# ── END CONFIG ───────────────────────────────────────────────────────────────

COMMANDS = [
    ("OSPF Neighbors",  "sudo vtysh -c 'show ip ospf neighbor'"),
    ("BGP Summary",     "sudo vtysh -c 'show ip bgp summary'"),
    ("Routing Table",   "sudo vtysh -c 'show ip route'"),
]

PASS = "\033[92m[PASS]\033[0m"
FAIL = "\033[91m[FAIL]\033[0m"
INFO = "\033[94m[INFO]\033[0m"


def ssh_connect(ip: str) -> paramiko.SSHClient:
    import os
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(ip, username=SSH_USER, key_filename=os.path.expanduser(KEY_PATH), timeout=15)
    return client


def run_command(client: paramiko.SSHClient, cmd: str) -> str:
    _, stdout, stderr = client.exec_command(cmd)
    return stdout.read().decode().strip()


def check_router(name: str, ip: str):
    print(f"\n{'='*60}")
    print(f"  {name}  ({ip})")
    print(f"{'='*60}")
    try:
        client = ssh_connect(ip)
    except Exception as e:
        print(f"  {FAIL} Could not connect: {e}")
        return

    for label, cmd in COMMANDS:
        print(f"\n{INFO} {label}")
        out = run_command(client, cmd)
        print(out if out else "  (no output)")

        # Basic pass/fail checks
        if "OSPF" in label and "Full" in out:
            print(f"  {PASS} OSPF neighbor(s) in Full state")
        elif "OSPF" in label and out:
            print(f"  {FAIL} No OSPF Full neighbors detected")

        if "BGP" in label and out:
            # FRR 8.5 shows numeric prefix count (e.g. '1') or 'Established' when up
            import re
            if re.search(r'\b\d+\s+\d+\s+\d+:\d+:\d+\s+\d+', out) or "Established" in out:
                print(f"  {PASS} BGP session(s) Established")
            else:
                print(f"  {FAIL} No BGP Established sessions found")

    # Ping tests
    targets = PING_TARGETS.get(name, [])
    for target in targets:
        out = run_command(client, f"ping -c 3 -W 2 {target}")
        if "3 received" in out or "3 packets received" in out:
            print(f"  {PASS} Ping to {target} successful")
        else:
            print(f"  {FAIL} Ping to {target} FAILED")

    client.close()


def simulate_failure(r1_ip: str):
    print(f"\n{'='*60}")
    print("  FAILURE SIMULATION — Shutting down R1 eth0 (OSPF link)")
    print(f"{'='*60}")
    try:
        client = ssh_connect(r1_ip)
        # Shut down the OSPF-facing interface
        run_command(client, "sudo vtysh -c 'conf t' -c 'interface eth0' -c 'shutdown'")
        print(f"  {INFO} Interface eth0 on R1 shut down. Waiting 30s for reconvergence...")
        client.close()

        time.sleep(30)

        # Check R2 routing table — OSPF route to R1 should be gone
        client = ssh_connect(ROUTERS["R2"])
        out = run_command(client, "sudo vtysh -c 'show ip route'")
        print(f"\n{INFO} R2 routing table DURING failure:")
        print(out)
        client.close()

        # Bring link back up
        client = ssh_connect(r1_ip)
        run_command(client, "sudo vtysh -c 'conf t' -c 'interface eth0' -c 'no shutdown'")
        print(f"\n  {INFO} Interface eth0 on R1 restored. Waiting 30s for reconvergence...")
        client.close()

        time.sleep(30)

        # Verify reconvergence
        client = ssh_connect(ROUTERS["R2"])
        out = run_command(client, "sudo vtysh -c 'show ip route'")
        print(f"\n{INFO} R2 routing table AFTER reconvergence:")
        print(out)
        if "10.0.1.0" in out:
            print(f"  {PASS} Routes reconverged successfully")
        else:
            print(f"  {FAIL} Route reconvergence may have failed — check manually")
        client.close()

    except Exception as e:
        print(f"  {FAIL} Failure simulation error: {e}")


if __name__ == "__main__":
    print("\n🔍 BGP/OSPF Network Verification Script")
    print("=========================================\n")

    # Normal verification
    for name, ip in ROUTERS.items():
        check_router(name, ip)

    # Optionally run failure simulation
    if "--failure" in sys.argv:
        simulate_failure(ROUTERS["R1"])

    print("\n✅ Verification complete.\n")
