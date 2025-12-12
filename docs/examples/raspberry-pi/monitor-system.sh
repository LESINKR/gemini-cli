#!/bin/bash

# Copyright 2025 Google LLC
# SPDX-License-Identifier: Apache-2.0

# monitor-system.sh - System resource monitoring for Raspberry Pi
# 
# This script monitors CPU/GPU temperature, resource usage, and throttling
# on Raspberry Pi devices running Gemini CLI.
#
# Usage: ./monitor-system.sh [--interval SECONDS] [--threshold TEMP]
#
# Options:
#   --interval SECONDS    Refresh interval in seconds (default: 2)
#   --threshold TEMP      Temperature threshold for warnings in Celsius (default: 70)
#   --log FILE           Log output to file in addition to console

set -e

# Default configuration
REFRESH_INTERVAL=2
TEMP_WARNING=70
TEMP_CRITICAL=80
LOG_FILE=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --interval)
            REFRESH_INTERVAL="$2"
            shift 2
            ;;
        --threshold)
            TEMP_WARNING="$2"
            shift 2
            ;;
        --log)
            LOG_FILE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [--interval SECONDS] [--threshold TEMP] [--log FILE]"
            echo ""
            echo "Monitor Raspberry Pi system resources for Gemini CLI"
            echo ""
            echo "Options:"
            echo "  --interval SECONDS    Refresh interval (default: 2)"
            echo "  --threshold TEMP      Warning temperature in °C (default: 70)"
            echo "  --log FILE           Log to file"
            echo "  --help               Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# ANSI color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to log to file if enabled
log_to_file() {
    if [ -n "$LOG_FILE" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    fi
}

# Function to get CPU temperature
get_cpu_temp() {
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        echo $(( $(cat /sys/class/thermal/thermal_zone0/temp) / 1000 ))
    else
        echo "N/A"
    fi
}

# Function to get GPU temperature (VideoCore)
get_gpu_temp() {
    if command -v vcgencmd &> /dev/null; then
        temp=$(vcgencmd measure_temp 2>/dev/null | sed 's/temp=//' | sed "s/'C//" | sed 's/°C//')
        echo "${temp}"
    else
        echo "N/A"
    fi
}

# Function to check throttling status
check_throttling() {
    if command -v vcgencmd &> /dev/null; then
        throttled=$(vcgencmd get_throttled 2>/dev/null)
        if [[ $throttled == *"0x0"* ]]; then
            echo -e "${GREEN}No throttling${NC}"
            log_to_file "No throttling detected"
        else
            echo -e "${RED}Throttling detected: $throttled${NC}"
            log_to_file "WARNING: Throttling detected - $throttled"
        fi
    else
        echo "N/A"
    fi
}

# Function to get CPU usage
get_cpu_usage() {
    # Get CPU usage from /proc/stat
    cpu_line=$(head -n 1 /proc/stat)
    cpu_values=($cpu_line)
    
    # Calculate total and idle time
    total=0
    for value in "${cpu_values[@]:1}"; do
        total=$((total + value))
    done
    
    idle=${cpu_values[4]}
    
    # Calculate usage percentage
    if [ -n "$prev_total" ] && [ -n "$prev_idle" ]; then
        diff_total=$((total - prev_total))
        diff_idle=$((idle - prev_idle))
        
        if [ $diff_total -gt 0 ]; then
            cpu_usage=$((100 * (diff_total - diff_idle) / diff_total))
            echo "${cpu_usage}%"
        else
            echo "0%"
        fi
    else
        echo "N/A"
    fi
    
    prev_total=$total
    prev_idle=$idle
}

# Function to get memory usage
get_memory_usage() {
    free -m | awk 'NR==2{printf "%d/%dMB (%.1f%%)", $3, $2, $3*100/$2 }'
}

# Function to get disk usage
get_disk_usage() {
    df -h / | awk 'NR==2{print $3"/"$2" ("$5")"}'
}

# Function to get system uptime
get_uptime() {
    uptime -p | sed 's/up //'
}

# Function to get current CPU frequency
get_cpu_freq() {
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ]; then
        freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
        freq_mhz=$((freq / 1000))
        echo "${freq_mhz}MHz"
    else
        echo "N/A"
    fi
}

# Function to get CPU governor
get_cpu_governor() {
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
        cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    else
        echo "N/A"
    fi
}

# Function to check if Gemini CLI is running
check_gemini_running() {
    if pgrep -f "gemini" > /dev/null; then
        echo -e "${GREEN}Running${NC}"
        log_to_file "Gemini CLI is running"
    else
        echo -e "${YELLOW}Not running${NC}"
    fi
}

# Function to get Gemini CLI process stats
get_gemini_stats() {
    pid=$(pgrep -f "gemini" | head -n 1)
    if [ -n "$pid" ]; then
        # Get memory usage of the process
        mem_usage=$(ps -p $pid -o rss= 2>/dev/null | awk '{printf "%.1fMB", $1/1024}')
        # Get CPU usage of the process
        cpu_usage=$(ps -p $pid -o %cpu= 2>/dev/null | awk '{printf "%.1f%%", $1}')
        echo "PID: $pid | CPU: $cpu_usage | Mem: $mem_usage"
    else
        echo "N/A"
    fi
}

# Trap Ctrl+C for clean exit
trap 'echo -e "\n${CYAN}Monitoring stopped${NC}"; exit 0' INT TERM

# Main monitoring loop
echo -e "${CYAN}=== Raspberry Pi System Monitor ===${NC}"
echo "Monitoring interval: ${REFRESH_INTERVAL}s"
echo "Temperature warning threshold: ${TEMP_WARNING}°C"
echo "Temperature critical threshold: ${TEMP_CRITICAL}°C"
if [ -n "$LOG_FILE" ]; then
    echo "Logging to: $LOG_FILE"
    log_to_file "=== Monitoring started ==="
fi
echo ""
echo "Press Ctrl+C to exit"
echo ""

# Initialize variables for CPU usage calculation
prev_total=0
prev_idle=0

while true; do
    # Clear screen only if not logging to file or in CI
    if [ -z "$CI" ]; then
        clear
    fi
    
    echo -e "${CYAN}=== System Resource Monitor ===${NC}"
    echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # System info
    echo -e "${BLUE}--- System Info ---${NC}"
    echo "Uptime: $(get_uptime)"
    echo "CPU Governor: $(get_cpu_governor)"
    echo "CPU Frequency: $(get_cpu_freq)"
    echo ""
    
    # Temperature monitoring
    echo -e "${BLUE}--- Temperature ---${NC}"
    cpu_temp=$(get_cpu_temp)
    if [ "$cpu_temp" != "N/A" ]; then
        if [ "$cpu_temp" -ge "$TEMP_CRITICAL" ]; then
            echo -e "CPU Temp: ${RED}${cpu_temp}°C [CRITICAL]${NC}"
            log_to_file "CRITICAL: CPU temperature at ${cpu_temp}°C"
        elif [ "$cpu_temp" -ge "$TEMP_WARNING" ]; then
            echo -e "CPU Temp: ${YELLOW}${cpu_temp}°C [WARNING]${NC}"
            log_to_file "WARNING: CPU temperature at ${cpu_temp}°C"
        else
            echo -e "CPU Temp: ${GREEN}${cpu_temp}°C [OK]${NC}"
        fi
    else
        echo "CPU Temp: N/A"
    fi
    
    # GPU Temperature
    gpu_temp=$(get_gpu_temp)
    if [ "$gpu_temp" != "N/A" ]; then
        echo "GPU Temp: ${gpu_temp}°C"
    else
        echo "GPU Temp: N/A"
    fi
    
    # Throttling status
    echo -n "Throttling: "
    check_throttling
    echo ""
    
    # Resource usage
    echo -e "${BLUE}--- Resource Usage ---${NC}"
    echo "CPU Usage: $(get_cpu_usage)"
    echo "Memory: $(get_memory_usage)"
    echo "Disk: $(get_disk_usage)"
    echo ""
    
    # Gemini CLI status
    echo -e "${BLUE}--- Gemini CLI ---${NC}"
    echo -n "Status: "
    check_gemini_running
    gemini_stats=$(get_gemini_stats)
    if [ "$gemini_stats" != "N/A" ]; then
        echo "Stats: $gemini_stats"
    fi
    echo ""
    
    echo -e "${CYAN}Press Ctrl+C to exit | Refresh: ${REFRESH_INTERVAL}s${NC}"
    
    sleep "$REFRESH_INTERVAL"
done
