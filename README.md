

## About

**MirrorTrail** is a Bash-based automation script for **Attack Surface Management (ASM)** and **reconnaissance**.

It is designed to help security teams and authorized bug bounty hunters quickly discover hidden assets, validate what is actually live, and focus attention on the systems that matter. By combining subdomain enumeration, live host filtering, and targeted vulnerability checks, MirrorTrail helps reduce noise and surface shadow IT, forgotten infrastructure, and unmonitored exposure faster.

## Core Workflow

MirrorTrail uses a simple, high-signal pipeline:

- **`subfinder`** and **`amass`** for passive and active subdomain enumeration
- **`httpx`** for live host probing, basic tech detection, and filtering dead DNS records
- **`nuclei`** for targeted scanning of critical/high severity issues, exposures, and CVEs

## Key Features

- Reads targets from a `targets.txt` file for dynamic, scalable scanning
- Automatically creates timestamped output directories for clean result organization
- Filters out dead assets to save time and reduce wasted requests
- Applies rate limiting to help reduce the chance of WAF blocks during scanning

## Prerequisites

Before running MirrorTrail, make sure the following tools are installed and available in your `PATH`:

- `bash`
- `amass`
- `subfinder`
- `httpx`
- `nuclei`

You will also need a `targets.txt` file with one target per line:

```txt
example.com
example.org
example.net
