#!/bin/bash
 
# Define colour codes
GREEN="\e[32m"
RED="\e[31m"
ORANGE="\e[33m"
RESET="\e[0m"
 
# Check if Nessus is already running before prompting for password
if systemctl is-active --quiet nessusd; then
    echo -e "${ORANGE}Nessus is already running.${RESET}"
    echo "Press any key to exit (or wait 30 seconds)..."
    read -n 1 -s -t 30 key && exit 0
fi
 
# Display message before prompting for the password
echo "Attempting to start the Nessus service..."
 
# Prompt for sudo password securely using Zenity (silent mode)
PASSWORD=$(zenity --password --title="Authentication Required" --width=250 --height=100 2>/dev/null)
 
# If user cancels the password prompt, exit silently
if [ -z "$PASSWORD" ]; then
    exit 1
fi
 
# Use the password securely to start Nessus, suppressing output
echo "$PASSWORD" | sudo -S systemctl start nessusd >/dev/null 2>&1
 
# Clear the password from memory immediately
unset PASSWORD
 
# Check if the service started successfully
if systemctl is-active --quiet nessusd; then
    echo -e "${GREEN}Nessus service started successfully.${RESET}"
else
    echo -e "${RED}Failed to start Nessus service.${RESET}"
    exit 1
fi
 
# Display success message and wait for key press or timeout
echo "Press any key to exit (or wait 30 seconds)..."
read -n 1 -s -t 30 key && exit 0
