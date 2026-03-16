#!/bin/bash
set -e

echo "=== Генерация ключей для TunnelFastConfig (Xray VLESS + Reality) ==="

if ! command -v docker &> /dev/null; then
    echo "Ошибка: Docker не установлен. Пожалуйста, установите Docker и Docker Compose."
    exit 1
fi

echo "1. Генерируем UUID..."
UUID=$(docker run --rm ghcr.io/xtls/xray-core xray uuid)
echo "UUID: $UUID"

echo "2. Генерируем пару ключей..."
KEYS=$(docker run --rm ghcr.io/xtls/xray-core xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | grep "Private key:" | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEYS" | grep "Public key:" | awk '{print $3}')

if [ -z "$PRIVATE_KEY" ]; then
    echo "Ошибка при генерации ключей."
    exit 1
fi

echo "3. Генерируем ShortId..."
SHORT_ID=$(openssl rand -hex 8)
echo "ShortId: $SHORT_ID"

echo "4. Применяем настройки к config.json..."
sed -i "s/YOUR_UUID/$UUID/g" config.json
sed -i "s/YOUR_PRIVATE_KEY/$PRIVATE_KEY/g" config.json
sed -i "s/YOUR_SHORT_ID/$SHORT_ID/g" config.json

echo "=== Настройка завершена! ==="
echo ""
echo "Ваши данные для подключения (клиент):"
echo "-----------------------------------"
echo "Address: <IP-адрес вашего сервера>"
echo "Port: 443"
echo "ID (UUID): $UUID"
echo "Flow: xtls-rprx-vision"
echo "Network: tcp"
echo "TLS: reality"
echo "SNI: www.microsoft.com"
echo "Public Key: $PUBLIC_KEY"
echo "ShortId: $SHORT_ID"
echo "-----------------------------------"
echo "Сохраните эти данные!"
echo "Теперь вы можете запустить сервер командой: docker compose up -d"
