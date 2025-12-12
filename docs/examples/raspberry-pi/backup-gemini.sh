#!/bin/bash

# Copyright 2025 Google LLC
# SPDX-License-Identifier: Apache-2.0

# backup-gemini.sh - Backup Gemini CLI configuration and data
#
# This script creates backups of your Gemini CLI configuration,
# settings, and conversation history.
#
# Usage: ./backup-gemini.sh [OPTIONS]
#
# Options:
#   --output-dir DIR     Backup directory (default: ~/gemini-backups)
#   --keep-backups N     Number of backups to keep (default: 5)
#   --compress          Use compression (default: yes)
#   --include-cache     Include cache directory (default: no)

set -e

# Default configuration
BACKUP_DIR="$HOME/gemini-backups"
KEEP_BACKUPS=5
COMPRESS=true
INCLUDE_CACHE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --output-dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        --keep-backups)
            KEEP_BACKUPS="$2"
            shift 2
            ;;
        --compress)
            COMPRESS=true
            shift
            ;;
        --no-compress)
            COMPRESS=false
            shift
            ;;
        --include-cache)
            INCLUDE_CACHE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Backup Gemini CLI configuration and data"
            echo ""
            echo "Options:"
            echo "  --output-dir DIR      Backup directory (default: ~/gemini-backups)"
            echo "  --keep-backups N      Number of backups to keep (default: 5)"
            echo "  --compress           Use gzip compression (default)"
            echo "  --no-compress        Don't use compression"
            echo "  --include-cache      Include cache directory"
            echo "  --help               Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Generate timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="gemini-config-$TIMESTAMP"

# Temporary directory for staging
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo -e "${GREEN}Creating Gemini CLI backup...${NC}"
echo "Timestamp: $TIMESTAMP"
echo "Backup directory: $BACKUP_DIR"
echo ""

# Function to backup a file or directory
backup_item() {
    local source=$1
    local dest=$2
    
    if [ -e "$source" ]; then
        echo "  ✓ Backing up: $source"
        mkdir -p "$(dirname "$TEMP_DIR/$dest")"
        cp -r "$source" "$TEMP_DIR/$dest" 2>/dev/null || true
    else
        echo "  - Skipping (not found): $source"
    fi
}

# Backup Gemini configuration
echo "Backing up configuration files..."
backup_item "$HOME/.gemini" "gemini"

# Backup Git configuration (useful for Gemini CLI context)
if [ -f "$HOME/.gitconfig" ]; then
    backup_item "$HOME/.gitconfig" "gitconfig"
fi

# Backup SSH configuration (if exists)
if [ -d "$HOME/.ssh" ]; then
    echo "  ✓ Backing up SSH config (excluding private keys)"
    mkdir -p "$TEMP_DIR/ssh"
    # Only backup config and known_hosts, not private keys
    [ -f "$HOME/.ssh/config" ] && cp "$HOME/.ssh/config" "$TEMP_DIR/ssh/" 2>/dev/null || true
    [ -f "$HOME/.ssh/known_hosts" ] && cp "$HOME/.ssh/known_hosts" "$TEMP_DIR/ssh/" 2>/dev/null || true
    [ -f "$HOME/.ssh/authorized_keys" ] && cp "$HOME/.ssh/authorized_keys" "$TEMP_DIR/ssh/" 2>/dev/null || true
fi

# Backup npm global packages list
if command -v npm &> /dev/null; then
    echo "  ✓ Backing up npm global packages list"
    npm list -g --depth=0 > "$TEMP_DIR/npm-global-packages.txt" 2>/dev/null || true
fi

# Optionally backup cache
if [ "$INCLUDE_CACHE" = true ]; then
    echo "Backing up cache..."
    backup_item "$HOME/.gemini/cache" "gemini/cache"
fi

# Create backup archive
echo ""
echo "Creating archive..."

if [ "$COMPRESS" = true ]; then
    BACKUP_FILE="$BACKUP_DIR/${BACKUP_NAME}.tar.gz"
    tar -czf "$BACKUP_FILE" -C "$TEMP_DIR" . 2>/dev/null
    echo -e "${GREEN}✓ Compressed backup created: $BACKUP_FILE${NC}"
else
    BACKUP_FILE="$BACKUP_DIR/${BACKUP_NAME}.tar"
    tar -cf "$BACKUP_FILE" -C "$TEMP_DIR" . 2>/dev/null
    echo -e "${GREEN}✓ Backup created: $BACKUP_FILE${NC}"
fi

# Show backup size
BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "  Size: $BACKUP_SIZE"

# Clean up old backups
echo ""
echo "Cleaning up old backups (keeping $KEEP_BACKUPS most recent)..."
if [ "$COMPRESS" = true ]; then
    PATTERN="gemini-config-*.tar.gz"
else
    PATTERN="gemini-config-*.tar"
fi

BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/$PATTERN 2>/dev/null | wc -l)

if [ "$BACKUP_COUNT" -gt "$KEEP_BACKUPS" ]; then
    OLD_BACKUPS=$(ls -t "$BACKUP_DIR"/$PATTERN | tail -n +$((KEEP_BACKUPS + 1)))
    for backup in $OLD_BACKUPS; do
        echo "  Removing old backup: $(basename $backup)"
        rm -f "$backup"
    done
    echo -e "${GREEN}✓ Cleaned up $(echo "$OLD_BACKUPS" | wc -l) old backup(s)${NC}"
else
    echo "  No cleanup needed (total backups: $BACKUP_COUNT)"
fi

# Summary
echo ""
echo -e "${GREEN}=== Backup Complete ===${NC}"
echo "Backup file: $BACKUP_FILE"
echo "Backup size: $BACKUP_SIZE"
echo ""
echo "To restore this backup:"
if [ "$COMPRESS" = true ]; then
    echo "  tar -xzf $BACKUP_FILE -C ~/"
else
    echo "  tar -xf $BACKUP_FILE -C ~/"
fi
echo ""
echo "Recent backups:"
ls -lht "$BACKUP_DIR"/$PATTERN 2>/dev/null | head -n 5 || echo "  No backups found"
