#!/usr/bin/env python3
"""
Serial Reader for LoRa Pi Gateway
A Python module for reading data from serial ports with configurable settings.
"""

import serial
import time
import logging
from typing import Optional, Callable, Dict, Any
import threading
import queue

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class SerialReader:
    """
    A class to handle serial communication for reading data from serial ports.
    """
    
    def __init__(self, 
                 port: str = '/dev/ttyUSB0',
                 baudrate: int = 9600,
                 timeout: float = 1.0,
                 bytesize: int = serial.EIGHTBITS,
                 parity: str = serial.PARITY_NONE,
                 stopbits: int = serial.STOPBITS_ONE):
        """
        Initialize the SerialReader with specified parameters.
        
        Args:
            port (str): Serial port name (e.g., '/dev/ttyUSB0', 'COM3')
            baudrate (int): Baud rate for communication
            timeout (float): Read timeout in seconds
            bytesize: Number of data bits
            parity: Parity setting
            stopbits: Number of stop bits
        """
        self.port = port
        self.baudrate = baudrate
        self.timeout = timeout
        self.bytesize = bytesize
        self.parity = parity
        self.stopbits = stopbits
        
        self.serial_conn: Optional[serial.Serial] = None
        self.is_connected = False
        self.is_reading = False
        self.read_thread: Optional[threading.Thread] = None
        self.data_queue = queue.Queue()
        self.callback: Optional[Callable[[bytes], None]] = None
        
    def connect(self) -> bool:
        """
        Connect to the serial port.
        
        Returns:
            bool: True if connection successful, False otherwise
        """
        try:
            self.serial_conn = serial.Serial(
                port=self.port,
                baudrate=self.baudrate,
                timeout=self.timeout,
                bytesize=self.bytesize,
                parity=self.parity,
                stopbits=self.stopbits
            )
            
            if self.serial_conn.is_open:
                self.is_connected = True
                logger.info(f"Successfully connected to {self.port} at {self.baudrate} baud")
                return True
            else:
                logger.error(f"Failed to open serial port {self.port}")
                return False
                
        except serial.SerialException as e:
            logger.error(f"Serial connection error: {e}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error during connection: {e}")
            return False
    
    def disconnect(self):
        """Disconnect from the serial port."""
        self.stop_reading()
        
        if self.serial_conn and self.serial_conn.is_open:
            self.serial_conn.close()
            self.is_connected = False
            logger.info(f"Disconnected from {self.port}")
    
    def set_callback(self, callback: Callable[[bytes], None]):
        """
        Set a callback function to be called when data is received.
        
        Args:
            callback: Function that takes bytes as argument
        """
        self.callback = callback
    
    def start_reading(self):
        """Start continuous reading from serial port in a separate thread."""
        if not self.is_connected:
            logger.error("Not connected to serial port")
            return
        
        if self.is_reading:
            logger.warning("Already reading from serial port")
            return
        
        self.is_reading = True
        self.read_thread = threading.Thread(target=self._read_loop, daemon=True)
        self.read_thread.start()
        logger.info("Started reading from serial port")
    
    def stop_reading(self):
        """Stop continuous reading from serial port."""
        self.is_reading = False
        if self.read_thread:
            self.read_thread.join(timeout=2.0)
        logger.info("Stopped reading from serial port")
    
    def _read_loop(self):
        """Internal method for continuous reading loop."""
        while self.is_reading and self.is_connected:
            try:
                if self.serial_conn.in_waiting > 0:
                    data = self.serial_conn.read(self.serial_conn.in_waiting)
                    if data:
                        self.data_queue.put(data)
                        if self.callback:
                            self.callback(data)
                        logger.debug(f"Received {len(data)} bytes: {data.hex()}")
                else:
                    time.sleep(0.01)  # Small delay to prevent busy waiting
                    
            except serial.SerialException as e:
                logger.error(f"Serial read error: {e}")
                self.is_connected = False
                break
            except Exception as e:
                logger.error(f"Unexpected error during reading: {e}")
                break
    
    def read_line(self) -> Optional[str]:
        """
        Read a single line from the serial port.
        
        Returns:
            str: The read line or None if no data available
        """
        if not self.is_connected:
            logger.error("Not connected to serial port")
            return None
        
        try:
            line = self.serial_conn.readline()
            if line:
                return line.decode('utf-8', errors='ignore').strip()
            return None
        except serial.SerialException as e:
            logger.error(f"Serial read error: {e}")
            return None
    
    def read_bytes(self, size: int = 1024) -> Optional[bytes]:
        """
        Read a specified number of bytes from the serial port.
        
        Args:
            size (int): Number of bytes to read
            
        Returns:
            bytes: The read data or None if no data available
        """
        if not self.is_connected:
            logger.error("Not connected to serial port")
            return None
        
        try:
            data = self.serial_conn.read(size)
            if data:
                return data
            return None
        except serial.SerialException as e:
            logger.error(f"Serial read error: {e}")
            return None
    
    def get_queued_data(self) -> Optional[bytes]:
        """
        Get data from the internal queue (if using continuous reading).
        
        Returns:
            bytes: The queued data or None if queue is empty
        """
        try:
            return self.data_queue.get_nowait()
        except queue.Empty:
            return None
    
    def write(self, data: bytes) -> bool:
        """
        Write data to the serial port.
        
        Args:
            data (bytes): Data to write
            
        Returns:
            bool: True if write successful, False otherwise
        """
        if not self.is_connected:
            logger.error("Not connected to serial port")
            return False
        
        try:
            bytes_written = self.serial_conn.write(data)
            self.serial_conn.flush()
            logger.debug(f"Wrote {bytes_written} bytes: {data.hex()}")
            return True
        except serial.SerialException as e:
            logger.error(f"Serial write error: {e}")
            return False
    
    def get_port_info(self) -> Dict[str, Any]:
        """
        Get information about the current serial port.
        
        Returns:
            dict: Port information
        """
        if not self.serial_conn:
            return {}
        
        return {
            'port': self.serial_conn.port,
            'baudrate': self.serial_conn.baudrate,
            'bytesize': self.serial_conn.bytesize,
            'parity': self.serial_conn.parity,
            'stopbits': self.serial_conn.stopbits,
            'timeout': self.serial_conn.timeout,
            'is_open': self.serial_conn.is_open,
            'in_waiting': self.serial_conn.in_waiting if self.serial_conn.is_open else 0
        }


def list_available_ports():
    """
    List all available serial ports.
    
    Returns:
        list: List of available port names
    """
    import serial.tools.list_ports
    
    ports = serial.tools.list_ports.comports()
    return [port.device for port in ports]


def main():
    """Example usage of the SerialReader class."""
    print("Available serial ports:")
    ports = list_available_ports()
    for port in ports:
        print(f"  - {port}")
    
    if not ports:
        print("No serial ports found!")
        return
    
    # Example: Read from the first available port
    port = ports[0]
    print(f"\nConnecting to {port}...")
    
    # Create serial reader instance
    reader = SerialReader(port=port, baudrate=9600)
    
    # Define a callback function for received data
    def data_callback(data: bytes):
        print(f"Received: {data.decode('utf-8', errors='ignore')}")
    
    reader.set_callback(data_callback)
    
    # Connect and start reading
    if reader.connect():
        print("Connected successfully!")
        print("Starting continuous reading (press Ctrl+C to stop)...")
        
        try:
            reader.start_reading()
            
            # Keep the main thread alive
            while True:
                time.sleep(1)
                
        except KeyboardInterrupt:
            print("\nStopping...")
        finally:
            reader.disconnect()
    else:
        print("Failed to connect!")


if __name__ == "__main__":
    main() 