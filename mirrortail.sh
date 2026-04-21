#!/bin/bash

# --- Banner ---
cat << BANNER
    ...     ..      ..        .                                                           .....                                      .          .. 
  x*8888x.:*8888: -"888:     @88>                                                      .H8888888h.  ~-.                             @88>  x .d88"  
 X   48888X '8888H  8888     %8P      .u    .      .u    .          u.      .u    .    888888888888x  '>    .u    .                 %8P    5888R   
X8x.  8888X  8888X  !888>     .     .d88B :@8c   .d88B :@8c   ...ue888b   .d88B :@8c  X~     '?888888hx~  .d88B :@8c        u        .     '888R   
X8888 X8888  88888   '*8%-  .@88u  ='8888f8888r ='8888f8888r  888R Y888r ='8888f8888r '      x8.^'*88*'  ="8888f8888r    us888u.   .@88u    888R   
'*888!X8888> X8888  xH8>   ''888E'   4888>'88"    4888>'88"   888R I888>   4888>'88"   '-:- X8888x         4888>'88"  .@88 "8888" ''888E'   888R   
  '?8 '8888  X888X X888>     888E    4888> '      4888> '     888R I888>   4888> '          488888>        4888> '    9888  9888    888E    888R   
  -^  '888"  X888  8888>     888E    4888>        4888>       888R I888>   4888>          .. '"88*         4888>      9888  9888    888E    888R   
   dx '88~x. !88~  8888>     888E   .d888L .+    .d888L .+   u8888cJ888   .d888L .+     x88888nX"      .  .d888L .+   9888  9888    888E    888R   
 .8888Xf.888x:!    X888X.:   888&   ^"8888*"     ^"8888*"     "*888*P"    ^"8888*"     !"*8888888n..  :   ^"8888*"    9888  9888    888&   .888B . 
:""888":~"888"     '888*"    R888"     "Y"          "Y"         'Y"          "Y"      '    "*88888888*       "Y"      "888*""888"   R888"  ^*888%  
    "~'    "~        ""       ""                                                              ^"***"'                  ^Y"   ^Y'     ""      "%    
                                                                                                                                                   
                                                                                                                                                   
                                                                                                                                                           
BANNER

# --- Dependency Checks ---
echo "[*] Checking dependencies..."
if ! command -v subfinder &>/dev/null; then
    echo "[ERR] subfinder not found. Install: sudo apt install -y subfinder"
    exit 1
fi
if ! command -v amass &>/dev/null; then
    echo "[ERR] amass not found. Install: sudo apt install -y amass"
    exit 1
fi
if ! command -v httpx-toolkit &>/dev/null; then
    echo "[ERR] httpx-toolkit not found. Install: sudo apt install -y httpx-toolkit"
    exit 1
fi
if ! command -v nuclei &>/dev/null; then
    echo "[ERR] nuclei not found. Install: sudo apt install -y nuclei"
    exit 1
fi
echo "[+] All dependencies OK."
echo ""

# --- Setup & Variables ---
TARGET_FILE="target.txt"
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
touch "$OUTPUT_DIR/subfinder.txt"
touch "$OUTPUT_DIR/amass.txt"
subfinder -dL "$TARGET_FILE" -silent -o "$OUTPUT_DIR/subfinder.txt"
amass enum -passive -df "$TARGET_FILE" -o "$OUTPUT_DIR/amass.txt" 2>/dev/null

# Combine and deduplicate
cat "$OUTPUT_DIR/subfinder.txt" "$OUTPUT_DIR/amass.txt" | sort -u > "$OUTPUT_DIR/all_subs.txt"
echo "[+] Total subdomains found: $(wc -l < "$OUTPUT_DIR/all_subs.txt")"

# --- 2. Live Host Discovery (The Filter) ---
echo "[+] Probing for live HTTP/HTTPS services..."
touch "$OUTPUT_DIR/live_hosts.txt"
cat "$OUTPUT_DIR/all_subs.txt" | httpx-toolkit \
    -title \
    -tech-detect \
    -status-code \
    -follow-redirects \
    -c 50 \
    -silent \
    -o "$OUTPUT_DIR/live_hosts.txt"
echo "[+] Live hosts found: $(wc -l < "$OUTPUT_DIR/live_hosts.txt")"

# --- 3. Vulnerability Scanning (Targeted) ---
echo "[+] Running Nuclei templates (Critical/High/Exposures)..."
touch "$OUTPUT_DIR/nuclei_results.txt"
if [[ ! -s "$OUTPUT_DIR/live_hosts.txt" ]]; then
    echo "[WRN] No live hosts found, skipping Nuclei."
else
    nuclei -l "$OUTPUT_DIR/live_hosts.txt" \
        -severity critical,high \
        -tags exposure,misconfiguration,cve \
        -rate-limit 15 \
        -o "$OUTPUT_DIR/nuclei_results.txt"
fi

# --- 4. Summary ---
echo ""
echo "---"
echo "[+] Recon complete."
echo "[>] Results saved in: $OUTPUT_DIR"
echo "[>] Live hosts: $(wc -l < "$OUTPUT_DIR/live_hosts.txt")"
echo "[>] Nuclei findings: $(wc -l < "$OUTPUT_DIR/nuclei_results.txt")"
