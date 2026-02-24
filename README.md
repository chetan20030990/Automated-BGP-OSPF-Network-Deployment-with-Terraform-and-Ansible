# Automated BGP/OSPF Network Deployment with Terraform and Ansible

<div align="center">
  <img src="https://readme-typing-svg.herokuapp.com?font=Fira+Code&size=22&pause=1000&color=2E75B6&center=true&vCenter=true&width=700&lines=BGP+%7C+OSPF+%7C+Terraform+%7C+Ansible;AWS+EC2+Router+Simulation;FRRouting+8.5.2;Infrastructure+as+Code" alt="Project Header" />

  ![Status](https://img.shields.io/badge/Status-Completed-success?style=for-the-badge)
  ![Platform](https://img.shields.io/badge/Platform-AWS-orange?style=for-the-badge)
  ![Protocols](https://img.shields.io/badge/Protocols-BGP%20%7C%20OSPF-blue?style=for-the-badge)
  ![IaC](https://img.shields.io/badge/IaC-Terraform%20%7C%20Ansible-purple?style=for-the-badge)
</div>

## Project Overview

A fully automated BGP/OSPF network deployed on AWS using three EC2 instances running **FRRouting (FRR) 8.5.2** as software routers. All infrastructure is provisioned with **Terraform** and all router configuration is managed with **Ansible**, demonstrating end-to-end Infrastructure as Code for a dynamic routing environment.

**Topology:** OSPF Area 0 within AS 100 (R1–R2) and eBGP peering between AS 100 and AS 200 (R1–R3), deployed across two AWS subnets inside a custom VPC.

---

## Network Topology

```
AS 100                              AS 200
┌─────────────────────────┐         ┌─────────────┐
│                         │         │             │
│  R1 (10.0.1.8)  ──────────────────  R3 (10.0.2.5) │
│       |          eBGP   │         │             │
│  OSPF Area 0            │         └─────────────┘
│       |                 │
│  R2 (10.0.1.13)         │
│                         │
└─────────────────────────┘

Subnet A: 10.0.1.0/28  (R1–R2 OSPF link)
Subnet B: 10.0.2.0/28  (R1–R3 eBGP link)
VPC:      10.0.0.0/16
```

---

## Infrastructure Summary

| Component | Details |
|-----------|---------|
| **R1** | AS 100, OSPF Area 0, eBGP peer with R3 |
| **R2** | AS 100, OSPF Area 0 |
| **R3** | AS 200, eBGP peer with R1 |
| **Routing Software** | FRRouting (FRR) 8.5.2 |
| **AWS Infrastructure** | VPC, 2 subnets, Internet Gateway, Security Groups, 3 EC2 t3.micro |
| **IaC** | Terraform (3 modules) + Ansible (3 roles) |

---

## Terraform Module Structure

```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
└── modules/
    ├── vpc/          # VPC, subnets, IGW, route tables
    ├── security_groups/  # SSH, BGP (179), OSPF, intra-VPC rules
    └── ec2/          # EC2 instances, Elastic IPs, outputs
```

**Outputs:** Public IPs, private IPs, and subnet IDs for all three routers — used to dynamically generate the Ansible inventory.

---

## Ansible Role Structure

```
ansible/
├── site.yml
├── inventory/
│   └── hosts.ini          # Generated from Terraform outputs
├── host_vars/
│   ├── R1.yml             # OSPF router-id, BGP AS, peer IPs
│   ├── R2.yml
│   └── R3.yml
└── roles/
    ├── base/              # IP forwarding, FRR 8.5.2 installation
    ├── ospf/              # ospfd daemon, frr.conf OSPF template
    └── bgp/               # bgpd daemon, frr.conf BGP template
```

### Role Descriptions

**base** — Applied to all routers. Enables `net.ipv4.ip_forward`, downloads FRR 8.5.2 RPMs directly (bypassing broken yum repo metadata), installs libyang2 dependency, and starts the `frr` systemd service.

**ospf** — Applied to R1 and R2. Enables `ospfd` in `/etc/frr/daemons` and deploys a Jinja2-templated `frr.conf` with OSPF Area 0. Uses `ip ospf network non-broadcast` with explicit unicast neighbor statements to work around AWS VPC's lack of multicast support.

**bgp** — Applied to R1 and R3. Enables `bgpd` and deploys router-specific BGP configs. R1 (AS 100) peers with R3 (AS 200) over eBGP. Each AS advertises its directly connected prefix.

---

## Key Implementation Notes

### AWS Multicast Limitation
AWS VPC does not support IP multicast. OSPF normally discovers neighbors via multicast to `224.0.0.5`. The fix was to set the interface network type to `non-broadcast` and configure explicit unicast neighbor statements:

```
interface eth0
 ip ospf area 0.0.0.0
 ip ospf network non-broadcast
!
router ospf
 neighbor 10.0.1.13 priority 1
```

### FRR Version Compatibility
FRR 9.x requires a newer `libyang` ABI than what ships with Amazon Linux 2. FRR 8.5.2 was used instead, with `libyang2` downloaded and installed directly from the FRR RPM repository to satisfy the dependency.

### Python Interpreter
Ansible 2.19 requires Python 3.8+ on managed hosts. Amazon Linux 2 ships Python 3.7 by default. Python 3.8 was installed via `amazon-linux-extras` before running the playbook.

---

## Verification Script

`scripts/verify_network.py` automates post-deployment validation using Paramiko to SSH into all three routers and check:

- OSPF neighbor state (`Full/DR` or `Full/Backup`)
- BGP session state (Established)
- Routing table contents
- Ping reachability between routers

**Dependencies:** `pip install paramiko`

**Usage:**
```bash
python3 scripts/verify_network.py           # Normal verification
python3 scripts/verify_network.py --failure # Run failure simulation
```

---

## Verification Results

```
R1 (100.31.196.80)
  [PASS] OSPF neighbor 10.0.1.13 — Full/DR (32m uptime)
  [PASS] BGP session with 10.0.2.5 (AS 200) — Established (30m uptime)
  [PASS] Ping to 10.0.1.13 successful
  [PASS] Ping to 10.0.2.5 successful

R2 (3.237.239.253)
  [PASS] OSPF neighbor 10.0.1.8 — Full/Backup (32m uptime)
  [PASS] Ping to 10.0.1.8 successful

R3 (3.231.24.87)
  [PASS] BGP session with 10.0.1.8 (AS 100) — Established (30m uptime)
  [PASS] BGP route 10.0.1.0/28 learned via 10.0.1.8
  [PASS] Ping to 10.0.1.8 successful
```

---

## Failure Simulation and Reconvergence

The `--failure` flag in the verification script shuts down R1's `eth0` interface and demonstrates protocol reconvergence:

| State | OSPF (R1–R2) | BGP (R1–R3) |
|-------|-------------|-------------|
| **Before** | Full/DR — Full/Backup | Established, prefixes exchanged |
| **During** | No neighbors (R2 lost adjacency) | Connect state, route withdrawn |
| **After** | Full/DR — Full/Backup restored | Re-established, route re-advertised |

**Reconvergence time:** ~35–40 seconds (OSPF dead timer 40s, BGP hold timer 180s with fast detection).

---

## BGP Routing Table (R3 after reconvergence)

```
K>* 0.0.0.0/0 [0/0] via 10.0.2.1, eth0
B   10.0.1.0/28 [20/0] via 10.0.1.8, weight 1   ← learned from R1 via eBGP
S>* 10.0.1.8/32 [1/0] via 10.0.2.1, eth0
C>* 10.0.2.0/28 is directly connected, eth0
```

---

## Repository Structure

```
bgp-ospf-project/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│       ├── vpc/
│       ├── security_groups/
│       └── ec2/
├── ansible/
│   ├── site.yml
│   ├── inventory/
│   │   └── hosts.ini
│   ├── host_vars/
│   │   ├── R1.yml
│   │   ├── R2.yml
│   │   └── R3.yml
│   └── roles/
│       ├── base/
│       ├── ospf/
│       └── bgp/
└── scripts/
    └── verify_network.py
```

---

## Technologies Used

| Category | Tools |
|----------|-------|
| **Routing Software** | FRRouting (FRR) 8.5.2 |
| **Infrastructure Provisioning** | Terraform |
| **Configuration Management** | Ansible |
| **Cloud Platform** | AWS (EC2, VPC, Security Groups) |
| **Routing Protocols** | OSPF (Area 0), eBGP |
| **Scripting** | Python, Bash |
| **SSH Automation** | Paramiko |
| **OS** | Amazon Linux 2 |

---

## Academic Context

- **Course:** TELE 6420 — Infrastructure Automation
- **Institution:** Northeastern University, Boston, MA
- **Period:** Spring 2026

---

<div align="center">

**Chetan Pavan Sai Nannapaneni**

[![LinkedIn](https://img.shields.io/badge/-LinkedIn-0077B5?style=for-the-badge&logo=LinkedIn&logoColor=white)](https://www.linkedin.com/in/chetannannapaneni/)
[![Email](https://img.shields.io/badge/-Email-D14836?style=for-the-badge&logo=Gmail&logoColor=white)](mailto:nannapaneni.che@northeastern.edu)
[![Portfolio](https://img.shields.io/badge/-Portfolio-000000?style=for-the-badge&logo=GitHub&logoColor=white)](https://github.com/chetan20030990/networking-portfolio)

</div>
