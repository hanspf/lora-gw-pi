#!/bin/bash

# Raspberry Pi Serial Port Diagnostic Script
set -e

echo "=== Raspberry Pi Serial Port Diagnostic ==="
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo ""

# Check Raspberry Pi model
echo "=== Raspberry Pi Information ==="
if [ -f /proc/device-tree/model ]; then
    echo "Model: $(cat /proc/device-tree/model)"
else
    echo "Model: Unknown (not a Raspberry Pi or /proc not mounted)"
fi

# Check kernel version
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo ""

# Check serial devices
echo "=== Serial Device Check ==="
echo "All tty devices:"
ls -la /dev/tty* 2>/dev/null || echo "No tty devices found"

echo ""
echo "Common Raspberry Pi serial ports:"
for port in ttyAMA0 ttyS0 serial0 serial1 ttyUSB0 ttyACM0; do
    if [ -e "/dev/$port" ]; then
        echo "✓ /dev/$port exists"
        ls -l "/dev/$port"
    else
        echo "✗ /dev/$port does not exist"
    fi
done

echo ""
echo "=== UART Configuration ==="

# Check if UART is enabled in config.txt
if [ -f /boot/config.txt ]; then
    echo "Checking /boot/config.txt for UART settings:"
    if grep -q "enable_uart=1" /boot/config.txt; then
        echo "✓ enable_uart=1 found in config.txt"
    else
        echo "✗ enable_uart=1 not found in config.txt"
    fi
    
    if grep -q "dtoverlay=disable-bt" /boot/config.txt; then
        echo "✓ Bluetooth UART disabled (dtoverlay=disable-bt)"
    else
        echo "ℹ Bluetooth UART not disabled"
    fi
else
    echo "✗ /boot/config.txt not found"
fi

# Check if serial console is disabled
if [ -f /boot/cmdline.txt ]; then
    echo ""
    echo "Checking /boot/cmdline.txt for console settings:"
    if grep -q "console=serial0" /boot/cmdline.txt; then
        echo "⚠ Serial console is enabled (console=serial0)"
        echo "   This may interfere with your application"
    else
        echo "✓ Serial console is disabled"
    fi
else
    echo "✗ /boot/cmdline.txt not found"
fi

echo ""
echo "=== User Permissions ==="
echo "Current user: $(whoami)"
echo "User groups: $(groups)"

if groups | grep -q dialout; then
    echo "✓ User is in dialout group"
else
    echo "✗ User is NOT in dialout group"
    echo "  Run: sudo usermod -a -G dialout $USER"
fi

echo ""
echo "=== Device Permissions ==="
for port in ttyAMA0 ttyS0 serial0 serial1; do
    if [ -e "/dev/$port" ]; then
        perms=$(ls -l "/dev/$port" | awk '{print $1}')
        owner=$(ls -l "/dev/$port" | awk '{print $3}')
        group=$(ls -l "/dev/$port" | awk '{print $4}')
        echo "/dev/$port: $perms $owner:$group"
        
        if [ -r "/dev/$port" ] && [ -w "/dev/$port" ]; then
            echo "  ✓ Read/Write access: OK"
        else
            echo "  ✗ Read/Write access: FAILED"
        fi
    fi
done

echo ""
echo "=== Docker Check ==="
if command -v docker &> /dev/null; then
    echo "✓ Docker is installed"
    echo "Docker version: $(docker --version)"
    
    if docker info &> /dev/null; then
        echo "✓ Docker daemon is running"
    else
        echo "✗ Docker daemon is not running"
    fi
else
    echo "✗ Docker is not installed"
fi

echo ""
echo "=== Recommendations ==="
echo "1. If no serial devices found:"
echo "   - Enable UART in raspi-config"
echo "   - Add 'enable_uart=1' to /boot/config.txt"
echo "   - Reboot the Pi"
echo ""
echo "2. If permission issues:"
echo "   - Add user to dialout group: sudo usermod -a -G dialout $USER"
echo "   - Log out and back in"
echo ""
echo "3. If using built-in UART:"
echo "   - Disable serial console in raspi-config"
echo "   - Remove 'console=serial0' from /boot/cmdline.txt"
echo ""
echo "4. For Docker:"
echo "   - Use docker-compose-rpi.yml for Raspberry Pi specific configuration"
echo "   - Ensure devices are properly mounted"

echo ""
echo "=== End of Diagnostic ===" 