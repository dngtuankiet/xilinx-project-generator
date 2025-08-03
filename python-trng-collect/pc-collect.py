import serial
import sys
import os
# Time stamp for the output file
import time
from datetime import datetime

if len(sys.argv) < 4:
    print("Usage: python3 pc_collector.py <COM_PORT>")
    sys.exit(1)

com_port = sys.argv[1]
rounds = int(sys.argv[2])
batch_size = int(sys.argv[3])
baud_rate = 115200
try:
    ser = serial.Serial(com_port, baud_rate, timeout=1000)
    ser.flushInput()
except serial.SerialException as e:
    print("Failed to open {}: {}".format(com_port, e))
    sys.exit(1)
print("Listening to {}... Expecting {} bytes.".format(com_port, rounds * batch_size))

byte_count = 0
collection_rates = []
for round in range(rounds):
    ready = ser.read(3)
    print(f"\nReceived: {ready} - round {round + 1}/{rounds}")
    if b'RDY' in ready:
        start_timestamp = datetime.now()

        for byte_count in range(batch_size):
            data = ser.read(1)
            number = int.from_bytes(data, byteorder='big')
            # Calculate and display progress
            progress_percent = (byte_count / batch_size) * 100
            print(f"\rProgress: {byte_count+1}/{batch_size} bytes ({progress_percent:.1f}%) - Latest: 0x{number:02X}", end='', flush=True)
            
            # Print newline every 50 bytes for readability, or on last byte
            if (byte_count) % 50 == 0 or byte_count == batch_size:
                print()  # Add newline

        end_timestamp = datetime.now()
        total_time = (end_timestamp - start_timestamp).total_seconds()
        collection_rate = batch_size / total_time if total_time > 0 else 0
        collection_rates.append(collection_rate)
    else:
        print("Error: Expected 'RDY' but received: {}".format(ready))
        break

ser.reset_input_buffer()
ser.close()
print("\nSerial port closed! Data collection complete.")

# Display collection rates
if collection_rates:
    avg_rate = sum(collection_rates) / len(collection_rates)
    print(f"\nAverage collection rate: {avg_rate:.2f} bytes/second over {len(collection_rates)} rounds.")
print(f"Total bytes collected: {rounds * batch_size}")