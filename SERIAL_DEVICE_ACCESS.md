# Serial Device Access in Docker Containers

This document explains different approaches to make serial devices available to Docker containers, ordered from least to most secure.

## Approach 1: Mount All of /dev (Least Secure) ❌

**File:** `docker-compose.yml`

```yaml
devices:
  - "/dev:/dev"
```

**Pros:**
- Simple to implement
- Works with any device

**Cons:**
- Exposes ALL devices to container
- Major security risk
- Container can access disks, memory, etc.

## Approach 2: Mount Specific Devices (More Secure) ✅

**File:** `docker-compose-secure.yml`

```yaml
devices:
  - "/dev/ttyUSB0:/dev/ttyUSB0"
  - "/dev/ttyACM0:/dev/ttyACM0"
  - "/dev/ttyS0:/dev/ttyS0"
```

**Pros:**
- Only exposes needed devices
- Much more secure
- Clear what devices are available

**Cons:**
- Requires knowing device names in advance
- May need to update when devices change

## Approach 3: Dynamic Device Detection (Most Secure) ✅✅

**File:** `docker-compose-dynamic.yml`

```yaml
volumes:
  - ./scripts:/scripts:ro
command: ["/scripts/start-with-devices.sh"]
```

**Pros:**
- Automatically detects available devices
- Only creates device nodes for found devices
- No privileged mode needed
- Most secure approach

**Cons:**
- More complex setup
- Requires custom script

## Approach 4: Using Device Cgroups (Advanced) 🔧

```yaml
cgroup_parent: /devices/serial
```

**Pros:**
- Fine-grained device control
- Kernel-level security

**Cons:**
- Complex to configure
- Requires kernel support

## Approach 5: Using Device Groups (Alternative) 🔧

```yaml
group_add:
  - dialout
```

**Pros:**
- Uses existing Linux group permissions
- No device mounting needed

**Cons:**
- Requires proper group setup on host
- May not work in all environments

## Recommended Usage

### For Development/Testing:
Use **Approach 2** (specific devices) with `docker-compose-secure.yml`:

```bash
# Build with secure Dockerfile
docker build -f Dockerfile-secure -t lora-serial-reader-secure .

# Run with specific devices
docker-compose -f docker-compose-secure.yml up
```

### For Production:
Use **Approach 3** (dynamic detection) with `docker-compose-dynamic.yml`:

```bash
# Build with secure Dockerfile
docker build -f Dockerfile-secure -t lora-serial-reader-secure .

# Run with dynamic device detection
docker-compose -f docker-compose-dynamic.yml up
```

## Security Comparison

| Approach | Security Level | Complexity | Flexibility |
|----------|---------------|------------|-------------|
| Mount all /dev | ❌ Very Low | 🟢 Simple | 🟢 High |
| Specific devices | 🟡 Medium | 🟡 Medium | 🟡 Medium |
| Dynamic detection | 🟢 High | 🔴 Complex | 🟢 High |
| Device cgroups | 🟢 High | 🔴 Complex | 🟡 Medium |
| Device groups | 🟡 Medium | 🟡 Medium | 🟡 Medium |

## Device Detection Script Features

The `scripts/start-with-devices.sh` script provides:

- **Automatic Detection**: Finds USB, ACM, and serial devices
- **Permission Checking**: Verifies read/write access
- **Environment Variables**: Sets `DEFAULT_SERIAL_PORT` and `ALL_SERIAL_PORTS`
- **Error Handling**: Graceful fallback if no devices found
- **Logging**: Detailed output for debugging

## Environment Variables

When using the dynamic approach, these environment variables are set:

- `DEFAULT_SERIAL_PORT`: First available serial device
- `ALL_SERIAL_PORTS`: Comma-separated list of all devices

## Troubleshooting

### Permission Issues
```bash
# Add user to dialout group
sudo usermod -a -G dialout $USER

# Or run with sudo (not recommended for production)
sudo docker-compose up
```

### Device Not Found
```bash
# Check available devices
ls -la /dev/tty*

# Check device permissions
ls -l /dev/ttyUSB0
```

### Container Can't Access Device
```bash
# Check if device exists in container
docker exec -it lora-serial-reader ls -la /dev/tty*

# Check container logs
docker logs lora-serial-reader
```

## Best Practices

1. **Never use `--privileged`** unless absolutely necessary
2. **Mount only specific devices** when possible
3. **Use non-root users** in containers
4. **Check device permissions** before running
5. **Log device access** for debugging
6. **Use environment variables** for device configuration
7. **Test with different devices** to ensure compatibility 