#!/bin/bash
# install.sh
# This script checks for Nessus and required dependencies (including zenity),
# prompts for the user's desktop path (defaulting to $HOME/Desktop),
# creates a custom directory in /opt for shell scripts,
# copies all .sh files to that custom directory,
# updates the Exec lines in all .desktop files (replacing {SCRIPTS_DIR} with /opt/nessusdesktop),
# and copies the updated .desktop files to the user's desktop.
# Finally, it sets appropriate file permissions.

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

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

# --- Check for required dependencies ---
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

# --- Create custom directory for shell scripts ---
SCRIPTS_DIR="/opt/nessusdesktop"
if [ ! -d "$SCRIPTS_DIR" ]; then
    echo "Creating custom directory for shell scripts: $SCRIPTS_DIR"
    sudo mkdir -p "$SCRIPTS_DIR"
fi

# --- Copy .sh files to custom directory ---
echo "Copying shell scripts to $SCRIPTS_DIR..."
find . -type f -name "*.sh" -exec sudo cp {} "$SCRIPTS_DIR" \;
sudo find "$SCRIPTS_DIR" -type f -name "*.sh" -exec chmod 755 {} \;

# --- Process .desktop files ---
# Replace the placeholder {SCRIPTS_DIR} with the custom directory in the Exec line,
# then copy the updated .desktop file to the user's desktop.
echo "Processing .desktop files..."
while IFS= read -r -d '' desktop_file; do
    filename=$(basename "$desktop_file")
    sed "s|{SCRIPTS_DIR}|$SCRIPTS_DIR|g" "$desktop_file" > "$DESKTOP_PATH/$filename"
done < <(find . -type f -name "*.desktop" -print0)

# --- Set permissions for the copied .desktop files ---
echo "Setting permissions for the desktop files..."
find "$DESKTOP_PATH" -maxdepth 1 -type f -name "*.desktop" -exec chmod 755 {} \;

echo "Installation complete."
echo ".desktop files have been copied to: $DESKTOP_PATH"
echo "Shell scripts have been copied to: $SCRIPTS_DIR"
