# LoRa Pi Gateway - Serial Reader

A Python-based serial communication module for LoRa Pi Gateway applications with Docker support.

## Features

- **Serial Communication**: Read/write data from serial ports
- **Multiple Reading Modes**: Continuous, line-by-line, and byte-by-byte reading
- **Docker Support**: Containerized deployment with secure device access
- **Thread-Safe**: Non-blocking operations with callbacks
- **Error Handling**: Comprehensive logging and error recovery

## Quick Start

### Prerequisites
- Python 3.8+
- Docker (optional)
- Serial device (USB-to-Serial, LoRa module, etc.)

### Local Development
```bash
# Install dependencies
pip install -r requirements.txt

# Run the serial reader
python serial_reader.py
```

### Docker Deployment
```bash
# Build and run with secure device access
./run.sh run

# Or use Docker Compose
docker-compose up -d
```

## Usage Examples

### Basic Serial Reading
```python
from serial_reader import SerialReader

reader = SerialReader(port='/dev/ttyUSB0', baudrate=9600)
if reader.connect():
    data = reader.read_line()
    print(f"Received: {data}")
    reader.disconnect()
```

### Continuous Reading with Callback
```python
def data_callback(data):
    print(f"Received: {data.decode('utf-8')}")

reader = SerialReader(port='/dev/ttyUSB0', baudrate=9600)
reader.set_callback(data_callback)

if reader.connect():
    reader.start_reading()
    # Data automatically processed by callback
```

## Docker Options

### Secure Device Access
- **Specific Devices**: `docker-compose -f docker-compose-secure.yml up`
- **Dynamic Detection**: `docker-compose -f docker-compose-dynamic.yml up`

### Management Script
```bash
./run.sh help          # Show all commands
./run.sh run           # Build and run in background
./run.sh interactive   # Run interactively for debugging
./run.sh logs          # View container logs
./run.sh stop          # Stop container
```

## Configuration

### Serial Parameters
- **Port**: Device path (e.g., `/dev/ttyUSB0`, `COM3`)
- **Baudrate**: Communication speed (default: 9600)
- **Timeout**: Read timeout in seconds (default: 1.0)
- **Parity**: Parity setting (default: None)
- **Stop Bits**: Number of stop bits (default: 1)

### Environment Variables
- `DEFAULT_SERIAL_PORT`: First available serial device
- `ALL_SERIAL_PORTS`: Comma-separated list of all devices
- `PYTHONUNBUFFERED`: Ensure immediate output (set to 1)

## Troubleshooting

### Permission Issues
```bash
# Add user to dialout group
sudo usermod -a -G dialout $USER

# Check device permissions
ls -l /dev/ttyUSB0
```

### Device Not Found
```bash
# List available devices
ls -la /dev/tty*

# Check container logs
docker logs lora-serial-reader
```

## Security

For production use, prefer the secure Docker configurations:
- Use specific device mounting instead of `/dev:/dev`
- Run with non-root user
- Use dynamic device detection when possible

See [SERIAL_DEVICE_ACCESS.md](SERIAL_DEVICE_ACCESS.md) for detailed security information.

## License

This project is open source. Feel free to modify and distribute. 