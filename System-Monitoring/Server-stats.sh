#!/bin/bash

# Color codes
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RESET='\033[0m'
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

separator="================================================================================"

# Function to colorize usage based on thresholds
colorize_usage() {
    local usage=$1
    if (( $(echo "$usage < 50" | bc -l) )); then
        echo -e "${GREEN}${usage}%${RESET}"
    elif (( $(echo "$usage < 80" | bc -l) )); then
        echo -e "${YELLOW}${usage}%${RESET}"
    else
        echo -e "${RED}${usage}%${RESET}"
    fi
}

print_header() {
    echo -e "\n${CYAN}${BOLD}$1${RESET}"
    echo "$separator"
}

# ------------------------ Uptime ------------------------

uptime_info=$(uptime -p | sed 's/up //')
print_header "🕒 Uptime"
echo -e "System Uptime   : ${YELLOW}${uptime_info}${RESET}"

# ------------------------ CPU Usage ------------------------

top_output=$(top -bn1)
cpu_idle=$(echo "$top_output" | grep "Cpu(s)" | sed 's/.*, *\([0-9.]*\)%* id.*/\1/')
cpu_usage=$(awk -v idle="$cpu_idle" 'BEGIN { printf("%.1f", 100 - idle) }')

print_header "🖥️  CPU Usage"
echo -e "Usage           : $(colorize_usage $cpu_usage)"

# ------------------------ Memory Usage ------------------------

read total_memory available_memory <<< $(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {print t, a}' /proc/meminfo)
used_memory=$((total_memory - available_memory))

used_memory_percent=$(awk -v u=$used_memory -v t=$total_memory 'BEGIN { printf("%.1f", (u / t) * 100) }')
free_memory_percent=$(awk -v a=$available_memory -v t=$total_memory 'BEGIN { printf("%.1f", (a / t) * 100) }')

# Convert from kB to MB 
total_memory_mb=$(awk -v t=$total_memory 'BEGIN { printf("%.1f", t/1024) }')
used_memory_mb=$(awk -v u=$used_memory 'BEGIN { printf("%.1f", u/1024) }')
available_memory_mb=$(awk -v a=$available_memory 'BEGIN { printf("%.1f", a/1024) }')

print_header "🧠 Memory Usage"
printf "Total Memory    : ${YELLOW}%-10s MB${RESET}\n" "$total_memory_mb"
printf "Used Memory     : ${YELLOW}%-10s MB${RESET} (%s)\n" "$used_memory_mb" "$(colorize_usage $used_memory_percent)"
printf "Free/Available  : ${YELLOW}%-10s MB${RESET} (%s%%)\n" "$available_memory_mb" "$free_memory_percent"

# ------------------------ Disk Usage ------------------------

df_output=$(df -h /)
read size_disk used_disk available_disk <<< $(echo "$df_output" | awk 'NR==2 {print $2, $3, $4}')

df_output_raw=$(df /)
read size_disk_kb used_disk_kb available_disk_kb <<< $(echo "$df_output_raw" | awk 'NR==2 {print $2, $3, $4}')

used_disk_percent=$(echo "scale=1; $used_disk_kb *100/$size_disk_kb" | bc)
available_disk_percent=$(echo "scale=1; $available_disk_kb *100/$size_disk_kb" | bc)

print_header "💾 Disk Usage"
printf "Disk Size       : ${YELLOW}%-10s${RESET}\n" "$size_disk"
printf "Used Space      : ${YELLOW}%-10s${RESET} (%s)\n" "$used_disk" "$(colorize_usage $used_disk_percent)"
printf "Available Space : ${YELLOW}%-10s${RESET} (%s%%)\n" "$available_disk" "$available_disk_percent"

# ------------------------ Top Processes ------------------------

print_header "🔥 Top 5 Processes by CPU"
ps -eo user,pid,%cpu,%mem,comm --sort=-%cpu | awk 'NR==1 || NR<=6 { printf "%-10s %-6s %-6s %-6s %s\n", $1, $2, $3, $4, $5 }'

print_header "🧠 Top 5 Processes by Memory"
ps -eo user,pid,%cpu,%mem,comm --sort=-%mem | awk 'NR==1 || NR<=6 { printf "%-10s %-6s %-6s %-6s %s\n", $1, $2, $3, $4, $5 }'
