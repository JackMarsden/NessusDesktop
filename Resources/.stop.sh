#!/bin/bash
# Define colour codes
GREEN="\e[32m"
RED="\e[31m"
ORANGE="\e[33m"
RESET="\e[0m"
# Check if Nessus is already stopped before prompting for password
if ! systemctl is-active --quiet nessusd; then
    echo -e "${ORANGE}Nessus is already stopped.${RESET}"
    echo "Press any key to exit (or wait 30 seconds)..."
    read -n 1 -s -t 30 key && exit 0
fi
# Display message before prompting for the password
echo "Attempting to stop the Nessus service..."
# Prompt for sudo password securely using Zenity (silent mode)
PASSWORD=$(zenity --password --title="Authentication Required" --width=250 --height=100 2>/dev/null)
# If user cancels the password prompt, exit silently
if [ -z "$PASSWORD" ]; then
    exit 1
fi
# Use the password securely to stop Nessus, suppressing output
echo "$PASSWORD" | sudo -S systemctl stop nessusd >/dev/null 2>&1
# Clear the password from memory immediately
unset PASSWORD
# Check if the service stopped successfully
if ! systemctl is-active --quiet nessusd; then
    echo -e "${GREEN}Nessus service stopped successfully.${RESET}"
else
    echo -e "${RED}Failed to stop Nessus service.${RESET}"
    exit 1
fi
# Display success message and wait for key press or timeout
echo "Press any key to exit (or wait 30 seconds)..."
read -n 1 -s -t 30 key && exit 0