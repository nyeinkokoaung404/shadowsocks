#!/bin/bash

# အရောင်သတ်မှတ်ချက်များ
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# ကိုယ့်ကိုယ်ကို Permission ပြန်ပေးခြင်း
chmod +x "$0"

echo -e "${GREEN}>>> TrustTunnel Full Auto-Installer (Version 2026) စတင်နေပါပြီ...${NC}"

# ၁။ လိုအပ်သည်များ Update လုပ်ခြင်း
sudo apt update && sudo apt upgrade -y
sudo apt install certbot curl -y

# ၂။ TrustTunnel ဆွဲယူပြီး တပ်ဆင်ခြင်း
mkdir -p /opt/trusttunnel
curl -fsSL https://raw.githubusercontent.com/TrustTunnel/TrustTunnel/refs/heads/master/scripts/install.sh | sh -s -
cd /opt/trusttunnel

# ၃။ User ထံမှ အချက်အလက်များ တောင်းခံခြင်း
echo -e "${GREEN}--- Configuration သတ်မှတ်ရန် ---${NC}"
read -p "သင့် Domain ကို ထည့်ပါ (ဥပမာ- tst.channel404.xyz): " DOMAIN
read -p "သင့် Email ကို ထည့်ပါ: " EMAIL
read -p "Admin Panel အတွက် Password သတ်မှတ်ပါ: " ADMIN_PASSWORD
IP_ADDR=$(curl -s ifconfig.me)

# ၄။ SSL ရွေးချယ်မှု
echo -e "${GREEN}ဘယ် SSL ကို အသုံးပြုမလဲ?${NC}"
echo "1) Let's Encrypt (အလိုအလျောက် ထုတ်ယူမည်)"
echo "2) Cloudflare Origin SSL (Manual ကူးထည့်မည်)"
read -p "ရွေးချယ်မှု (1 သို့မဟုတ် 2): " SSL_CHOICE

if [ "$SSL_CHOICE" == "1" ]; then
    echo -e "${GREEN}>>> Let's Encrypt SSL ထုတ်ယူနေပါပြီ...${NC}"
    sudo certbot certonly --standalone -d $DOMAIN --email $EMAIL --agree-tos --non-interactive --quiet
    CERT_PATH="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
    KEY_PATH="/etc/letsencrypt/live/${DOMAIN}/privkey.pem"
else
    echo -e "${GREEN}>>> cert.pem စာသားများကို ကူးထည့်ပါ (Ctrl+O, Enter, Ctrl+X ဖြင့်သိမ်းပါ)${NC}"
    sleep 2 && sudo nano /opt/trusttunnel/cert.pem
    echo -e "${GREEN}>>> key.pem စာသားများကို ကူးထည့်ပါ (Ctrl+O, Enter, Ctrl+X ဖြင့်သိမ်းပါ)${NC}"
    sleep 2 && sudo nano /opt/trusttunnel/key.pem
    CERT_PATH="/opt/trusttunnel/cert.pem"
    KEY_PATH="/opt/trusttunnel/key.pem"
fi

# ၅။ Permission ပြင်ဆင်ခြင်း
sudo chmod -R 755 /etc/letsencrypt/archive/ 2>/dev/null
sudo chmod -R 755 /etc/letsencrypt/live/ 2>/dev/null

# ၆။ vpn.toml ကို Version အသစ် Format အတိုင်း ဖန်တီးခြင်း
echo -e "${GREEN}>>> vpn.toml ကို Configuration များ ထည့်သွင်းနေပါပြီ...${NC}"
cat <<EOF > /opt/trusttunnel/vpn.toml
listen_address = "0.0.0.0:443"
credentials_file = "credentials.toml"
cert_path = "${CERT_PATH}"
key_path = "${KEY_PATH}"

[admin]
password = "${ADMIN_PASSWORD}"
EOF

# credentials.toml အလွတ်တစ်ခု ကြိုဆောက်ထားခြင်း
touch /opt/trusttunnel/credentials.toml

# ၇။ Systemd Service File ဖန်တီးခြင်း
cat <<EOF | sudo tee /etc/systemd/system/trusttunnel.service
[Unit]
Description=TrustTunnel Endpoint Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/trusttunnel
ExecStart=/opt/trusttunnel/trusttunnel_endpoint /opt/trusttunnel/vpn.toml /opt/trusttunnel/credentials.toml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ၈။ Firewall Setting
# sudo ufw allow 22/tcp
# sudo ufw allow 443/tcp
# sudo ufw allow 80/tcp
# sudo ufw --force enable

# ၉။ Service စတင်ခြင်း
sudo systemctl daemon-reload
sudo systemctl enable trusttunnel
sudo systemctl start trusttunnel

echo -e "${GREEN}--------------------------------------------------${NC}"
echo -e "တပ်ဆင်မှု အောင်မြင်ပါသည်။"
echo -e "Domain: ${DOMAIN}"
echo -e "IP: ${IP_ADDR}"
echo -e "Admin Password: ${ADMIN_PASSWORD}"
echo -e "--------------------------------------------------${NC}"
echo -e "ယခု Admin Command ကို သုံး၍ User များ စီမံနိုင်ပါပြီ:"
echo -e "./trusttunnel_endpoint vpn.toml credentials.toml -c admin -a ${IP_ADDR}:443"
