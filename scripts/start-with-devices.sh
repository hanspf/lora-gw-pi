#!/bin/bash

# Script to dynamically mount serial devices and start the application
set -e

echo "=== Serial Device Detection and Mounting ==="

# Function to detect serial devices
detect_serial_devices() {
    echo "Scanning for serial devices..."
    
    # Find all serial devices
    SERIAL_DEVICES=()
    
    # USB serial devices
    for device in /dev/ttyUSB*; do
        if [ -e "$device" ]; then
            SERIAL_DEVICES+=("$device")
            echo "Found USB serial device: $device"
        fi
    done
    
    # ACM devices (Arduino, etc.)
    for device in /dev/ttyACM*; do
        if [ -e "$device" ]; then
            SERIAL_DEVICES+=("$device")
            echo "Found ACM device: $device"
        fi
    done
    
    # Standard serial ports
    for device in /dev/ttyS*; do
        if [ -e "$device" ]; then
            SERIAL_DEVICES+=("$device")
            echo "Found serial port: $device"
        fi
    done
    
    # Custom serial devices (if any)
    for device in /dev/tty*; do
        if [ -e "$device" ] && [[ "$device" =~ /dev/tty[A-Z][0-9]+ ]]; then
            if [[ ! " ${SERIAL_DEVICES[@]} " =~ " ${device} " ]]; then
                SERIAL_DEVICES+=("$device")
                echo "Found custom serial device: $device"
            fi
        fi
    done
    
    echo "Total serial devices found: ${#SERIAL_DEVICES[@]}"
}

# Function to create device nodes in container
create_device_nodes() {
    if [ ${#SERIAL_DEVICES[@]} -eq 0 ]; then
        echo "No serial devices found. Running without device access."
        return
    fi
    
    echo "Creating device nodes in container..."
    
    for device in "${SERIAL_DEVICES[@]}"; do
        if [ -e "$device" ]; then
            # Get device major/minor numbers
            DEVICE_INFO=$(stat -c "%t %T" "$device" 2>/dev/null || stat -f "%Hr %Lr" "$device" 2>/dev/null)
            if [ $? -eq 0 ]; then
                MAJOR=$(echo $DEVICE_INFO | cut -d' ' -f1)
                MINOR=$(echo $DEVICE_INFO | cut -d' ' -f2)
                
                # Convert hex to decimal
                MAJOR_DEC=$((16#$MAJOR))
                MINOR_DEC=$((16#$MINOR))
                
                echo "Creating device node: $device (major: $MAJOR_DEC, minor: $MINOR_DEC)"
                
                # Create device node in container
                mknod "$device" c $MAJOR_DEC $MINOR_DEC 2>/dev/null || true
                
                # Set permissions
                chmod 666 "$device" 2>/dev/null || true
            fi
        fi
    done
}

# Function to check device permissions
check_permissions() {
    echo "Checking device permissions..."
    
    for device in "${SERIAL_DEVICES[@]}"; do
        if [ -e "$device" ]; then
            PERMS=$(ls -l "$device" 2>/dev/null | awk '{print $1}')
            OWNER=$(ls -l "$device" 2>/dev/null | awk '{print $3}')
            GROUP=$(ls -l "$device" 2>/dev/null | awk '{print $4}')
            
            echo "Device: $device"
            echo "  Permissions: $PERMS"
            echo "  Owner: $OWNER"
            echo "  Group: $GROUP"
            
            # Check if we can read/write
            if [ -r "$device" ] && [ -w "$device" ]; then
                echo "  ✓ Read/Write access: OK"
            else
                echo "  ✗ Read/Write access: FAILED"
                echo "  Consider adding user to dialout group or using sudo"
            fi
        fi
    done
}

# Function to set environment variables
set_environment() {
    if [ ${#SERIAL_DEVICES[@]} -gt 0 ]; then
        # Set the first device as default
        export DEFAULT_SERIAL_PORT="${SERIAL_DEVICES[0]}"
        echo "Setting DEFAULT_SERIAL_PORT=$DEFAULT_SERIAL_PORT"
        
        # Create a comma-separated list of all devices
        ALL_DEVICES=$(IFS=','; echo "${SERIAL_DEVICES[*]}")
        export ALL_SERIAL_PORTS="$ALL_DEVICES"
        echo "Setting ALL_SERIAL_PORTS=$ALL_DEVICES"
    else
        export DEFAULT_SERIAL_PORT=""
        export ALL_SERIAL_PORTS=""
        echo "No serial devices available"
    fi
}

# Main execution
main() {
    echo "Starting serial device setup..."
    
    # Detect devices
    detect_serial_devices
    
    # Create device nodes
    create_device_nodes
    
    # Check permissions
    check_permissions
    
    # Set environment
    set_environment
    
    echo "=== Starting Application ==="
    
    # Start the Python application
    cd /app
    exec python serial_reader.py
}

# Run main function
main "$@" 