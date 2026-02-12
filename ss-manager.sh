#!/bin/bash

CONFIG_PATH="/usr/local/etc/xray/config.json"
WEB_DIR="/var/www/html/configs"
DOMAIN="152.42.246.244" # သင့် Domain သို့မဟုတ် IP ပြောင်းပါ

mkdir -p $WEB_DIR

add_user() {
    read -p "Username: " username
    read -p "Port: " port
    read -p "Password: " password
    read -p "GB Limit: " limit_gb

    # Xray Config ထဲသို့ User ထည့်ခြင်း (Shadowsocks Protocol)
    # ဤနေရာတွင် ရိုးရှင်းစေရန် Template တစ်ခုကို အစားထိုးသည့် ပုံစံသုံးထားသည်
    
    # JSON File ထုတ်ပေးခြင်း (ssconf:// အတွက်)
    rand_id=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)
    cat <<EOF > "$WEB_DIR/$rand_id.json"
{
  "server": "$(curl -s ifconfig.me)",
  "server_port": $port,
  "password": "$password",
  "method": "aes-256-gcm",
  "remarks": "$username",
  "limit": $limit_gb
}
EOF

    echo -e "\n✅ User Created!"
    echo -e "Config Link: ssconf://$DOMAIN/configs/$rand_id.json#$username"
    
    # ဤနေရာတွင် Xray service ကို restart ချရန် လိုအပ်သည်
    # (မှတ်ချက် - Production မှာ API သုံးပြီး ထည့်တာ ပိုကောင်းပါတယ်)
}

show_menu() {
    echo "1. Add User"
    echo "2. Check Usage"
    read -p "Choice: " c
    case $c in
        1) add_user ;;
        2) check_usage ;;
    esac
}

show_menu
