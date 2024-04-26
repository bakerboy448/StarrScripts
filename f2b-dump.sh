#!/bin/bash

# Temporary file to hold the Fail2Ban configuration details
temp_file=$(mktemp)

# Function to add content to the temporary file
add_content() {
    echo -e "\n$1\n" >>"$temp_file"
    cat "$2" >>"$temp_file" 2>/dev/null
    echo -e "\n" >>"$temp_file"
}

# List all active jails
echo "Listing all active jails:" >>"$temp_file"
fail2ban-client status >>"$temp_file"

# Get status for each jail
jails=$(fail2ban-client status | grep 'Jail list:' | sed -E 's/^[^:]+:\s+//;s/,//g')
for jail in $jails; do
    echo -e "\nStatus of $jail jail:\n" >>"$temp_file"
    fail2ban-client status "$jail" >>"$temp_file"
done

# Global configurations
add_content "Global Fail2Ban Configuration (/etc/fail2ban/jail.conf):" "/etc/fail2ban/jail.conf"
add_content "Custom Global Configuration (/etc/fail2ban/jail.local):" "/etc/fail2ban/jail.local"

# Custom jail configurations in jail.d/
echo "Custom Jail Configurations in /etc/fail2ban/jail.d/:" >>"$temp_file"
for config_file in /etc/fail2ban/jail.d/*; do
    [ -e "$config_file" ] || continue
    add_content "Custom Jail Configuration ($config_file):" "$config_file"
done

# Upload to termbin
echo "Uploading to Termbin..." >>"$temp_file"
cat "$temp_file" | nc termbin.com 9999

# Cleanup
rm "$temp_file"
