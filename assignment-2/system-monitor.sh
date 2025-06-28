#!/bin/bash

# System Health Monitoring Script
LOG_FILE="./system-health.log"
ALERT_LOG="./system-alerts.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Add timestamp
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting System Health Monitor" | tee -a "$LOG_FILE"

# CPU Check - Only show if > 80%
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}' | cut -d. -f1)
if [ "$cpu_usage" -gt 80 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - CPU Usage: ${cpu_usage}%" | tee -a "$LOG_FILE"
    echo -e "${RED}ALERT: High CPU usage detected: ${cpu_usage}%${NC}" | tee -a "$ALERT_LOG"
fi

# Memory Check - Threshold 50%
memory_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
if [ "$memory_usage" -gt 50 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Memory Usage: ${memory_usage}%" | tee -a "$LOG_FILE"
    echo -e "${RED}ALERT: High memory usage detected: ${memory_usage}%${NC}" | tee -a "$ALERT_LOG"
fi

# Disk Check - Threshold 50%
disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$disk_usage" -gt 50 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Disk Usage: ${disk_usage}%" | tee -a "$LOG_FILE"
    echo -e "${RED}ALERT: High disk usage detected: ${disk_usage}%${NC}" | tee -a "$ALERT_LOG"
fi

# Process Check
critical_processes=("systemd" "init")
for process in "${critical_processes[@]}"; do
    if ! pgrep "$process" > /dev/null; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Critical process not running: $process" | tee -a "$LOG_FILE"
        echo -e "${RED}ALERT: Critical process not running: $process${NC}" | tee -a "$ALERT_LOG"
    fi
done

echo "$(date '+%Y-%m-%d %H:%M:%S') - System health check completed" | tee -a "$LOG_FILE"
echo "------" | tee -a "$LOG_FILE"