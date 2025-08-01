#!/usr/bin/env python3
"""
TRNG Data Collection Script
Collects random data from FPGA-based True Random Number Generator via UART
"""

import serial
import serial.tools.list_ports
import argparse
import time
import sys
import os
from datetime import datetime

class TRNGCollector:
    def __init__(self, port=None, baudrate=115200, timeout=1):
        """
        Initialize TRNG data collector
        
        Args:
            port (str): Serial port path (e.g., '/dev/ttyUSB0', 'COM3')
            baudrate (int): Baud rate for serial communication
            timeout (float): Serial read timeout in seconds
        """
        self.port = port
        self.baudrate = baudrate
        self.timeout = timeout
        self.serial_conn = None
        
    def list_available_ports(self):
        """List all available serial ports"""
        ports = serial.tools.list_ports.comports()
        print("Available serial ports:")
        for i, port in enumerate(ports):
            print(f"  {i+1}. {port.device} - {port.description}")
        return [port.device for port in ports]
    
    def connect(self):
        """Establish serial connection"""
        try:
            if not self.port:
                # Auto-detect port if not specified
                available_ports = self.list_available_ports()
                if not available_ports:
                    raise Exception("No serial ports found")
                
                # Try to find FTDI or similar UART bridge
                for port_info in serial.tools.list_ports.comports():
                    if any(keyword in port_info.description.lower() 
                          for keyword in ['ftdi', 'uart', 'usb', 'serial']):
                        self.port = port_info.device
                        print(f"Auto-detected port: {self.port}")
                        break
                
                if not self.port:
                    self.port = available_ports[0]
                    print(f"Using first available port: {self.port}")
            
            self.serial_conn = serial.Serial(
                port=self.port,
                baudrate=self.baudrate,
                timeout=self.timeout,
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE
            )
            
            print(f"Connected to {self.port} at {self.baudrate} baud")
            time.sleep(2)  # Wait for connection to stabilize
            
            # Clear any pending data
            self.serial_conn.flushInput()
            self.serial_conn.flushOutput()
            
            return True
            
        except Exception as e:
            print(f"Error connecting to serial port: {e}")
            return False
    
    def disconnect(self):
        """Close serial connection"""
        if self.serial_conn and self.serial_conn.is_open:
            self.serial_conn.close()
            print("Serial connection closed")
    
    def collect_data(self, num_bytes, output_file=None, display_progress=True):
        """
        Collect random data from TRNG
        
        Args:
            num_bytes (int): Number of bytes to collect
            output_file (str): Output file path (optional)
            display_progress (bool): Show progress during collection
            
        Returns:
            bytes: Collected random data
        """
        if not self.serial_conn or not self.serial_conn.is_open:
            raise Exception("Serial connection not established")
        
        collected_data = bytearray()
        start_time = time.time()
        
        print(f"Collecting {num_bytes} bytes of random data...")
        
        try:
            while len(collected_data) < num_bytes:
                # Read available data
                if self.serial_conn.in_waiting > 0:
                    chunk = self.serial_conn.read(min(self.serial_conn.in_waiting, 
                                                    num_bytes - len(collected_data)))
                    collected_data.extend(chunk)
                    
                    if display_progress and len(collected_data) % 100 == 0:
                        progress = (len(collected_data) / num_bytes) * 100
                        elapsed = time.time() - start_time
                        rate = len(collected_data) / elapsed if elapsed > 0 else 0
                        print(f"\rProgress: {progress:.1f}% ({len(collected_data)}/{num_bytes} bytes) "
                              f"Rate: {rate:.1f} bytes/sec", end='', flush=True)
                
                time.sleep(0.001)  # Small delay to prevent busy waiting
        
        except KeyboardInterrupt:
            print(f"\nCollection interrupted. Collected {len(collected_data)} bytes.")
        
        elapsed_time = time.time() - start_time
        final_rate = len(collected_data) / elapsed_time if elapsed_time > 0 else 0
        
        print(f"\nCollection complete!")
        print(f"Collected: {len(collected_data)} bytes")
        print(f"Time: {elapsed_time:.2f} seconds")
        print(f"Average rate: {final_rate:.2f} bytes/sec")
        
        # Save to file if specified
        if output_file:
            self.save_data(collected_data, output_file)
        
        return bytes(collected_data)
    
    def save_data(self, data, filename):
        """Save collected data to file"""
        try:
            # Create directory if it doesn't exist
            os.makedirs(os.path.dirname(filename) if os.path.dirname(filename) else '.', exist_ok=True)
            
            with open(filename, 'wb') as f:
                f.write(data)
            print(f"Data saved to: {filename}")
            
            # Also save as hex for inspection
            hex_filename = filename + '.hex'
            with open(hex_filename, 'w') as f:
                hex_data = ' '.join(f'{byte:02x}' for byte in data)
                f.write(hex_data)
            print(f"Hex dump saved to: {hex_filename}")
            
        except Exception as e:
            print(f"Error saving data: {e}")
    
    def analyze_data(self, data):
        """Basic analysis of collected random data"""
        if not data:
            print("No data to analyze")
            return
        
        print("\n=== Data Analysis ===")
        print(f"Total bytes: {len(data)}")
        print(f"Total bits: {len(data) * 8}")
        
        # Count bit frequencies
        bit_count = 0
        for byte in data:
            bit_count += bin(byte).count('1')
        
        total_bits = len(data) * 8
        ones_ratio = bit_count / total_bits if total_bits > 0 else 0
        
        print(f"Ones: {bit_count} ({ones_ratio:.3%})")
        print(f"Zeros: {total_bits - bit_count} ({1 - ones_ratio:.3%})")
        
        # Byte value distribution
        byte_counts = [0] * 256
        for byte in data:
            byte_counts[byte] += 1
        
        min_count = min(byte_counts)
        max_count = max(byte_counts)
        print(f"Byte distribution - Min: {min_count}, Max: {max_count}")
        
        # Show first few bytes as hex
        preview_bytes = min(16, len(data))
        hex_preview = ' '.join(f'{data[i]:02x}' for i in range(preview_bytes))
        print(f"First {preview_bytes} bytes (hex): {hex_preview}")

def main():
    parser = argparse.ArgumentParser(description='TRNG Data Collector')
    parser.add_argument('-p', '--port', type=str, help='Serial port (e.g., /dev/ttyUSB0, COM3)')
    parser.add_argument('-b', '--baudrate', type=int, default=115200, help='Baud rate (default: 115200)')
    parser.add_argument('-n', '--num-bytes', type=int, default=1000, help='Number of bytes to collect (default: 1000)')
    parser.add_argument('-o', '--output', type=str, help='Output file path')
    parser.add_argument('-t', '--timeout', type=float, default=1.0, help='Serial timeout in seconds (default: 1.0)')
    parser.add_argument('--no-analysis', action='store_true', help='Skip data analysis')
    parser.add_argument('--continuous', action='store_true', help='Continuous collection mode')
    
    args = parser.parse_args()
    
    # Generate default output filename if not specified
    if not args.output:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        args.output = f"trng_data_{timestamp}.bin"
    
    # Create collector instance
    collector = TRNGCollector(port=args.port, baudrate=args.baudrate, timeout=args.timeout)
    
    try:
        # Connect to device
        if not collector.connect():
            sys.exit(1)
        
        if args.continuous:
            # Continuous collection mode
            print("Continuous collection mode. Press Ctrl+C to stop.")
            file_counter = 0
            while True:
                try:
                    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                    output_file = f"trng_continuous_{timestamp}_{file_counter:04d}.bin"
                    
                    data = collector.collect_data(args.num_bytes, output_file)
                    
                    if not args.no_analysis:
                        collector.analyze_data(data)
                    
                    file_counter += 1
                    print(f"\nFile {file_counter} complete. Starting next collection...")
                    
                except KeyboardInterrupt:
                    print("\nContinuous collection stopped.")
                    break
        else:
            # Single collection
            data = collector.collect_data(args.num_bytes, args.output)
            
            if not args.no_analysis:
                collector.analyze_data(data)
    
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
    
    finally:
        collector.disconnect()

if __name__ == "__main__":
    main()
