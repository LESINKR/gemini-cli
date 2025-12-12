# Gemini CLI on Raspberry Pi

This guide provides comprehensive instructions for running Gemini CLI on
Raspberry Pi and other ARM-based devices, including resource monitoring, SSH
configuration, and best practices for optimal performance.

## Prerequisites

### Hardware Requirements

- **Raspberry Pi 4 or newer** (recommended)
  - Minimum: 4GB RAM
  - Recommended: 8GB RAM for better performance
- **Storage**: Minimum 16GB SD card or SSD (SSD strongly recommended for better
  performance)
- **Cooling**: Active cooling (fan) recommended to prevent thermal throttling
- **Network**: Ethernet connection recommended for stability

### Software Requirements

- **Operating System**: Raspberry Pi OS (64-bit) or Ubuntu Server 22.04+ for ARM
- **Node.js**: Version 20 or higher
- **SSH**: Enabled for remote access

## Installation

### 1. System Setup

First, update your system and install required dependencies:

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify Node.js installation
node --version  # Should be v20.x or higher
npm --version

# Install additional tools
sudo apt-get install -y git curl build-essential
```

### 2. SSH Configuration

Enable and secure SSH access to your Raspberry Pi:

```bash
# Enable SSH if not already enabled
sudo systemctl enable ssh
sudo systemctl start ssh

# Configure SSH for better security
sudo nano /etc/ssh/sshd_config
```

Add or modify these settings in `/etc/ssh/sshd_config`:

```
# Change default SSH port (optional but recommended)
Port 2222

# Disable root login
PermitRootLogin no

# Enable public key authentication
PubkeyAuthentication yes

# Disable password authentication (after setting up keys)
PasswordAuthentication no

# Allow only specific users (replace 'pi' with your username)
AllowUsers pi
```

Restart SSH service:

```bash
sudo systemctl restart ssh
```

#### Setting up SSH Keys

On your local machine, generate and copy SSH keys:

```bash
# Generate SSH key pair (if you don't have one)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy public key to Raspberry Pi (replace with your Pi's IP and port)
ssh-copy-id -p 2222 pi@192.168.1.100

# Test SSH connection
ssh -p 2222 pi@192.168.1.100
```

### 3. Install Gemini CLI

Install Gemini CLI globally:

```bash
# Install globally
npm install -g @google/gemini-cli

# Verify installation
gemini --version
```

Alternatively, for lighter resource usage, run without installation:

```bash
# Run with npx (no global install needed)
npx @google/gemini-cli
```

## Resource Monitoring

Raspberry Pi devices can experience thermal throttling and performance issues
under heavy load. Use the included monitoring script to track system resources.

### System Monitoring Script

Create a monitoring script to track CPU/GPU temperature and usage:

```bash
# Create scripts directory
mkdir -p ~/gemini-scripts
cd ~/gemini-scripts

# Download the monitoring script
curl -o monitor-system.sh https://raw.githubusercontent.com/google-gemini/gemini-cli/main/docs/examples/raspberry-pi/monitor-system.sh
chmod +x monitor-system.sh
```

Or create it manually:

```bash
#!/bin/bash
# monitor-system.sh - System resource monitoring for Raspberry Pi

set -e

# ANSI color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Temperature thresholds (Celsius)
TEMP_WARNING=70
TEMP_CRITICAL=80

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
        vcgencmd measure_temp | sed 's/temp=//' | sed 's/°C//'
    else
        echo "N/A"
    fi
}

# Function to check throttling status
check_throttling() {
    if command -v vcgencmd &> /dev/null; then
        throttled=$(vcgencmd get_throttled)
        if [[ $throttled == *"0x0"* ]]; then
            echo -e "${GREEN}No throttling${NC}"
        else
            echo -e "${RED}Throttling detected: $throttled${NC}"
        fi
    else
        echo "N/A"
    fi
}

# Function to get CPU usage
get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}'
}

# Function to get memory usage
get_memory_usage() {
    free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2 }'
}

# Function to get disk usage
get_disk_usage() {
    df -h / | awk 'NR==2{print $5}'
}

# Main monitoring loop
echo "=== Raspberry Pi System Monitor ==="
echo "Press Ctrl+C to exit"
echo ""

while true; do
    clear
    echo "=== System Resource Monitor ==="
    echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    # CPU Temperature
    cpu_temp=$(get_cpu_temp)
    if [ "$cpu_temp" != "N/A" ]; then
        if [ "$cpu_temp" -ge "$TEMP_CRITICAL" ]; then
            echo -e "CPU Temp: ${RED}${cpu_temp}°C [CRITICAL]${NC}"
        elif [ "$cpu_temp" -ge "$TEMP_WARNING" ]; then
            echo -e "CPU Temp: ${YELLOW}${cpu_temp}°C [WARNING]${NC}"
        else
            echo -e "CPU Temp: ${GREEN}${cpu_temp}°C [OK]${NC}"
        fi
    else
        echo "CPU Temp: N/A"
    fi

    # GPU Temperature
    gpu_temp=$(get_gpu_temp)
    echo "GPU Temp: ${gpu_temp}°C"

    # Throttling status
    echo -n "Throttling: "
    check_throttling

    # System resources
    echo ""
    echo "CPU Usage: $(get_cpu_usage)"
    echo "Memory Usage: $(get_memory_usage)"
    echo "Disk Usage: $(get_disk_usage)"

    echo ""
    echo "Press Ctrl+C to exit"

    sleep 2
done
```

Run the monitor:

```bash
./monitor-system.sh
```

### Automatic Temperature Management

Create a service to automatically throttle Gemini CLI when temperature is high:

```bash
#!/bin/bash
# temp-guard.sh - Automatically pause Gemini CLI if temperature exceeds threshold

TEMP_THRESHOLD=75
CHECK_INTERVAL=10

while true; do
    cpu_temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
    cpu_temp=$((cpu_temp / 1000))

    if [ $cpu_temp -gt $TEMP_THRESHOLD ]; then
        echo "Warning: CPU temperature ${cpu_temp}°C exceeds threshold ${TEMP_THRESHOLD}°C"
        # Optionally pause or throttle processes here
        # pkill -STOP -f gemini  # Pause Gemini CLI
        sleep 30
        # pkill -CONT -f gemini  # Resume Gemini CLI
    fi

    sleep $CHECK_INTERVAL
done
```

## Performance Optimization

### 1. Memory Management

Configure swap space for better memory handling:

```bash
# Check current swap
free -h

# Increase swap if needed (2GB example)
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
# Set CONF_SWAPSIZE=2048
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

### 2. Use Lightweight Models

When running Gemini CLI on Raspberry Pi, prefer lighter models:

```bash
# Use Gemini 2.5 Flash for faster responses
gemini -m gemini-2.5-flash

# Or set as default in ~/.gemini/settings.json
{
  "model": "gemini-2.5-flash"
}
```

### 3. Limit Context Size

Reduce memory usage by limiting context:

```bash
# Limit included directories
gemini --max-file-size 100000 --exclude-patterns "node_modules/**,dist/**"
```

### 4. Disable Sandboxing

On resource-constrained devices, consider disabling Docker sandboxing:

```bash
# Run without sandbox
export GEMINI_SANDBOX=false
gemini
```

**Note**: Only disable sandboxing in trusted environments.

## Running as a System Service

Create a systemd service to run Gemini CLI automatically:

```bash
sudo nano /etc/systemd/system/gemini-cli.service
```

Add the following content:

```ini
[Unit]
Description=Gemini CLI Service
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi
Environment="PATH=/usr/bin:/usr/local/bin"
Environment="GEMINI_API_KEY=your_api_key_here"
Environment="GEMINI_SANDBOX=false"
ExecStart=/usr/local/bin/gemini --headless
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

# Resource limits
MemoryLimit=2G
CPUQuota=75%

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable gemini-cli
sudo systemctl start gemini-cli

# Check status
sudo systemctl status gemini-cli

# View logs
sudo journalctl -u gemini-cli -f
```

## Docker on Raspberry Pi

If you want to use Docker for sandboxing on Raspberry Pi:

### Install Docker

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Reboot or log out/in for changes to take effect
```

### Build ARM-compatible Sandbox Image

Modify the Dockerfile for ARM architecture:

```dockerfile
FROM arm64v8/node:20-slim

# ... rest of Dockerfile content
```

Build the image:

```bash
# Build for ARM64
docker build -t gemini-cli-sandbox:arm64 -f Dockerfile .

# Run with Gemini CLI
export GEMINI_SANDBOX=docker
gemini --sandbox
```

## Troubleshooting

### Issue: Thermal Throttling

**Symptoms**: Slow performance, system freezing

**Solutions**:

1. Add active cooling (fan)
2. Reduce ambient temperature
3. Apply heatsinks to CPU/RAM
4. Lower CPU governor:
   ```bash
   # Set CPU governor to powersave
   echo "powersave" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
   ```

### Issue: Out of Memory

**Symptoms**: Process killed, Node.js heap errors

**Solutions**:

1. Increase swap space
2. Use lighter model (gemini-2.5-flash)
3. Reduce context size
4. Close other applications
5. Set Node.js memory limit:
   ```bash
   export NODE_OPTIONS="--max-old-space-size=2048"
   ```

### Issue: Slow Network Performance

**Symptoms**: Slow API responses, timeouts

**Solutions**:

1. Use Ethernet instead of Wi-Fi
2. Check network with `ping google.com`
3. Optimize DNS settings:
   ```bash
   # Add to /etc/resolv.conf
   nameserver 8.8.8.8
   nameserver 8.8.4.4
   ```

### Issue: SD Card Performance

**Symptoms**: Slow file operations, high I/O wait

**Solutions**:

1. Use SSD via USB 3.0 instead of SD card
2. Use high-quality, high-speed SD card (UHS-3 or better)
3. Reduce logging:
   ```bash
   export GEMINI_LOG_LEVEL=error
   ```

## Best Practices

1. **Use Ethernet**: Wired connection provides more stable performance
2. **Active Cooling**: Essential for sustained workloads
3. **SSD Storage**: Significantly improves performance over SD cards
4. **Monitor Resources**: Regularly check temperature and resource usage
5. **Lightweight Models**: Use Flash models instead of Pro when possible
6. **Limit Scope**: Keep working directory focused and exclude unnecessary files
7. **Regular Updates**: Keep OS and Gemini CLI updated
8. **Backup Configuration**: Save your `~/.gemini/settings.json`

## Remote Access Configuration

### Setting up Tailscale for Secure Remote Access

For secure remote access to your Raspberry Pi running Gemini CLI:

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Start Tailscale
sudo tailscale up

# Get Tailscale IP
tailscale ip -4
```

Now you can access your Pi securely from anywhere using the Tailscale IP.

### Port Forwarding (if needed)

If you need to expose Gemini CLI over the internet (not recommended without
proper security):

```bash
# Configure firewall
sudo apt-get install ufw
sudo ufw allow 2222/tcp  # SSH
sudo ufw enable

# Configure port forwarding on your router
# Forward external port to Pi's SSH port
```

## Example: Automated Backup Script

```bash
#!/bin/bash
# backup-gemini.sh - Backup Gemini CLI configuration

BACKUP_DIR="/home/pi/gemini-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Backup configuration
tar -czf "$BACKUP_DIR/gemini-config-$TIMESTAMP.tar.gz" \
    ~/.gemini/ \
    ~/.gitconfig 2>/dev/null

# Keep only last 5 backups
ls -t "$BACKUP_DIR"/gemini-config-*.tar.gz | tail -n +6 | xargs -r rm

echo "Backup completed: $BACKUP_DIR/gemini-config-$TIMESTAMP.tar.gz"
```

## Additional Resources

- [Official Gemini CLI Documentation](../README.md)
- [Raspberry Pi Documentation](https://www.raspberrypi.org/documentation/)
- [Node.js on ARM](https://nodejs.org/en/download/)
- [Docker on Raspberry Pi](https://docs.docker.com/engine/install/debian/)

## Community Examples

Share your Raspberry Pi + Gemini CLI setup:

- [GitHub Discussions](https://github.com/google-gemini/gemini-cli/discussions)
- [Issue Tracker](https://github.com/google-gemini/gemini-cli/issues)

---

**Note**: Performance on Raspberry Pi will be lower than on desktop systems.
Adjust expectations and optimize settings accordingly.
