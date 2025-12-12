#!/bin/bash

# Copyright 2025 Google LLC
# SPDX-License-Identifier: Apache-2.0

# temp-guard.sh - Temperature-based process management for Raspberry Pi
#
# This script monitors system temperature and can pause/throttle processes
# when temperature exceeds defined thresholds to prevent thermal damage.
#
# Usage: ./temp-guard.sh [OPTIONS]
#
# Options:
#   --threshold TEMP     Temperature threshold in Celsius (default: 75)
#   --critical TEMP      Critical temperature threshold (default: 82)
#   --interval SECONDS   Check interval in seconds (default: 10)
#   --process NAME       Process name to manage (default: gemini)
#   --action ACTION      Action to take: pause|nice|warn (default: warn)
#   --log FILE          Log file path

set -e

# Default configuration
TEMP_THRESHOLD=75
TEMP_CRITICAL=82
CHECK_INTERVAL=10
PROCESS_NAME="gemini"
ACTION="warn"
LOG_FILE="/var/log/temp-guard.log"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --threshold)
            TEMP_THRESHOLD="$2"
            shift 2
            ;;
        --critical)
            TEMP_CRITICAL="$2"
            shift 2
            ;;
        --interval)
            CHECK_INTERVAL="$2"
            shift 2
            ;;
        --process)
            PROCESS_NAME="$2"
            shift 2
            ;;
        --action)
            ACTION="$2"
            shift 2
            ;;
        --log)
            LOG_FILE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Temperature guard for Raspberry Pi running Gemini CLI"
            echo ""
            echo "Options:"
            echo "  --threshold TEMP     Warning temperature in °C (default: 75)"
            echo "  --critical TEMP      Critical temperature in °C (default: 82)"
            echo "  --interval SECONDS   Check interval (default: 10)"
            echo "  --process NAME       Process to manage (default: gemini)"
            echo "  --action ACTION      Action: pause|nice|warn (default: warn)"
            echo "  --log FILE          Log file (default: /var/log/temp-guard.log)"
            echo "  --help              Show this help"
            echo ""
            echo "Actions:"
            echo "  warn   - Log warnings only (no process intervention)"
            echo "  nice   - Reduce process priority when hot"
            echo "  pause  - Pause process when critical (requires sudo)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Color codes for terminal output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# State variables
process_paused=false
process_niced=false

# Logging function
log_message() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log to file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Also print to console with colors
    case $level in
        ERROR)
            echo -e "${RED}[$timestamp] [ERROR] $message${NC}" >&2
            ;;
        WARN)
            echo -e "${YELLOW}[$timestamp] [WARN] $message${NC}"
            ;;
        INFO)
            echo -e "${GREEN}[$timestamp] [INFO] $message${NC}"
            ;;
        *)
            echo "[$timestamp] [$level] $message"
            ;;
    esac
}

# Get CPU temperature
get_cpu_temp() {
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        echo $(( $(cat /sys/class/thermal/thermal_zone0/temp) / 1000 ))
    else
        echo 0
    fi
}

# Get process PID
get_process_pid() {
    pgrep -f "$PROCESS_NAME" | head -n 1
}

# Pause process (requires sudo)
pause_process() {
    local pid=$1
    if [ -n "$pid" ]; then
        if kill -STOP "$pid" 2>/dev/null; then
            log_message "WARN" "Paused process $PROCESS_NAME (PID: $pid) due to critical temperature"
            process_paused=true
            return 0
        else
            log_message "ERROR" "Failed to pause process $pid (try running with sudo)"
            return 1
        fi
    fi
    return 1
}

# Resume process
resume_process() {
    local pid=$1
    if [ -n "$pid" ]; then
        if kill -CONT "$pid" 2>/dev/null; then
            log_message "INFO" "Resumed process $PROCESS_NAME (PID: $pid)"
            process_paused=false
            return 0
        else
            log_message "ERROR" "Failed to resume process $pid"
            return 1
        fi
    fi
    return 1
}

# Reduce process priority
reduce_priority() {
    local pid=$1
    if [ -n "$pid" ]; then
        if renice -n 19 -p "$pid" > /dev/null 2>&1; then
            log_message "WARN" "Reduced priority of $PROCESS_NAME (PID: $pid) due to high temperature"
            process_niced=true
            return 0
        else
            log_message "ERROR" "Failed to renice process $pid (try running with sudo)"
            return 1
        fi
    fi
    return 1
}

# Restore process priority
restore_priority() {
    local pid=$1
    if [ -n "$pid" ]; then
        if renice -n 0 -p "$pid" > /dev/null 2>&1; then
            log_message "INFO" "Restored priority of $PROCESS_NAME (PID: $pid)"
            process_niced=false
            return 0
        else
            log_message "ERROR" "Failed to restore priority for process $pid"
            return 1
        fi
    fi
    return 1
}

# Check if running with sufficient privileges for pause action
check_privileges() {
    if [ "$ACTION" = "pause" ] && [ "$EUID" -ne 0 ]; then
        log_message "WARN" "Action 'pause' requires root privileges. Run with sudo or use --action=nice"
    fi
}

# Cleanup on exit
cleanup() {
    log_message "INFO" "Temperature guard stopping..."
    
    # Restore process state if modified
    if [ "$process_paused" = true ]; then
        pid=$(get_process_pid)
        if [ -n "$pid" ]; then
            resume_process "$pid"
        fi
    fi
    
    if [ "$process_niced" = true ]; then
        pid=$(get_process_pid)
        if [ -n "$pid" ]; then
            restore_priority "$pid"
        fi
    fi
    
    exit 0
}

# Trap signals for cleanup
trap cleanup INT TERM EXIT

# Main function
main() {
    log_message "INFO" "Temperature guard started"
    log_message "INFO" "Configuration: threshold=${TEMP_THRESHOLD}°C, critical=${TEMP_CRITICAL}°C, interval=${CHECK_INTERVAL}s, action=${ACTION}"
    
    check_privileges
    
    echo -e "${CYAN}Temperature Guard Active${NC}"
    echo "Monitoring process: $PROCESS_NAME"
    echo "Warning threshold: ${TEMP_THRESHOLD}°C"
    echo "Critical threshold: ${TEMP_CRITICAL}°C"
    echo "Check interval: ${CHECK_INTERVAL}s"
    echo "Action: $ACTION"
    echo "Log file: $LOG_FILE"
    echo ""
    echo "Press Ctrl+C to stop"
    echo ""
    
    while true; do
        cpu_temp=$(get_cpu_temp)
        pid=$(get_process_pid)
        
        if [ "$cpu_temp" -ge "$TEMP_CRITICAL" ]; then
            # Critical temperature
            log_message "ERROR" "CRITICAL temperature: ${cpu_temp}°C (threshold: ${TEMP_CRITICAL}°C)"
            
            case $ACTION in
                pause)
                    if [ -n "$pid" ] && [ "$process_paused" = false ]; then
                        pause_process "$pid"
                    fi
                    ;;
                nice)
                    if [ -n "$pid" ] && [ "$process_niced" = false ]; then
                        reduce_priority "$pid"
                    fi
                    ;;
            esac
            
        elif [ "$cpu_temp" -ge "$TEMP_THRESHOLD" ]; then
            # Warning temperature
            log_message "WARN" "High temperature: ${cpu_temp}°C (threshold: ${TEMP_THRESHOLD}°C)"
            
            if [ "$ACTION" = "nice" ] && [ -n "$pid" ] && [ "$process_niced" = false ]; then
                reduce_priority "$pid"
            fi
            
        else
            # Normal temperature - restore if needed
            if [ "$process_paused" = true ] && [ -n "$pid" ]; then
                log_message "INFO" "Temperature normal: ${cpu_temp}°C - resuming process"
                resume_process "$pid"
            fi
            
            if [ "$process_niced" = true ] && [ -n "$pid" ]; then
                log_message "INFO" "Temperature normal: ${cpu_temp}°C - restoring priority"
                restore_priority "$pid"
            fi
        fi
        
        sleep "$CHECK_INTERVAL"
    done
}

# Create log file if it doesn't exist
touch "$LOG_FILE" 2>/dev/null || {
    LOG_FILE="/tmp/temp-guard.log"
    log_message "WARN" "Cannot write to /var/log, using $LOG_FILE instead"
}

# Run main function
main
