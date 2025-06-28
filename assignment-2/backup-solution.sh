#!/bin/bash

# Automated Backup Solution
# Creates compressed backups with success/failure reporting

SOURCE_DIR="$1"
BACKUP_NAME="$2"
BACKUP_DIR="./backups"
LOG_FILE="./backup.log"
REPORT_FILE="./backup-report.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to generate report
generate_report() {
    local status="$1"
    local backup_path="$2"
    local start_time="$3"
    local end_time="$4"
    
    local duration=$((end_time - start_time))
    local backup_size=""
    
    if [ -f "$backup_path" ]; then
        backup_size=$(du -h "$backup_path" | cut -f1)
    fi
    
    cat > "$REPORT_FILE" << EOF
=== Backup Report ===
Date: $(date)
Source: $SOURCE_DIR
Status: $status
Backup File: $backup_path
Backup Size: $backup_size
Duration: ${duration} seconds
=====================
EOF
    
    log_message "Backup report generated: $REPORT_FILE"
}

echo -e "${BLUE}Starting Automated Backup Solution...${NC}"

# Validate input
if [ -z "$SOURCE_DIR" ]; then
    echo -e "${RED}Usage: $0 <source_directory> [backup_name]${NC}"
    echo "Example: $0 /home/user/documents my_backup"
    exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}Error: Source directory '$SOURCE_DIR' doesn't exist${NC}"
    exit 1
fi

# Start timing
start_time=$(date +%s)
log_message "=== Backup process started ==="
log_message "Source directory: $SOURCE_DIR"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Create backup filename
timestamp=$(date '+%Y%m%d_%H%M%S')
if [ -n "$BACKUP_NAME" ]; then
    backup_filename="${BACKUP_NAME}_${timestamp}.tar.gz"
else
    dir_name=$(basename "$SOURCE_DIR")
    backup_filename="${dir_name}_backup_${timestamp}.tar.gz"
fi

backup_path="$BACKUP_DIR/$backup_filename"

log_message "Creating backup: $backup_path"
echo -e "${YELLOW}Creating backup: $backup_filename${NC}"

# Create compressed backup
if tar -czf "$backup_path" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")" 2>/dev/null; then
    end_time=$(date +%s)
    backup_size=$(du -h "$backup_path" | cut -f1)
    
    echo -e "${GREEN}✓ Backup created successfully${NC}"
    log_message "Backup created successfully"
    log_message "Backup size: $backup_size"
    log_message "Backup location: $backup_path"
    
    # Generate success report
    generate_report "SUCCESS" "$backup_path" "$start_time" "$end_time"
    
    echo -e "${GREEN}✓ Backup completed successfully${NC}"
    echo "Backup size: $backup_size"
    echo "Backup location: $backup_path"
    echo "Report: $REPORT_FILE"
    
else
    end_time=$(date +%s)
    echo -e "${RED}✗ Backup failed${NC}"
    log_message "ERROR: Backup creation failed"
    
    # Generate failure report
    generate_report "FAILED" "$backup_path" "$start_time" "$end_time"
    
    exit 1
fi

log_message "=== Backup process completed ==="