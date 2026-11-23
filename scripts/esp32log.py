#!/usr/bin/env python3
"""
esp32log.py - auto-reconnecting serial monitor for the ESP32-S3.

The Waveshare 1.85C-BOX uses native USB-CDC, so a RESET drops the serial port
and plain `screen`/`idf.py monitor` dies. This reconnects automatically and
mirrors everything to a log file, so you never miss boot output across resets.

Usage:
    python3 esp32log.py [PORT] [BAUD]

Defaults: PORT auto-detected (first /dev/cu.usbmodem* on macOS, /dev/ttyACM0 on
Linux), BAUD 115200. Log file: ./esp32_boot.log

Requires: pip install pyserial
"""
import sys, time, glob, datetime
import serial  # pip install pyserial

LOG = "esp32_boot.log"
BAUD = int(sys.argv[2]) if len(sys.argv) > 2 else 115200


def find_port():
    if len(sys.argv) > 1:
        return sys.argv[1]
    for pat in ("/dev/cu.usbmodem*", "/dev/ttyACM*", "/dev/ttyUSB*"):
        hits = sorted(glob.glob(pat))
        if hits:
            return hits[0]
    return None


def main():
    print(f"[esp32log] baud={BAUD}  log={LOG}  (Ctrl+C to stop)")
    with open(LOG, "a", buffering=1) as logf:
        while True:
            port = find_port()
            if not port:
                print("[esp32log] no serial port found, retrying...")
                time.sleep(1)
                continue
            try:
                with serial.Serial(port, BAUD, timeout=1) as ser:
                    stamp = datetime.datetime.now().isoformat(timespec="seconds")
                    print(f"[esp32log] connected {port} @ {stamp}")
                    logf.write(f"\n===== connected {port} @ {stamp} =====\n")
                    while True:
                        line = ser.readline()
                        if line:
                            text = line.decode("utf-8", "replace").rstrip()
                            print(text)
                            logf.write(text + "\n")
            except serial.SerialException:
                print("[esp32log] port dropped (reset?), reconnecting...")
                time.sleep(0.5)
            except KeyboardInterrupt:
                print("\n[esp32log] bye")
                return


if __name__ == "__main__":
    main()
