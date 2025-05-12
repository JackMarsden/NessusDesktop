#!/bin/bash
# install.sh
# This script checks for Nessus and required dependencies (including zenity and gio),
# prompts for the user's desktop path (defaulting to $HOME/Desktop),
# creates a custom directory in /opt for shell scripts,
# copies all .sh files to that custom directory,
# copies the .desktop files to the user's desktop,
# marks them as trusted (secure) using gio if available,
# sets appropriate file permissions,
# and manages versioning by creating and comparing a version file.

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Define Version Number ---
CURRENT_VERSION="v1.0.0"

# --- Define Scripts Directory ---
SCRIPTS_DIR="/opt/nessusdesktop"
VERSION_FILE="$SCRIPTS_DIR/version.txt"

# --- Check for Nessus ---
if ! ( command_exists nessusd || [ -x "/opt/nessus/sbin/nessusd" ] ); then
    echo "Nessus does not appear to be installed."
    read -p "Would you like to install Nessus? (y/n): " install_nessus
    if [[ "$install_nessus" == "y" || "$install_nessus" == "Y" ]]; then
        echo "Please install Nessus manually from https://www.tenable.com/products/nessus/nessus-download"
        exit 1
    else
        echo "Nessus is required. Exiting installation."
        exit 1
    fi
fi

# --- Check for Required Dependencies ---
dependencies=(sed chmod find zenity gio)
for dep in "${dependencies[@]}"; do
    if ! command_exists "$dep"; then
        echo "Dependency '$dep' is not installed."
        read -p "Would you like to install '$dep'? (y/n): " install_dep
        if [[ "$install_dep" == "y" || "$install_dep" == "Y" ]]; then
            if command_exists apt-get; then
                sudo apt-get update && sudo apt-get install -y "$dep"
            elif command_exists yum; then
                sudo yum install -y "$dep"
            else
                echo "No supported package manager found. Please install '$dep' manually."
                exit 1
            fi
        else
            echo "The dependency '$dep' is required. Exiting installation."
            exit 1
        fi
    fi
done

# --- Prompt for Desktop Path ---
DEFAULT_DESKTOP="${HOME}/Desktop"
read -e -p "Enter the full path to your desktop [${DEFAULT_DESKTOP}]: " -i "${DEFAULT_DESKTOP}" DESKTOP_PATH
DESKTOP_PATH=${DESKTOP_PATH:-${DEFAULT_DESKTOP}}
if [ ! -d "$DESKTOP_PATH" ]; then
    echo "The provided path does not exist or is not a directory. Exiting."
    exit 1
fi

# --- Check for Existing Installation ---
if [ -f "$VERSION_FILE" ]; then
    INSTALLED_VERSION=$(cat "$VERSION_FILE")
    echo "An existing installation is detected with version: $INSTALLED_VERSION"
    echo "Current version is: $CURRENT_VERSION"
    read -p "Do you want to overwrite the existing installation? (y/n): " overwrite
    if [[ "$overwrite" == "y" || "$overwrite" == "Y" ]]; then
        echo "Overwriting existing installation..."
        sudo rm -rf "$SCRIPTS_DIR"
    else
        echo "Installation canceled."
        exit 0
    fi
else
    echo "No existing installation found."
fi

# --- Create Scripts Directory ---
echo "Creating directory: $SCRIPTS_DIR"
sudo mkdir -p "$SCRIPTS_DIR"

# --- Copy .sh Files to Scripts Directory ---
echo "Copying shell scripts to $SCRIPTS_DIR..."
find . -type f -name "*.sh" ! -name "install.sh" -exec sudo cp {} "$SCRIPTS_DIR" \;
sudo find "$SCRIPTS_DIR" -type f -name "*.sh" -exec chmod 755 {} \;

# --- Process .desktop Files ---
echo "Processing .desktop files..."
while IFS= read -r -d '' desktop_file; do
    filename=$(basename "$desktop_file")
    # Replace {SCRIPTS_DIR} placeholder with the scripts directory
    sed "s|{SCRIPTS_DIR}|$SCRIPTS_DIR|g" "$desktop_file" > "$DESKTOP_PATH/$filename"
    
    # Mark the .desktop file as trusted using gio
    if command_exists gio; then
        gio set -t boolean "$DESKTOP_PATH/$filename" metadata::trusted true 2>/dev/null
        gio set -t string "$DESKTOP_PATH/$filename" metadata::xfce-exe-checksum "$(sha256sum "$DESKTOP_PATH/$filename" | cut -d' ' -f1)" 2>/dev/null
    else
        echo "gio command not found. Skipping setting trust for $filename."
    fi
done < <(find . -type f -name "*.desktop" -print0)

# --- Set Permissions for Desktop Files ---
echo "Setting permissions for desktop files..."
find "$DESKTOP_PATH" -maxdepth 1 -type f -name "*.desktop" -exec chmod 755 {} \;

# --- Create Version File ---
echo "$CURRENT_VERSION" | sudo tee "$VERSION_FILE" > /dev/null

echo "Installation complete."
echo "Desktop files have been copied to: $DESKTOP_PATH"
echo "Shell scripts have been copied to: $SCRIPTS_DIR"
