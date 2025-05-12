# NessusDesktop - ![Version](https://img.shields.io/badge/version-1.0.2-blue)

NessusDesktop is a utility designed to simplify the management of the Nessus vulnerability scanner's service on GUI based Linux systems. It provides convenient scripts to start and stop the Nessus service, streamlining the process of initiating vulnerability scans.

## Features

- **Service Management:** Easily start or stop the Nessus service using simple commands.
- **Script Organization:** All management scripts are housed in a dedicated directory for straightforward access.

## Prerequisites

- A Linux-based operating system (e.g., Ubuntu, CentOS, Debian).
  - Tested on Kali Linux
- sudo privileges to manage system services.
- An installed instance of Tenable's Nessus vulnerability scanner.

## Installation

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/JackMarsden/nessusdesktop
   ```
2. **Navigate to the Directory:**

   ```bash
   cd nessusDesktop
   ```
3. **Run the Installation Script:**

   ```bash
   bash ./install.sh
   ```
   **The script will:**

- **Prompt for confirmation** if the `/opt/nessusdesktop` directory already exists, offering options to overwrite or cancel the installation.
- **Copy necessary management scripts** to the `/opt/nessusdesktop` directory, excluding the `install.sh` script itself.
- **Set appropriate permissions** for the copied scripts to ensure they are executable.
 
## Usage

After installation, you can start or stop the Nessus service using the desktop shortcuts.
