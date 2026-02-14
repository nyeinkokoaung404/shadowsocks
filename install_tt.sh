#!/bin/bash

# အရောင်သတ်မှတ်ချက်များ
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# ကိုယ့်ကိုယ်ကို permission ပြန်ပေးတဲ့အပိုင်း (Optional but helpful)
chmod +x "$0"

echo -e "${GREEN}>>> TrustTunnel Full Auto-Installer စတင်နေပါပြီ...${NC}"

# ၁။ လိုအပ်သည်များ Update လုပ်ခြင်း
sudo apt update && sudo apt upgrade -y
sudo apt install certbot curl -y

# ၂။ TrustTunnel ဆွဲယူပြီး တပ်ဆင်ခြင်း
mkdir -p /opt/trusttunnel
curl -fsSL https://raw.githubusercontent.com/TrustTunnel/TrustTunnel/refs/heads/master/scripts/install.sh | sh -s -
cd /opt/trusttunnel

# ၃။ User ထံမှ အချက်အလက်များ တောင်းခံခြင်း
echo -e "${GREEN}--- Configuration သတ်မှတ်ရန် ---${NC}"
read -p "သင့် Domain ကို ထည့်ပါ (ဥပမာ- channel.404.com): " DOMAIN
read -p "သင့် Email ကို ထည့်ပါ: " EMAIL
read -p "Admin Panel အတွက် Password သတ်မှတ်ပါ: " ADMIN_PASSWORD
IP_ADDR=$(curl -s ifconfig.me)

# ၄။ SSL Certificate ထုတ်ယူခြင်း
echo -e "${GREEN}>>> SSL Certificate ထုတ်ယူနေပါပြီ...${NC}"
sudo certbot certonly --standalone -d $DOMAIN --email $EMAIL --agree-tos --non-interactive --quiet

# ၅။ Permission ပြင်ဆင်ခြင်း
sudo chmod -R 755 /etc/letsencrypt/archive/
sudo chmod -R 755 /etc/letsencrypt/live/

# ၆။ vpn.toml ဖိုင်ကို အလိုအလျောက် ဖန်တီးခြင်း
cat <<EOF > /opt/trusttunnel/vpn.toml
[server]
listen = "0.0.0.0:443"
cert_path = "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
key_path = "/etc/letsencrypt/live/${DOMAIN}/privkey.pem"

[admin]
password = "${ADMIN_PASSWORD}"
EOF

touch /opt/trusttunnel/hosts.toml

# ၇။ Systemd Service File ဖန်တီးခြင်း
cat <<EOF | sudo tee /etc/systemd/system/trusttunnel.service
[Unit]
Description=TrustTunnel Endpoint Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/trusttunnel
ExecStart=/opt/trusttunnel/trusttunnel_endpoint /opt/trusttunnel/vpn.toml /opt/trusttunnel/hosts.toml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ၈။ Firewall Setting
sudo ufw allow 22/tcp
sudo ufw allow 443/tcp
sudo ufw allow 80/tcp
sudo ufw --force enable

# ၉။ Service စတင်ခြင်း
sudo systemctl daemon-reload
sudo systemctl enable trusttunnel
sudo systemctl start trusttunnel

echo -e "${GREEN}--------------------------------------------------${NC}"
echo -e "${GREEN}တပ်ဆင်မှု အောင်မြင်ပါသည်။${NC}"
echo -e "Domain: ${DOMAIN}"
echo -e "IP: ${IP_ADDR}"
echo -e "Admin Password: ${ADMIN_PASSWORD}"
echo -e "${GREEN}--------------------------------------------------${NC}"
