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
            echo "📡 Getting saved WiFi networks..."
            echo ""

            # Etsitään kaikki tallennetut SSID:t useista lähteistä
            SSID_LIST=$( \
                grep -oP '(?<=<string name="SSID">).*?(?=</string>)' /data/misc/wifi/WifiConfigStore.xml 2>/dev/null; \
                grep -oP '(?<=<string name="SSID">).*?(?=</string>)' /data/misc/apexdata/com.android.wifi/WifiConfigStore.xml 2>/dev/null; \
                grep -oP '(?<=ssid=").*?(?=")' /data/misc/wifi/wpa_supplicant.conf 2>/dev/null \
            | sort -u )

            if [ -z "$SSID_LIST" ]; then
                echo "❌ Ei löydetty tallennettuja verkkoja."
                read -p "Press enter to return to menu..."
                continue
            fi

            echo "$SSID_LIST"
            echo ""
            read -p "🔑 Enter SSID to get password: " ssid_choice
            echo ""
            echo "🔍 Searching password for \"$ssid_choice\"..."

            # Haetaan salasana eri tiedostoista
            found_pass=$( \
                awk -v ssid="\"$ssid_choice\"" '
                    BEGIN {found=0}
                    $0 ~ "<string name=\"SSID\">"ssid"<\/string>" {found=1; next}
                    found && $0 ~ "<string name=\"PreSharedKey\">" {
                        gsub(/.*<string name="PreSharedKey">|<\/string>.*/, "", $0)
                        print $0
                        exit
                    }
                    $0 ~ "<string name=\"SSID\">" && found {found=0}
                ' /data/misc/wifi/WifiConfigStore.xml /data/misc/apexdata/com.android.wifi/WifiConfigStore.xml 2>/dev/null;
                awk -v ssid="$ssid_choice" '
                    $0 ~ "network={" {net=1}
                    net && $0 ~ "ssid=\""ssid"\"" {found=1}
                    found && $0 ~ "psk=" {
                        gsub(/psk=|"| /, "", $0)
                        print $0
                        exit
                    }
                    $0 ~ "}" && net {net=0; found=0}
                ' /data/misc/wifi/wpa_supplicant.conf 2>/dev/null \
            )

            if [ -n "$found_pass" ]; then
                echo "✅ Password for \"$ssid_choice\": $found_pass"
            else
                echo "❌ Password not found."
            fi
            ;;
        2)
            echo ""
            read -p "🌐 Enter IP address: " ipaddr
            if [[ "$ipaddr" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo "🔎 Getting info for $ipaddr..."
                if command -v jq >/dev/null 2>&1; then
                    curl -s "http://ip-api.com/json/$ipaddr" | jq
                else
                    curl -s "http://ip-api.com/json/$ipaddr"
                fi
            else
                echo "❌ Invalid IP format."
            fi
            ;;
        3)
            echo "🐾 Bye😼!"
            exit 0
            ;;
        *)
            echo "❌ Unknown choice"
            ;;
    esac
    echo ""
    read -p "Press enter to return to menu..."
done
