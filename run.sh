#!/bin/bash

# Script to build and run the serial reader Docker container

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Create logs directory if it doesn't exist
mkdir -p logs

# Function to build the image
build_image() {
    print_status "Building Docker image..."
    docker build -t lora-serial-reader .
    print_status "Docker image built successfully!"
}

# Function to run the container
run_container() {
    print_status "Starting serial reader container..."
    
    # Check if container is already running
    if docker ps -q -f name=lora-serial-reader | grep -q .; then
        print_warning "Container is already running. Stopping it first..."
        docker stop lora-serial-reader
        docker rm lora-serial-reader
    fi
    
    # Run the container
    docker run -d \
        --name lora-serial-reader \
        --privileged \
        --device=/dev:/dev \
        -v "$(pwd)/logs:/app/logs" \
        -e PYTHONUNBUFFERED=1 \
        -e TZ=UTC \
        --restart unless-stopped \
        lora-serial-reader
    
    print_status "Container started successfully!"
    print_status "To view logs: docker logs -f lora-serial-reader"
    print_status "To stop: docker stop lora-serial-reader"
}

# Function to run interactively
run_interactive() {
    print_status "Starting serial reader container in interactive mode..."
    
    # Check if container is already running
    if docker ps -q -f name=lora-serial-reader | grep -q .; then
        print_warning "Container is already running. Stopping it first..."
        docker stop lora-serial-reader
        docker rm lora-serial-reader
    fi
    
    # Run the container interactively
    docker run -it \
        --name lora-serial-reader \
        --privileged \
        --device=/dev:/dev \
        -v "$(pwd)/logs:/app/logs" \
        -e PYTHONUNBUFFERED=1 \
        -e TZ=UTC \
        lora-serial-reader
}

# Function to show logs
show_logs() {
    print_status "Showing container logs..."
    docker logs -f lora-serial-reader
}

# Function to stop the container
stop_container() {
    print_status "Stopping container..."
    docker stop lora-serial-reader
    docker rm lora-serial-reader
    print_status "Container stopped and removed!"
}

# Function to show status
show_status() {
    print_status "Container status:"
    docker ps -a -f name=lora-serial-reader
}

# Function to show available serial ports
show_ports() {
    print_status "Available serial ports on host:"
    ls -la /dev/tty* 2>/dev/null | grep -E "(USB|ACM|S)" || print_warning "No serial devices found"
}

# Main script logic
case "${1:-help}" in
    "build")
        build_image
        ;;
    "run")
        build_image
        run_container
        ;;
    "interactive")
        build_image
        run_interactive
        ;;
    "logs")
        show_logs
        ;;
    "stop")
        stop_container
        ;;
    "status")
        show_status
        ;;
    "ports")
        show_ports
        ;;
    "help"|*)
        echo "Usage: $0 {build|run|interactive|logs|stop|status|ports|help}"
        echo ""
        echo "Commands:"
        echo "  build       - Build the Docker image"
        echo "  run         - Build and run the container in background"
        echo "  interactive - Build and run the container interactively"
        echo "  logs        - Show container logs"
        echo "  stop        - Stop and remove the container"
        echo "  status      - Show container status"
        echo "  ports       - Show available serial ports on host"
        echo "  help        - Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 build        # Build the image"
        echo "  $0 run          # Run in background"
        echo "  $0 interactive  # Run interactively (for debugging)"
        echo "  $0 logs         # View logs"
        ;;
esac 