import serial
import sys
import os
# Time stamp for the output file
import time
from datetime import datetime


byte_count = 1000

start_timestamp = datetime.now()

if len(sys.argv) < 3:
    print("Usage: python3 pc_collector.py <COM_PORT>")
    sys.exit(1)

com_port = sys.argv[1]
rounds = int(sys.argv[2])
baud_rate = 115200
try:
    ser = serial.Serial(com_port, baud_rate, timeout=1000)
    ser.flushInput()
except serial.SerialException as e:
    print("Failed to open {}: {}".format(com_port, e))
    sys.exit(1)
print("Listening to {}... Expecting {} bytes.".format(com_port, rounds))


for round in range(rounds):
    data = ser.read(1)
    number = int.from_bytes(data, byteorder='big')
    
    # Calculate and display progress
    progress_percent = ((round + 1) / rounds) * 100
    print(f"\rProgress: {round + 1}/{rounds} bytes ({progress_percent:.1f}%) - Latest: 0x{number:02X}", end='', flush=True)
    
    # Print newline every 50 bytes for readability, or on last byte
    if (round + 1) % 50 == 0 or round == rounds - 1:
        print()  # Add newline


ser.reset_input_buffer()
ser.close()
print("\nSerial port closed! Data collection complete.")

end_timestamp = datetime.now()

total_time = (end_timestamp - start_timestamp).total_seconds()
collection_rate = rounds / total_time if total_time > 0 else 0

print(f"Data collection started at {start_timestamp.strftime('%Y%m%d_%H%M%S')} and ended at {end_timestamp.strftime('%Y%m%d_%H%M%S')}.")
print(f"Total time taken: {total_time:.2f} seconds.")
print(f"Collection rate: {collection_rate:.2f} bytes/second.")
print(f"Total bytes collected: {rounds}")