# TRNG Data Collection Scripts

This directory contains Python scripts to collect random data from the FPGA-based True Random Number Generator (TRNG) via UART.

## Files

- `pc_collect.py` - Main collection script with advanced features
- `simple_collect.py` - Simple example script for basic data collection
- `requirements.txt` - Python package dependencies

## Installation

1. Install Python dependencies:
```bash
pip install -r requirements.txt
```

## Usage

### Main Collection Script (pc_collect.py)

The main script provides comprehensive features for data collection and analysis.

#### Basic Usage:
```bash
# Auto-detect port and collect 1000 bytes
python3 pc_collect.py

# Specify port and number of bytes
python3 pc_collect.py -p /dev/ttyUSB0 -n 5000

# Custom output file
python3 pc_collect.py -p /dev/ttyUSB0 -n 1000 -o my_random_data.bin

# Different baud rate
python3 pc_collect.py -p /dev/ttyUSB0 -b 9600 -n 1000
```

#### Advanced Features:
```bash
# Continuous collection mode
python3 pc_collect.py --continuous -n 1000

# Skip data analysis
python3 pc_collect.py --no-analysis -n 5000

# Custom timeout
python3 pc_collect.py -t 2.0 -n 1000
```

#### Command Line Options:
- `-p, --port`: Serial port (e.g., /dev/ttyUSB0, COM3)
- `-b, --baudrate`: Baud rate (default: 115200)
- `-n, --num-bytes`: Number of bytes to collect (default: 1000)
- `-o, --output`: Output file path
- `-t, --timeout`: Serial timeout in seconds (default: 1.0)
- `--no-analysis`: Skip data analysis
- `--continuous`: Continuous collection mode

### Simple Collection Script (simple_collect.py)

For quick and basic data collection:

```bash
# Collect 100 bytes from /dev/ttyUSB0
python3 simple_collect.py /dev/ttyUSB0

# Collect 1000 bytes
python3 simple_collect.py /dev/ttyUSB0 1000
```

## Port Detection

The script can auto-detect available serial ports. Common port names:

### Linux:
- `/dev/ttyUSB0`, `/dev/ttyUSB1`, etc. (USB-to-serial adapters)
- `/dev/ttyACM0`, `/dev/ttyACM1`, etc. (CDC ACM devices)

### Windows:
- `COM1`, `COM2`, `COM3`, etc.

### macOS:
- `/dev/cu.usbserial-*` (USB-to-serial adapters)
- `/dev/cu.usbmodem*` (CDC ACM devices)

## Output Files

The collection script generates two files:
1. `.bin` file - Raw binary data
2. `.bin.hex` file - Hexadecimal representation for inspection

## Data Analysis

The main script provides basic statistical analysis:
- Total bytes and bits collected
- Bit distribution (ones vs zeros)
- Byte value distribution
- Collection rate (bytes/second)
- Preview of first bytes in hexadecimal

## Troubleshooting

### Permission Issues (Linux)
If you get permission errors, add your user to the dialout group:
```bash
sudo usermod -a -G dialout $USER
```
Then log out and back in.

### Port Not Found
1. Check that the FPGA board is connected via USB
2. Verify the UART bridge is working: `dmesg | grep tty`
3. List available ports: `ls /dev/tty*`

### No Data Received
1. Verify the FPGA bitstream is loaded correctly
2. Check that the TRNG is enabled (iEn signal)
3. Verify the baud rate matches the FPGA configuration
4. Check UART wiring/connections

## Example Output

```
$ python3 pc_collect.py -p /dev/ttyUSB0 -n 1000

Connected to /dev/ttyUSB0 at 115200 baud
Collecting 1000 bytes of random data...
Progress: 100.0% (1000/1000 bytes) Rate: 245.3 bytes/sec

Collection complete!
Collected: 1000 bytes
Time: 4.08 seconds
Average rate: 245.12 bytes/sec
Data saved to: trng_data_20250731_143022.bin
Hex dump saved to: trng_data_20250731_143022.bin.hex

=== Data Analysis ===
Total bytes: 1000
Total bits: 8000
Ones: 4023 (50.3%)
Zeros: 3977 (49.7%)
Byte distribution - Min: 1, Max: 8
First 16 bytes (hex): a3 5f 2d 91 c7 48 e6 79 b4 1a 8e f2 36 d5 9c 47
```
