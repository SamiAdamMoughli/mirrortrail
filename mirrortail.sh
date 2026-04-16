#!/bin/bash

# --- Setup & Variables ---
TARGET_FILE="targets.txt"
OUTPUT_DIR="./recon_results_$(date +%F)"
mkdir -p "$OUTPUT_DIR"

# Check if input file exists
if [[ ! -f "$TARGET_FILE" ]]; then
    echo "[!] Error: $TARGET_FILE not found."
    exit 1
fi

echo "[+] Starting recon on $(cat $TARGET_FILE | wc -l) targets..."

# --- 1. Subdomain Gathering (Passive & Fast) ---
echo "[+] Running Subfinder and Amass..."
subfinder -dL "$TARGET_FILE" -silent -o "$OUTPUT_DIR/subfinder.txt"
amass enum -passive -df "$TARGET_FILE" -o "$OUTPUT_DIR/amass.txt"

# Combine and unique
cat "$OUTPUT_DIR/subfinder.txt" "$OUTPUT_DIR/amass.txt" | sort -u > "$OUTPUT_DIR/all_subs.txt"
echo "[+] Total subdomains found: $(cat $OUTPUT_DIR/all_subs.txt | wc -l)"

# --- 2. Live Host Discovery (The Filter) ---
# We use httpx to check for working web servers and grab basic info
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
# We exclude 'fuzzing' to keep it fast and less noisy
nuclei -l "$OUTPUT_DIR/live_hosts.txt" \
    -severity critical,high \
    -tags exposure,misconfiguration,cve \
    -rate-limit 15 \
    -o "$OUTPUT_DIR/nuclei_results.txt"

# --- 4. Summary ---
echo "---"
echo "[✓] Recon Complete!"
echo "[>] Results saved in: $OUTPUT_DIR"
echo "[>] Live hosts: $(cat $OUTPUT_DIR/live_hosts.txt | wc -l)"
echo "[>] Nuclei findings: $(cat $OUTPUT_DIR/nuclei_results.txt | wc -l)"
