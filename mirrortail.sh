#!/bin/bash

# --- Setup & Variables ---
TARGET_FILE="subdomains.txt"
OUTPUT_DIR="./recon_results_$(date +%F)"
mkdir -p "$OUTPUT_DIR"

# Check if input file exists
if [[ ! -f "$TARGET_FILE" ]]; then
    echo "[ERR] $TARGET_FILE not found."
    exit 1
fi

echo "[+] Starting recon on $(wc -l < "$TARGET_FILE") targets..."

# --- 1. Subdomain Gathering (Passive & Fast) ---
echo "[+] Running Subfinder and Amass..."
subfinder -dL "$TARGET_FILE" -silent -o "$OUTPUT_DIR/subfinder.txt"
amass enum -passive -df "$TARGET_FILE" -o "$OUTPUT_DIR/amass.txt"

# Combine and deduplicate
cat "$OUTPUT_DIR/subfinder.txt" "$OUTPUT_DIR/amass.txt" | sort -u > "$OUTPUT_DIR/all_subs.txt"
echo "[+] Total subdomains found: $(wc -l < "$OUTPUT_DIR/all_subs.txt")"

# --- 2. Live Host Discovery (The Filter) ---
echo "[+] Probing for live HTTP/HTTPS services..."
cat "$OUTPUT_DIR/all_subs.txt" | httpx \
    -title \
    -tech-detect \
    -status-code \
    -follow-redirects \
    -threads 50 \
    -silent \
    -o "$OUTPUT_DIR/live_hosts.txt"

# --- 3. Vulnerability Scanning (Targeted) ---
echo "[+] Running Nuclei templates (Critical/High/Exposures)..."
nuclei -l "$OUTPUT_DIR/live_hosts.txt" \
    -severity critical,high \
    -tags exposure,misconfiguration,cve \
    -rate-limit 15 \
    -o "$OUTPUT_DIR/nuclei_results.txt"

# --- 4. Summary ---
echo "---"
echo "[+] Recon complete."
echo "[>] Results saved in: $OUTPUT_DIR"
echo "[>] Live hosts: $(wc -l < "$OUTPUT_DIR/live_hosts.txt")"
echo "[>] Nuclei findings: $(wc -l < "$OUTPUT_DIR/nuclei_results.txt")"
