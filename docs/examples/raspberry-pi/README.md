# Raspberry Pi Examples for Gemini CLI

This directory contains helper scripts and configuration files for running
Gemini CLI on Raspberry Pi and other ARM-based devices.

## Scripts

### 1. System Monitoring (`monitor-system.sh`)

Real-time system resource monitoring script that tracks:

- CPU and GPU temperature
- CPU usage and frequency
- Memory and disk usage
- Thermal throttling status
- Gemini CLI process status

**Usage:**

```bash
# Basic usage with default settings
./monitor-system.sh

# Custom refresh interval (5 seconds)
./monitor-system.sh --interval 5

# Custom temperature threshold (65°C warning)
./monitor-system.sh --threshold 65

# Log to file
./monitor-system.sh --log /var/log/system-monitor.log

# Show help
./monitor-system.sh --help
```

**Features:**

- Color-coded temperature warnings
- Real-time throttling detection
- Process-specific monitoring for Gemini CLI
- Optional file logging
- Low resource overhead

### 2. Temperature Guard (`temp-guard.sh`)

Automated temperature management that protects your Raspberry Pi from
overheating by managing process priority and execution.

**Usage:**

```bash
# Warn only mode (default)
./temp-guard.sh

# Reduce process priority when hot
./temp-guard.sh --action nice

# Pause process at critical temperature (requires sudo)
sudo ./temp-guard.sh --action pause

# Custom thresholds
./temp-guard.sh --threshold 70 --critical 80

# Monitor different process
./temp-guard.sh --process "node" --action nice

# Show help
./temp-guard.sh --help
```

**Actions:**

- `warn` - Log warnings only (no process intervention)
- `nice` - Reduce process priority when temperature exceeds threshold
- `pause` - Pause process when critical temperature reached (requires sudo)

**Features:**

- Configurable temperature thresholds
- Multiple protection strategies
- Automatic recovery when temperature normalizes
- Comprehensive logging
- Safe process management

### 3. Backup Script (`backup-gemini.sh`)

Creates timestamped backups of your Gemini CLI configuration, settings, and
related data.

**Usage:**

```bash
# Basic backup with default settings
./backup-gemini.sh

# Custom backup directory
./backup-gemini.sh --output-dir /mnt/backup

# Keep more backups
./backup-gemini.sh --keep-backups 10

# Include cache directory
./backup-gemini.sh --include-cache

# No compression
./backup-gemini.sh --no-compress

# Show help
./backup-gemini.sh --help
```

**What gets backed up:**

- `~/.gemini/` - Gemini CLI configuration and settings
- `~/.gitconfig` - Git configuration
- `~/.ssh/config` - SSH configuration (excluding private keys)
- Global npm packages list

**Features:**

- Automatic rotation (keeps 5 most recent by default)
- Optional compression
- Restore instructions in output
- Safe handling of sensitive files

### 4. Systemd Service (`gemini-cli.service`)

Example systemd service configuration for running Gemini CLI as a system
service.

**Installation:**

```bash
# 1. Edit the service file
nano gemini-cli.service
# Update User, WorkingDirectory, and Environment variables

# 2. Copy to systemd directory
sudo cp gemini-cli.service /etc/systemd/system/

# 3. Reload systemd
sudo systemctl daemon-reload

# 4. Enable service (start on boot)
sudo systemctl enable gemini-cli

# 5. Start service
sudo systemctl start gemini-cli

# 6. Check status
sudo systemctl status gemini-cli

# 7. View logs
sudo journalctl -u gemini-cli -f
```

**Features:**

- Automatic restart on failure
- Resource limits (CPU, memory)
- Security hardening
- Logging to systemd journal
- Lower process priority to prevent system impact

## Configuration Examples

### Crontab Automation

Add automated monitoring and backups to crontab:

```bash
# Edit crontab
crontab -e

# Add these lines:
# Monitor system every hour and log
0 * * * * /home/pi/gemini-scripts/monitor-system.sh --interval 1 --log /var/log/system-monitor.log &

# Backup Gemini CLI configuration daily at 2 AM
0 2 * * * /home/pi/gemini-scripts/backup-gemini.sh --output-dir /mnt/backup

# Run temperature guard continuously (start on reboot)
@reboot /home/pi/gemini-scripts/temp-guard.sh --action nice --log /var/log/temp-guard.log &
```

### Running Multiple Scripts Together

Create a master script to run monitoring and temperature protection:

```bash
#!/bin/bash
# start-gemini-services.sh

# Start temperature guard in background
./temp-guard.sh --action nice --threshold 75 &
TEMP_GUARD_PID=$!

# Start Gemini CLI
gemini

# Cleanup on exit
kill $TEMP_GUARD_PID 2>/dev/null
```

## Quick Start Guide

1. **Download scripts:**

   ```bash
   mkdir -p ~/gemini-scripts
   cd ~/gemini-scripts

   # Download all scripts from repository
   wget https://raw.githubusercontent.com/google-gemini/gemini-cli/main/docs/examples/raspberry-pi/monitor-system.sh
   wget https://raw.githubusercontent.com/google-gemini/gemini-cli/main/docs/examples/raspberry-pi/temp-guard.sh
   wget https://raw.githubusercontent.com/google-gemini/gemini-cli/main/docs/examples/raspberry-pi/backup-gemini.sh

   # Make executable
   chmod +x *.sh
   ```

2. **Test monitoring:**

   ```bash
   ./monitor-system.sh
   ```

3. **Set up temperature protection:**

   ```bash
   # Test in one terminal
   ./temp-guard.sh --action nice

   # Then add to startup via crontab or systemd
   ```

4. **Create initial backup:**
   ```bash
   ./backup-gemini.sh
   ```

## Troubleshooting

### Script Permission Denied

```bash
chmod +x script-name.sh
```

### Temperature Monitoring Not Working

Ensure `vcgencmd` is available:

```bash
# Test
vcgencmd measure_temp

# If not found, install
sudo apt-get install libraspberrypi-bin
```

### Logs Not Writing

Check file permissions:

```bash
# For user logs
mkdir -p ~/logs
./monitor-system.sh --log ~/logs/monitor.log

# For system logs (requires sudo)
sudo ./temp-guard.sh --log /var/log/temp-guard.log
```

### Process Not Found

Verify Gemini CLI is running:

```bash
ps aux | grep gemini
```

## Resource Requirements

- **monitor-system.sh**: ~5MB RAM, negligible CPU
- **temp-guard.sh**: ~3MB RAM, negligible CPU
- **backup-gemini.sh**: Temporary spike during backup creation

All scripts are designed to have minimal impact on system resources.

## Contributing

Improvements and additional scripts are welcome! Please submit pull requests to
the main Gemini CLI repository.

## License

All scripts are licensed under Apache License 2.0. See individual file headers
for details.

## Support

For issues or questions:

- [Gemini CLI Documentation](../../README.md)
- [Raspberry Pi Deployment Guide](../get-started/raspberry-pi.md)
- [GitHub Issues](https://github.com/google-gemini/gemini-cli/issues)
