# Mobile-Forensics-for-Android
This toolkit is created for the non rooted mobile. It's a beginner level mobile forensic toolkit

Give the permission to the file "chmod 777 DD_mobileforensic.sh"

Install the requiremen.sh

Features:

Display detailed device information
Extract various types of data (media, contacts, call logs, SMS, etc.)
Perform memory capture
Retrieve Wi-Fi and Bluetooth history
Backup entire device data
Extract WhatsApp and Telegram media

Prerequisites:

ADB (Android Debug Bridge): Ensure adb is installed and added to your system's PATH.
Installation instructions: ADB Installation Guide
Python 3.x: Required for running the Python scripts.
Tkinter: Ensure Tkinter is installed for GUI dialogs.
Pip Packages: Ensure necessary Python packages are installed using pip.

Installation:

Clone the repository:

sh
git clone https://github.com/dharani003/Mobile-Forensics-for-Android.git
cd Mobile-Forensics-for-Android


Install necessary Python packages:

sh
pip install magic

Usage:

Connect your Android device to the computer via USB and ensure USB debugging is enabled.

Run the main script:

sh
./mj_mobile_forensic.sh
Follow the on-screen instructions and select the desired operation from the menu.

Menu Options:

Entire Media Recovery and Extraction: Extract all media files from the device.
RAM Capture: Capture the RAM of the connected device.
Extract Call Log: Retrieve the call logs.
Extract Contacts: Retrieve the contacts.
Extract SMS: Retrieve SMS messages.
Wi-Fi History: Retrieve the history of connected Wi-Fi networks.
Bluetooth Paired History: Retrieve the history of paired Bluetooth devices.
Collect Google Accounts: Retrieve logged-in Google accounts.
Create a Backup: Backup app data and other files.
Entire Log Extraction: Extract system logs.
WhatsApp Media Extraction: Extract media files from WhatsApp.
Telegram Media Extraction: Extract media files from Telegram.

Example:

To extract call logs:

Select option 3 from the menu.
Follow the prompts to save the call logs to your desired location.

Notes:

Ensure your Android device has USB debugging enabled.
Permissions may be required on the device to allow data access.
