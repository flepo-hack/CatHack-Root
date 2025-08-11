#!/data/data/com.termux/files/usr/bin/bash

# Värit
CYAN='\033[0;36m'
NC='\033[0m'

cat_banner() {
    echo -e "${CYAN}"
    echo " /\_/\  "
    echo "( o.o )  Root Cat Prompt"
    echo " > ^ <   by Flepo"
    echo -e "${NC}"
}

# Root-tarkistus
if [ "$(id -u)" -ne 0 ]; then
    echo "⚠️Script must be run with root!"
    exit 1
fi

while true; do
    clear
    cat_banner
    echo "1) Wifi (Show password for choosen wifi)"
    echo "2) IP (Ip adress inf)"
    echo "3) EXIT"
    read -p "Valinta: " choice

    case "$choice" in
        1)
            echo ""
            echo "📡 Scanning wifis..."
            echo ""
            iw dev wlan0 scan 2>/dev/null | grep SSID | sed 's/SSID: //g' | sort -u

            echo ""
            echo "🔍 Searching passwords..."
            # Lista mahdollisista konfiguraatiotiedostoista
            FILES=(
                "/data/misc/wifi/WifiConfigStore.xml"
                "/data/misc/wifi/wpa_supplicant.conf"
                "/data/misc/apexdata/com.android.wifi/WifiConfigStore.xml"
                "/data/misc/apexdata/com.android.wifi/WifiConfigStoreStore.xml"
            )

            for FILE in "${FILES[@]}"; do
                if [ -f "$FILE" ]; then
                    echo ""
                    echo "📂 Found file: $FILE"
                    grep -E 'SSID|psk' "$FILE" | sed 's/^[ \t]*//'
                fi
            done

            echo ""
            echo "✅ Search ready."
            ;;
        2)
            echo ""
            echo "💻 network connections:"
            ip link show | awk -F': ' '{print $2}' | grep -v '^$'
            echo ""
            read -p "Give comnection (e.g. wlan0): " iface
            if ip addr show "$iface" &>/dev/null; then
                ip addr show "$iface"
            else
                echo "❌ No comnection found."
            fi
            ;;
        3)
            echo "🐾 Bye😼!"
            exit 0
            ;;
        *)
            echo "❌ Unknow choice"
            ;;
    esac
    echo ""
    read -p "Press enter to return menu..."
done
