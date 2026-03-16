# Containerization and Advanced Networking Assignment Report

**Student Details:**
- **Name:** Aditya Shrivastava
- **SAP ID:** 500124727
- **Enrollment No.:** R2142231558
- **Batch:** BATCH 4 CCVT 6th Semester 3rd Year

---

## 1. Build Optimization Explanation

The backend application utilizes a **Multi-Stage Build** Dockerfile to ensure the resulting container image is highly optimized, secure, and production-ready. 

- **Stage 1 (Builder):** We start with a lightweight `python:3.11-slim` base image and install necessary system dependencies and C-compilers like `gcc` and `libpq-dev`. These tools are strictly required to build and compile Python packages that rely on C-extensions (such as `psycopg2` for PostgreSQL connectivity). In this stage, we package all dependencies into pre-compiled binary `.whl` files using `pip wheel`.
- **Stage 2 (Runtime Container):** We initialize a fresh, new `python:3.11-slim` image. However, this time, we completely omit all compilation tools and build libraries. We only install `libpq5` (which is needed at runtime to communicate with Postgres) and copy over the pre-compiled `.whl` files from the first stage. 

**Why it is optimal:** By implementing this multi-stage approach, the final image is completely purged of source dependency caches, heavy C-compilers, and unnecessary development libraries. Furthermore, a non-root `appuser` is created in the final stage to run the application, ensuring that even if the container is compromised, the attacker does not have root-level filesystem access.

---

## 2. Network Design Diagram

Below is an ASCII representation of the architecture, illustrating how the isolated Docker containers communicate via the Macvlan network bridge directly mapping to the host's physical network interface.

```text
+-------------------------------------------------------------+
|               Host Machine / Physical Switch                |
|               (eth0 / Physical Interface)                   |
+-----------------------------+-------------------------------+
                              |
+-----------------------------v-------------------------------+
|               Macvlan Network (802.1q Bridge)               |
+--------------+-------------------------------+--------------+
               |                               |
     +---------v---------+           +---------v---------+
     |   FastAPI Backend |           |   PostgreSQL DB   |
     |    (Container)    |           |    (Container)    |
     | Unique MAC & IP   |           | Unique MAC & IP   |
     +---------+---------+           +---------+---------+
               |                               ^
               |           TCP / 5432          |
               +-------------------------------+
```

---

## 3. Image Size Comparison

When packaging Python applications that require database connectivity (like `psycopg2`), the difference in image size between a single-stage and multi-stage build is significant.

- **Standard Single-Stage Build:** A standard Dockerfile copying all requirements into a `python:3.11-slim` image alongside build-essential tools (`gcc`, `g++`, `make`) results in an image size typically ranging between **350MB to 500MB**. This image is bloated because it carries tools that a container does not need to execute the runtime application.
- **Optimized Multi-Stage Build:** By dropping the build environment layout in the first stage and utilizing only the pre-compiled `.whl` distributions in the second stage, the final image size dramatically shrinks down to approximately **120MB to 150MB**.

**Conclusion:** The multi-stage build decreases the storage footprint by over 60%. This significantly reduces network bandwidth costs during image pulls, speeds up deployment times in CI/CD pipelines, and minimizes the attack surface by ensuring fewer vulnerable system binaries are present.

---

## 4. Macvlan vs. Ipvlan Comparison

Both **Macvlan** and **Ipvlan** are advanced Docker networking drivers utilized when containers must bridge directly to an underlying physical network segment, bypassing traditional Docker NAT (Network Address Translation) and port-forwarding.

### Macvlan
Macvlan operates at Layer 2 (Data Link Layer) and relies on the 802.1q trunking protocol. Sub-interfaces are spawned and attached to the parent adapter.
- **Mechanism:** Each container is assigned a **unique IP Address** *and* a **unique MAC Address**.
- **Perception:** To the external network setup, physical switches, and routers, the containers look like completely separate, physical network devices plugged uniquely into the switch.
- **Primary Use Case:** Best suited for legacy applications that demand direct broadcast domains, strict physical-like network presence, or environments where network hardware mandates standard 1:1 MAC-to-IP mappings.

### Ipvlan
Ipvlan abstracts the MAC address away and allows finer routing control. It can run in either Layer 2 (L2) or Layer 3 (L3) modes.
- **Mechanism:** All containers on the Ipvlan network share the single, underlying **parent host MAC address**, but they receive **unique IP Addresses**.
- **Perception:** To the external network, all container traffic appears to originate from the single host machine, despite bearing different IP headers.
- **Primary Use Case:** Mandatory in modern cloud environments (such as AWS VPC, Google Cloud, or strict VMware ESXi infrastructures). These cloud providers implement rigid security mechanisms (MAC spoofing protection or port-security) that aggressively drop traffic originating from unrecognized or multiple MAC addresses on a single switch port. Ipvlan seamlessly bypasses these limitations.

**Summary for Production:**
In an on-premise datacenter with full switch control and promiscuous mode active, **Macvlan** is preferred for hardware-level transparency. However, in AWS, Azure, or strict hypervisor environments where MAC filtering is enforced, **Ipvlan** is strictly necessary.
