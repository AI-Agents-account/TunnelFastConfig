#!/bin/bash
set -e

echo "=== Генерация ключей для TunnelFastConfig (Xray VLESS + Reality) ==="

if ! command -v docker &> /dev/null; then
    echo "Ошибка: Docker не установлен."
    exit 1
fi

echo "Подготовка: обновляем образ xray-core..."
docker pull ghcr.io/xtls/xray-core:latest > /dev/null 2>&1 || true

echo "1. Генерируем UUID..."
# Подавляем возможные логи пула, чтобы не засорять UUID
UUID=$(docker run --rm ghcr.io/xtls/xray-core uuid 2>/dev/null | tr -d '\r')
echo "UUID: $UUID"

if [ -z "$UUID" ]; then
    echo "Ошибка: не удалось сгенерировать UUID!"
    exit 1
fi

echo "2. Генерируем пару ключей..."
# Утилита xray выводит ключи x25519 в stderr, объединяем потоки
KEYS=$(docker run --rm ghcr.io/xtls/xray-core x25519 2>&1)

# В новых версиях Xray формат вывода изменился:
# Было: "Private key: ...", "Public key: ..."
# Стало: "PrivateKey: ...", "Password: ...", "Hash32: ..." (или "PublicKey:" в некоторых билдах)
# В xtls-reality:
# PrivateKey -> privateKey в config.json
# Password -> это и есть Public Key для клиента

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
echo "SNI: vk.com"
echo "Public Key: $PUBLIC_KEY"
echo "ShortId: $SHORT_ID"
echo "-----------------------------------"
echo "Сохраните эти данные!"
echo "Теперь вы можете запустить сервер командой: docker compose up -d"

# Получаем публичный IP сервера для генерации ссылки
SERVER_IP=$(curl -s4 api.ipify.org || curl -s4 icanhazip.com || echo "IP_ВАШЕГО_СЕРВЕРА")
VLESS_LINK="vless://${UUID}@${SERVER_IP}:443?type=tcp&security=reality&flow=xtls-rprx-vision&pbk=${PUBLIC_KEY}&fp=chrome&sni=vk.com&sid=${SHORT_ID}&spx=%2F#TunnelFast"

echo ""
echo "🔥 БОНУС: Готовая ссылка для быстрого импорта:"
echo "-----------------------------------"
echo "$VLESS_LINK"
echo "-----------------------------------"
echo "Просто скопируйте эту ссылку и вставьте ее в клиент (например, V2Box) из буфера обмена."
