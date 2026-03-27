#!/bin/bash
set -e

# Парсим аргумент (пресет маскировки), по умолчанию microsoft
PRESET="${1:-microsoft}"
PRESET=$(echo "$PRESET" | tr '[:upper:]' '[:lower:]')

case "$PRESET" in
    vk|vkontakte)
        DEST="vk.com:443"
        SERVER_NAMES='"vk.com", "m.vk.com", "api.vk.com", "oauth.vk.com"'
        CLIENT_SNI="vk.com"
        ;;
    yandex|ya)
        DEST="ya.ru:443"
        SERVER_NAMES='"ya.ru", "www.ya.ru", "yandex.ru", "mail.yandex.ru", "disk.yandex.ru", "music.yandex.ru"'
        CLIENT_SNI="ya.ru"
        ;;
    gosuslugi|gu)
        DEST="www.gosuslugi.ru:443"
        SERVER_NAMES='"www.gosuslugi.ru", "esia.gosuslugi.ru", "lk.gosuslugi.ru"'
        CLIENT_SNI="www.gosuslugi.ru"
        ;;
    apple)
        DEST="www.apple.com:443"
        SERVER_NAMES='"www.apple.com", "icloud.com", "www.icloud.com", "itunes.apple.com", "update.apple.com"'
        CLIENT_SNI="www.apple.com"
        ;;
    google)
        DEST="dl.google.com:443"
        SERVER_NAMES='"dl.google.com", "play.google.com", "android.clients.google.com", "update.googleapis.com"'
        CLIENT_SNI="dl.google.com"
        ;;
    microsoft|ms|*)
        DEST="www.microsoft.com:443"
        SERVER_NAMES='"www.microsoft.com", "update.microsoft.com", "bing.com", "www.bing.com", "skype.com", "www.skype.com", "login.live.com", "xbox.com"'
        CLIENT_SNI="www.microsoft.com"
        PRESET="microsoft"
        ;;
esac

echo "=== Генерация ключей для TunnelFastConfig (Xray VLESS + Reality) ==="
echo "Выбран пресет маскировки: $PRESET (домен: $CLIENT_SNI)"

if ! command -v docker &> /dev/null; then
    echo "Ошибка: Docker не установлен."
    exit 1
fi

echo "Подготовка: обновляем образ xray-core..."
docker pull ghcr.io/xtls/xray-core:latest > /dev/null 2>&1 || true

echo "1. Генерируем UUID..."
UUID=$(docker run --rm ghcr.io/xtls/xray-core uuid 2>/dev/null | tr -d '\r\n ')
echo "UUID: $UUID"

if [ -z "$UUID" ]; then
    echo "Ошибка: не удалось сгенерировать UUID!"
    exit 1
fi

echo "2. Генерируем пару ключей..."
KEYS=$(docker run --rm ghcr.io/xtls/xray-core x25519 2>&1)
PRIVATE_KEY=$(echo "$KEYS" | grep -iE "^(Private key:|PrivateKey:)" | awk -F': ' '{print $2}' | tr -d '\r\n ')
PUBLIC_KEY=$(echo "$KEYS" | grep -iE "^(Public key:|PublicKey:|Password:)" | awk -F': ' '{print $2}' | tr -d '\r\n ')

if [ -z "$PRIVATE_KEY" ] || [ -z "$PUBLIC_KEY" ]; then
    echo "Критическая ошибка при генерации ключей. Вывод утилиты:"
    echo "$KEYS"
    exit 1
fi

echo "3. Генерируем ShortId..."
SHORT_ID=$(openssl rand -hex 8)
echo "ShortId: $SHORT_ID"

echo "4. Генерируем config.json из шаблона..."
cp config.json.template config.json
sed -i "s|YOUR_UUID|$UUID|g" config.json
sed -i "s|YOUR_PRIVATE_KEY|$PRIVATE_KEY|g" config.json
sed -i "s|YOUR_SHORT_ID|$SHORT_ID|g" config.json
sed -i "s|YOUR_DEST|$DEST|g" config.json
sed -i "s|YOUR_SERVER_NAMES|$SERVER_NAMES|g" config.json

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
echo "SNI: $CLIENT_SNI"
echo "Public Key: $PUBLIC_KEY"
echo "ShortId: $SHORT_ID"
echo "-----------------------------------"
echo "Сохраните эти данные!"

PRIMARY_IFACE=$(ip route show default 2>/dev/null | awk '/default/ {for(i=1;i<=NF;i++) if ($i=="dev") {print $(i+1); exit}}')
SERVER_IP=$(ip -4 addr show dev "$PRIMARY_IFACE" 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -n1)

if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(curl -s4 api.ipify.org || curl -s4 icanhazip.com || echo "IP_ВАШЕГО_СЕРВЕРА")
fi

VLESS_LINK="vless://${UUID}@${SERVER_IP}:443?type=tcp&security=reality&flow=xtls-rprx-vision&pbk=${PUBLIC_KEY}&fp=chrome&sni=${CLIENT_SNI}&sid=${SHORT_ID}&spx=%2F#TunnelFast_${PRESET}"

echo ""
echo "🔥 БОНУС: Готовая ссылка для быстрого импорта:"
echo "-----------------------------------"
echo "$VLESS_LINK"
echo "-----------------------------------"
echo "Скопируйте эту ссылку и вставьте ее в клиент (например, V2Box) из буфера обмена."
echo "Теперь вы можете запустить сервер командой: docker compose up -d"
