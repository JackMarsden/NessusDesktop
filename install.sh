#!/bin/bash
# install.sh
# This script checks for Nessus and required dependencies (including zenity),
# prompts for the user's desktop path (defaulting to $HOME/Desktop),
# updates the Exec lines in all .desktop files (replacing {DESKTOP_PATH} with the chosen path),
# copies the updated .desktop files to that desktop,
# and sets appropriate file permissions.

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Check for Nessus ---
# Verify if 'nessusd' is in PATH or exists in the typical installation directory.
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

# --- Check for required dependencies ---
# List of dependencies used in the repository's shell scripts.
dependencies=(sed chmod find zenity)
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

# --- Process and copy .desktop files ---
# For each .desktop file, update its Exec line (replacing {DESKTOP_PATH} with the provided path)
# and then copy the updated file to the user's desktop.
echo "Processing .desktop files..."
while IFS= read -r -d '' desktop_file; do
    filename=$(basename "$desktop_file")
    # Update the Exec parameter by replacing the placeholder {DESKTOP_PATH}
    sed "s|{DESKTOP_PATH}|$DESKTOP_PATH|g" "$desktop_file" > "$DESKTOP_PATH/$filename"
done < <(find . -type f -name "*.desktop" -print0)

# --- Set appropriate file permissions ---
echo "Setting file permissions..."
# Make the copied .des
