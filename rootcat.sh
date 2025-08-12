#!/data/data/com.termux/files/usr/bin/bash

# Värit
CYAN='\033[0;36m'
NC='\033[0m'

cat_banner() {
    echo -e "${CYAN}"
    echo " /\_/\  "
    echo "( o.o )  CatHack Prompt"
    echo " > ^ <   by Flepo"
    echo -e "${NC}"
}

# Root-tarkistus
if [ "$(id -u)" -ne 0 ]; then
    echo "⚠️ Script must be run with root!"
    exit 1
fi

while true; do
    clear
    cat_banner
    echo "1) Wifi (Show password for chosen wifi)"
    echo "2) IP (IP address info)"
    echo "3) EXIT"
    read -p "Valinta: " choice

    case "$choice" in
        1)
            echo ""
            echo "📡 Scanning WiFis..."
            echo ""

            # Selvitetään oikea wlan-interface
            WLAN_IFACE=$(iw dev | grep Interface | awk '{print $2}' | head -n 1)
            if [ -z "$WLAN_IFACE" ]; then
                echo "❌ Ei löydetty wlan-laitetta."
                read -p "Press enter to return to menu..."
                continue
            fi

            # Toistuva skannaus kunnes löytyy verkkoja
            while true; do
                SSID_LIST=$(iw dev "$WLAN_IFACE" scan 2>/dev/null | grep 'SSID:' | sed 's/SSID: //' | sort -u)
                if [ -n "$SSID_LIST" ]; then
                    echo "$SSID_LIST"
                    break
                else
                    echo "⚠️ Ei verkkoja löytynyt, yritetään uudelleen..."
                    sleep 3
                fi
            done

            echo ""
            read -p "🔑 Enter SSID to get password: " ssid_choice
            echo ""
            echo "🔍 Searching password for \"$ssid_choice\"..."

            found_pass=""
            FILES=(
                "/data/misc/wifi/WifiConfigStore.xml"
                "/data/misc/wifi/wpa_supplicant.conf"
                "/data/misc/apexdata/com.android.wifi/WifiConfigStore.xml"
                "/data/misc/apexdata/com.android.wifi/WifiConfigStoreStore.xml"
            )

            for FILE in "${FILES[@]}"; do
                if [ -f "$FILE" ]; then
                    if [[ "$FILE" == *.xml ]]; then
                        pass=$(awk -v ssid="\"$ssid_choice\"" '
                            BEGIN {found=0}
                            $0 ~ "<string name=\"SSID\">"ssid"<\/string>" {found=1; next}
                            found && $0 ~ "<string name=\"PreSharedKey\">" {
                                gsub(/.*<string name="PreSharedKey">|<\/string>.*/, "", $0)
                                print $0
                                exit
                            }
                            $0 ~ "<string name=\"SSID\">" && found {found=0}
                        ' "$FILE")
                    else
                        pass=$(awk -v ssid="$ssid_choice" '
                            $0 ~ "network={" {net=1}
                            net && $0 ~ "ssid=\""ssid"\"" {found=1}
                            found && $0 ~ "psk=" {
                                gsub(/psk=|"| /, "", $0)
                                print $0
                                exit
                            }
                            $0 ~ "}" && net {net=0; found=0}
                        ' "$FILE")
                    fi

                    if [ -n "$pass" ]; then
                        found_pass="$pass"
                        break
                    fi
                fi
            done

            if [ -n "$found_pass" ]; then
                echo "✅ Password for \"$ssid_choice\": $found_pass"
            else
                echo "❌ Password not found in phone files, trying aircrack-ng..."
                if ! command -v aircrack-ng >/dev/null 2>&1; then
                    echo "📥 aircrack-ng not found, installing..."
                    pkg update && pkg install aircrack-ng -y
                fi
                read -p "📂 Enter path to .cap handshake file: " cap_file
                if [ ! -f "$cap_file" ]; then
                    echo "❌ File not found: $cap_file"
                    continue
                fi
                read -p "📂 Enter path to wordlist: " wordlist
                if [ ! -f "$wordlist" ]; then
                    echo "❌ File not found: $wordlist"
                    continue
                fi
                aircrack-ng -w "$wordlist" -e "$ssid_choice" "$cap_file"
            fi
            ;;
        2)
            echo ""
            read -p "🌐 Enter IP address: " ipaddr
            if [[ "$ipaddr" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo "🔎 Getting info for $ipaddr..."
                if comm
                
