# Use Python 3.11 slim image as base
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies for serial communication
RUN apt-get update && apt-get install -y \
    udev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the serial reader script
COPY serial_reader.py .

# Create a non-root user for security
RUN useradd -m -u 1000 serialuser && \
    chown -R serialuser:serialuser /app

# Switch to non-root user
USER serialuser

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

# Default command to run the serial reader
CMD ["python", "serial_reader.py"] 