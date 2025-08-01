#!/usr/bin/env python3
"""
Simple TRNG Data Collection Example
Basic script to quickly collect random data from TRNG
"""

import serial
import time
import sys

def simple_collect(port, num_bytes=100):
    """
    Simple function to collect random data from TRNG
    
    Args:
        port (str): Serial port path
        num_bytes (int): Number of bytes to collect
    """
    try:
        # Open serial connection
        ser = serial.Serial(port, 115200, timeout=1)
        print(f"Connected to {port}")
        time.sleep(2)  # Wait for connection
        
        # Clear buffers
        ser.flushInput()
        ser.flushOutput()
        
        # Collect data
        collected = bytearray()
        print(f"Collecting {num_bytes} bytes...")
        
        start_time = time.time()
        no_data_count = 0
        max_no_data_cycles = 100  # Maximum cycles without data before timeout
        
        while len(collected) < num_bytes:
            if ser.in_waiting > 0:
                # Read all available data at once
                available = ser.in_waiting
                data = ser.read(min(available, num_bytes - len(collected)))
                collected.extend(data)
                print(f"\rProgress: {len(collected)}/{num_bytes} (read {len(data)} bytes)", end='', flush=True)
                no_data_count = 0  # Reset no-data counter
            else:
                no_data_count += 1
                if no_data_count >= max_no_data_cycles:
                    print(f"\nTimeout: No more data received after {max_no_data_cycles} cycles")
                    print(f"Collected {len(collected)} bytes before timeout")
                    break
                time.sleep(0.001)  # Reduced sleep time for faster response
        
        elapsed = time.time() - start_time
        print(f"\nCollection complete in {elapsed:.2f} seconds")
        
        # Display results
        print(f"Collected {len(collected)} bytes:")
        hex_data = ' '.join(f'{b:02x}' for b in collected[:20])  # Show first 20 bytes
        print(f"First 20 bytes: {hex_data}...")
        
        # Save to file
        filename = f"simple_trng_{int(time.time())}.bin"
        with open(filename, 'wb') as f:
            f.write(collected)
        print(f"Data saved to {filename}")
        
        ser.close()
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 simple_collect.py <serial_port> [num_bytes]")
        print("Example: python3 simple_collect.py /dev/ttyUSB0 1000")
        sys.exit(1)
    
    port = sys.argv[1]
    num_bytes = int(sys.argv[2]) if len(sys.argv) > 2 else 100
    
    simple_collect(port, num_bytes)
