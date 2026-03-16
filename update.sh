#!/bin/bash
sed -i 's/FoXray/V2Box, Streisand/g' README.md

cat << 'INNER_EOF' >> setup.sh

# Получаем публичный IP сервера для генерации ссылки
SERVER_IP=\$(curl -s ifconfig.me || echo "IP_ВАШЕГО_СЕРВЕРА")
VLESS_LINK="vless://\${UUID}@\${SERVER_IP}:443?type=tcp&security=reality&pbk=\${PUBLIC_KEY}&fp=chrome&sni=vk.com&sid=\${SHORT_ID}&spx=%2F#TunnelFast"

echo ""
echo "🔥 БОНУС: Готовая ссылка для быстрого импорта:"
echo "-----------------------------------"
echo "\$VLESS_LINK"
echo "-----------------------------------"
echo "Скопируйте эту ссылку и вставьте ее в клиент (например, V2Box) из буфера обмена."
INNER_EOF
