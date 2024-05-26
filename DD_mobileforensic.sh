#!/bin/bash

# Display an attractive banner using figlet
echo -e "\n\033[1;34m"
figlet -f slant "DD Mobile Forensic"
echo -e "\033[0m"

# Check if adb is installed
if ! command -v adb &> /dev/null; then
    echo "adb (Android Debug Bridge) is not installed. Please install it and try again."
    exit 1
fi

# Check if any device is connected
connected_devices=$(adb devices | grep -w "device" | wc -l)
if [ "$connected_devices" -eq 0 ]; then
    echo "No android device is connected."
    exit 1
fi

# Wait for device to be connected
adb wait-for-device

# Check if USB debugging is enabled
usb_debugging_status=$(adb shell settings get global adb_enabled)
if [ "$usb_debugging_status" -ne 1 ]; then
    echo "USB Debugging is not enabled. Please enable USB Debugging on your device and try again."
    exit 1
fi

# Display connected device message
echo "Connected device details are:"

# Get device IP address
device_ip=$(adb shell ip addr show wlan0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
if [ -z "$device_ip" ]; then
    device_ip="Could not retrieve IP address"
fi
echo "IP Address: $device_ip"

# Get device manufacturer and model
manufacturer=$(adb shell getprop ro.product.manufacturer)
model=$(adb shell getprop ro.product.model)
echo "Manufacturer: $manufacturer"
echo "Model: $model"

# Get Android version
android_version=$(adb shell getprop ro.build.version.release)
echo "Android Version: $android_version"

# Get device CPU architecture
cpu_architecture=$(adb shell getprop ro.product.cpu.abi)
echo "CPU Architecture: $cpu_architecture"

# Get total RAM
total_ram=$(adb shell cat /proc/meminfo | grep MemTotal | awk '{print $2 $3}')
echo "Total RAM: $total_ram"

# Get available storage
available_storage=$(adb shell df -h /data | grep /data | awk '{print $4}')
echo "Available Storage: $available_storage"

# Get battery level
battery_level=$(adb shell dumpsys battery | grep level | awk '{print $2}')
echo "Battery Level: $battery_level%"

# Get screen resolution
screen_resolution=$(adb shell wm size | awk '{print $3}')
echo "Screen Resolution: $screen_resolution"

# Get kernel version
kernel_version=$(adb shell uname -r)
echo "Kernel Version: $kernel_version"

# Get build number
build_number=$(adb shell getprop ro.build.display.id)
echo "Build Number: $build_number"

# Get serial number
serial_number=$(adb shell getprop ro.serialno)
echo "Serial Number: $serial_number"

#Get IMEI number
imei=$(adb shell service call iphonesubinfo 1 | grep -oE '[0-9a-f]{8} [0-9a-f]{8}' | awk '{print $2$3}' | sed 's/\.//g')
echo "IMEI number: $imei"

echo "All details retrieved successfully."
echo -e "\n Now you can run these operations"
# Display the list of operations
echo -e  "\n1.  Entire Media Recovery and Extraction"
echo -e  "\n2.  Ram Capture"
echo -e  "\n3.  Extract Call log"
echo -e  "\n4.  Extract Contacts"
echo -e  "\n5.  Extract SMS"
echo -e  "\n6.  Wifi History"
echo -e  "\n7.  Bluetooth Paired History"
echo -e  "\n8.  Collect Google accounts"
echo -e  "\n9.  Create a Backup "
echo -e  "\n10. Entire Log extraction"

# Prompt the user to choose an operation
read -p "Select the Process: " choice

# Run the Python code based on the user's choice
case $choice in
    1)
        # Python code for Entire Media Recovery and Extraction
        python3 << EOF
import os
import subprocess
import tkinter as tk
from tkinter import filedialog
import magic
from concurrent.futures import ThreadPoolExecutor
import re

# Constants
SUPPORTED_TYPES = {'pdf', 'docx', 'avi', 'gif', 'png', 'jpg', 'jpg_ffdb', 'bmp', 'mpeg'}

# Function to search for media files on connected Android devices using ADB
def search_media_files():
    try:
        result = subprocess.run(['adb', 'shell', 'find', '/storage/emulated/0/', '-type', 'f'], capture_output=True, text=True, errors='ignore')
        if result.returncode == 0:
            if result.stdout:
                file_paths = result.stdout.split('\n')
                file_paths = [path.strip() for path in file_paths if path.strip() and not re.search(r'\.thumbnail|\.temp|\.cache|\.thumbcache|\.dat|\.xml|\.nomedia|\.android_secure|\.data', path, re.IGNORECASE)]
                return file_paths
            else:
                print("No files found on the device.")
                return []
        else:
            print("Failed to run ADB command:", result.stderr)
            return []
    except Exception as e:
        print("An error occurred:", e)
        return []

# Function to read file bytes from Android device using ADB
def read_file_from_device(file_path, dest):
    try:
        result = subprocess.run(['adb', 'pull', file_path, dest], capture_output=True)
        if result.returncode == 0:
            return os.path.join(dest, os.path.basename(file_path))
        else:
            print(f"Failed to pull file {file_path} from device:", result.stderr)
            return None
    except Exception as e:
        print("An error occurred:", e)
        return None

# Function to write recovered bytes to file
def write_bytes(source_path, dest_path):
    try:
        with open(source_path, 'rb') as source_file:
            bytes_data = source_file.read()
            with open(dest_path, 'wb') as dest_file:
                dest_file.write(bytes_data)
        print(f"Recovered: {dest_path}")
        return True
    except Exception as e:
        print(f"An error occurred while writing {dest_path}: {e}")
        return False

# Function to create a directory for recovered files
def create_recovery_directory():
    root = tk.Tk()
    root.withdraw()
    directory_path = filedialog.askdirectory(initialdir="/", title="Select Directory")
    return directory_path

# Function to handle recovery for a specific file type
def handle_recovery(file_paths, recovered_dir):
    def process_file(file_path):
        try:
            if not file_path_exists(file_path):
                print(f"File {file_path} does not exist on the device.")
                return False
            local_file_path = read_file_from_device(file_path, recovered_dir)
            if local_file_path:
                file_extension = magic.from_file(local_file_path, mime=True).split('/')[-1].lower()
                return write_bytes(local_file_path, os.path.join(recovered_dir, os.path.basename(file_path)))
            return False
        except Exception as e:
            print(f"An error occurred while processing {file_path}: {e}")
            return False

    with ThreadPoolExecutor() as executor:
        results = list(executor.map(process_file, file_paths))

    success_count = sum(results)
    total_files = len(file_paths)
    print(f"Recovered {success_count}/{total_files} files.")

# Function to check if a file exists on the device
def file_path_exists(file_path):
    result = subprocess.run(['adb', 'shell', 'ls', file_path], capture_output=True, text=True)
    return result.returncode == 0

def main():
    media_files = search_media_files()
    if media_files:
        recovered_dir = create_recovery_directory()
        if recovered_dir:
            handle_recovery(media_files, recovered_dir)
        else:
            print("No directory selected for recovery.")
    else:
        print("No media files found on connected Android device.")

if __name__ == "__main__":
    main()
EOF
        ;;
    2)
        # Python code for Ram Capture
        python3 << EOF
import os
import subprocess
import tkinter as tk
from tkinter import filedialog

def capture_ram():
    try:
        root = tk.Tk()
        root.withdraw()
        folder_path = filedialog.askdirectory(initialdir='/', title='Select Folder to Save RAM Capture')
        if not folder_path:
            print('No folder selected. Exiting...')
            return False
        file_path = os.path.join(folder_path, 'captured_ram.txt')
        result = subprocess.run(['adb', 'shell', 'dumpsys', 'meminfo', '--unreachable'], capture_output=True, text=True)
        with open(file_path, 'w') as f:
            f.write(result.stdout)
        print('RAM captured and saved successfully to:', file_path)
        return True
    except Exception as e:
        print('Error capturing RAM:', e)
        return False
    finally:
        try:
            root.destroy()
        except:
            pass

def main():
    if capture_ram():
        print('RAM captured successfully.')

if __name__ == '__main__':
    main()
EOF
        ;;
    3)
        # Python code for Extract Call log
        python3 << EOF
import subprocess
import csv
import tkinter as tk
from tkinter import filedialog

def extract_call_log():
    try:
        root = tk.Tk()
        root.withdraw()
        file_path = filedialog.asksaveasfilename(defaultextension=".csv", filetypes=[("CSV files", "*.csv")])
        if not file_path:
            print('No file selected. Exiting...')
            return False
        result = subprocess.run(['adb', 'shell', 'content', 'query', '--uri', 'content://call_log/calls'], capture_output=True, text=True)
        if result.returncode == 0:
            with open(file_path, 'w', newline='') as csvfile:
                fieldnames = ['ID', 'Number', 'Date', 'Duration', 'Type', 'New', 'Name', 'Number Type', 'Number Label']
                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                writer.writeheader()
                for line in result.stdout.strip().split('\n'):
                    row = dict(zip(fieldnames, line.split(',')))
                    writer.writerow(row)
            print('Call log extracted and saved successfully to:', file_path)
            return True
        else:
            print('Failed to extract call log:', result.stderr)
            return False
    except Exception as e:
        print('Error extracting call log:', e)
        return False
    finally:
        try:
            root.destroy()
        except:
            pass

def main():
    if extract_call_log():
        print('Call log extracted successfully.')

if __name__ == '__main__':
    main()
EOF
        ;;
    4)
        # Python code for Extract Contacts
        python3 << EOF
import subprocess
import csv
import tkinter as tk
from tkinter import filedialog

def extract_contacts():
    try:
        root = tk.Tk()
        root.withdraw()
        file_path = filedialog.asksaveasfilename(defaultextension=".csv", filetypes=[("CSV files", "*.csv")])
        if not file_path:
            print('No file selected. Exiting...')
            return False
        result = subprocess.run(['adb', 'shell', 'content', 'query', '--uri', 'content://contacts/phones/'], capture_output=True, text=True)
        if result.returncode == 0:
            with open(file_path, 'w', newline='') as csvfile:
                fieldnames = ['ID', 'Name', 'Number', 'Type']
                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                writer.writeheader()
                for line in result.stdout.strip().split('\n'):
                    row = dict(zip(fieldnames, line.split(',')))
                    writer.writerow(row)
            print('Contacts extracted and saved successfully to:', file_path)
            return True
        else:
            print('Failed to extract contacts:', result.stderr)
            return False
    except Exception as e:
        print('Error extracting contacts:', e)
        return False
    finally:
        try:
            root.destroy()
        except:
            pass

def main():
    if extract_contacts():
        print('Contacts extracted successfully.')

if __name__ == '__main__':
    main()
EOF
        ;;
    5)
        # Python code for Extract SMS
        python3 << EOF
import subprocess
import tkinter as tk
from tkinter import filedialog

# Function to execute a shell command
def execute_command(command):
    try:
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        output, error = process.communicate()
        return output.decode(), error.decode()
    except Exception as e:
        print("Error executing command:", e)
        return None, str(e)

# Function to retrieve SMS logs from the device
def get_sms_logs():
    try:
        sms_logs_command = "adb shell content query --uri content://sms/inbox --projection date,address,body"
        sms_logs_output, error = execute_command(sms_logs_command)
        if error:
            raise Exception(error)
        return sms_logs_output
    except Exception as e:
        print("Error retrieving SMS logs:", e)
        return None

# Function to save data to a text file
def save_to_text(filename, data):
    try:
        with open(filename, 'w', encoding='utf-8') as text_file:
            text_file.write(data)
        print("SMS logs saved to", filename)
    except Exception as e:
        print("Error saving SMS logs to file:", e)

# Function to check if the device is connected
def is_device_connected():
    try:
        result = subprocess.run(["adb", "devices"], capture_output=True, text=True, check=True)
        output = result.stdout.strip().split("\n")
        return len(output) > 1  # Check if any devices are listed (excluding the header)
    except subprocess.CalledProcessError as e:
        print("Error checking device connection:", e)
        return False
    except Exception as e:
        print("An error occurred:", e)
        return False

# Main function
def main():
    try:
        if not is_device_connected():
            print("Device is not connected. Exiting...")
            return

        # Get SMS logs
        sms_logs_data = get_sms_logs()

        if sms_logs_data:
            # Create GUI window
            root = tk.Tk()
            root.withdraw()  # Hide the main window

            # Prompt user to select the file path
            file_path = filedialog.asksaveasfilename(defaultextension=".txt", filetypes=[("Text files", "*.txt")], title="Save Text file")

            if file_path:
                # Save to text file if the user selected a file path
                save_to_text(file_path, sms_logs_data)
            else:
                print("No file selected. Exiting...")
        else:
            print("Failed to retrieve SMS logs. Exiting...")
    except Exception as e:
        print("An error occurred during execution:", e)

if __name__ == "__main__":
    main()

EOF
        ;;
    6)
        # Python code for Wifi History
        python3 << EOF
import subprocess
import os
import tkinter as tk
from tkinter import filedialog

# Function to fetch saved Wi-Fi networks using ADB
def fetch_saved_wifi_networks():
    try:
        # Run ADB command to fetch saved Wi-Fi networks
        result = subprocess.run(['adb', 'shell', 'dumpsys', 'wifi', '|', 'grep', '-E', '"SSID|capabilities"'],
                                capture_output=True, text=True, check=True)
        # Parse the Wi-Fi network information
        wifi_info = result.stdout.strip().split('\n')
        networks = []
        for line in wifi_info:
            if line.startswith("SSID:"):
                ssid = line.split(":")[1].strip()
                networks.append(ssid)
        return networks
    except subprocess.CalledProcessError as e:
        print("Failed to run ADB command:", e)
        return []

# Function to select the file location and enter filename using Tkinter GUI
def select_file_location_and_filename():
    root = tk.Tk()
    root.withdraw()

    # Prompt user to enter filename only if networks are found
    if fetch_saved_wifi_networks():
        # Prompt user to enter filename
        filename = filedialog.asksaveasfilename(
            defaultextension=".txt",
            filetypes=[("Text files", "*.txt")],
            title="Save Wi-Fi Network List"
        )
        return filename
    else:
        print("No saved Wi-Fi networks found.")
        return None

# Select the file location and enter filename using GUI
selected_filename = select_file_location_and_filename()

# Write the list of saved Wi-Fi networks to a text file
if selected_filename:
    try:
        with open(selected_filename, 'w') as f:
            for network in fetch_saved_wifi_networks():
                f.write(network + '\n')

        print("Saved Wi-Fi networks have been saved to:", selected_filename)
    except Exception as e:
        print("An error occurred while writing to file:", e)
else:
    print("No filename selected.")

EOF
        ;;
    7)
        # Python code for Bluetooth Paired History
        python3 << EOF
import subprocess
import tkinter as tk
from tkinter import filedialog

def run_adb_command(command):
    try:
        # Execute the ADB command and capture its output
        output = subprocess.check_output(command, shell=True, text=True)
        return output.strip()  # Strip any leading/trailing whitespace
    except subprocess.CalledProcessError as e:
        print("Error:", e)
        return None

def save_to_text_file(data, output_file):
    try:
        with open(output_file, "w") as file:
            file.write(data)
        print("Output saved to:", output_file)
    except Exception as e:
        print("Error:", e)

def select_output_file():
    root = tk.Tk()
    root.withdraw()  # Hide the main window

    output_file = filedialog.asksaveasfilename(defaultextension=".txt",
                                               filetypes=[("Text Files", "*.txt"), ("All Files", "*.*")],
                                               title="Save Bluetooth Manager Info As")
    return output_file

if __name__ == "__main__":
    # Run adb shell command to fetch Bluetooth manager information
    adb_command = "adb shell dumpsys bluetooth_manager"
    output = run_adb_command(adb_command)

    if output is not None:
        # Ask user to select the output file location
        output_file = select_output_file()

        if output_file:
            # Save the output to the selected text file
            save_to_text_file(output, output_file)
        else:
            print("No file selected. Exiting.")
    else:
        print("Failed to retrieve Bluetooth manager information.")

EOF
        ;;
    8)
        # Python code for Location History
        python3 << EOF
import subprocess
import tkinter as tk
from tkinter import filedialog

def get_logged_in_emails():
    try:
        adb_output = subprocess.check_output(['adb', 'shell', 'dumpsys', 'account'])
        adb_output = adb_output.decode('utf-8')
        email_lines = [line for line in adb_output.split('\n') if '@' in line]
        return email_lines
    except subprocess.CalledProcessError as e:
        print("Error:", e)
        return None

# Get the logged-in emails
logged_in_emails = get_logged_in_emails()

if logged_in_emails:
    # Create GUI window
    root = tk.Tk()
    root.withdraw()  # Hide the main window

    # Prompt user to select the file path
    file_path = filedialog.asksaveasfilename(defaultextension=".txt", filetypes=[("Text files", "*.txt")], title="Save Text file")

    if file_path:
        # Save the emails to the selected text file
        with open(file_path, 'w') as file:
            file.writelines(logged_in_emails)
        print("Logged-in Accounts saved to", file_path)
    else:
        print("No file selected. Exiting...")
else:
    print("No logged-in Accounts retrieved. Exiting...")

EOF
        ;;
    9)
        # Python code for App Data Extraction
        python3 << EOF
import subprocess
import os
import tkinter as tk
from tkinter import filedialog

def extract_app_data():
    try:
        root = tk.Tk()
        root.withdraw()
        folder_path = filedialog.askdirectory(initialdir='/', title='Select Folder to Save App Data')
        if not folder_path:
            print('No folder selected. Exiting...')
            return False
        result = subprocess.run(['adb', 'shell', 'pm', 'list', 'packages'], capture_output=True, text=True)
        if result.returncode == 0:
            packages = [line.split(':')[1].strip() for line in result.stdout.strip().split('\n')]
            for package in packages:
                package_data_dir = os.path.join(folder_path, package)
                os.makedirs(package_data_dir, exist_ok=True)
                subprocess.run(['adb', 'pull', f'/data/data/{package}', package_data_dir])
            print('App data extracted and saved successfully to:', folder_path)
            return True
        else:
            print('Failed to extract app data:', result.stderr)
            return False
    except Exception as e:
        print('Error extracting app data:', e)
        return False
    finally:
        try:
            root.destroy()
        except:
            pass

def main():
    if extract_app_data():
        print('App data extracted successfully.')

if __name__ == '__main__':
    main()
EOF
        ;;
    10)
        # Python code for Entire Log Extraction
        python3 << EOF
import subprocess
import tkinter as tk
from tkinter import filedialog

def extract_logs():
    try:
        root = tk.Tk()
        root.withdraw()
        folder_path = filedialog.askdirectory(initialdir='/', title='Select Folder to Save Logs')
        if not folder_path:
            print('No folder selected. Exiting...')
            return False
        log_types = ['main', 'system', 'crash', 'events']
        for log_type in log_types:
            log_file_path = os.path.join(folder_path, f'{log_type}_log.txt')
            with open(log_file_path, 'w') as f:
                subprocess.run(['adb', 'logcat', f'-b {log_type}', '-d'], stdout=f)
        print('Logs extracted and saved successfully to:', folder_path)
        return True
    except Exception as e:
        print('Error extracting logs:', e)
        return False
    finally:
        try:
            root.destroy()
        except:
            pass

def main():
    if extract_logs():
        print('Logs extracted successfully.')

if __name__ == '__main__':
    main()
EOF
        ;;
    *)
        echo "Invalid choice. Exiting..."
        exit 1
        ;;
esac
