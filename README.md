# TunnelFastConfig

Максимально простой и быстрый способ развернуть Xray VPN (VLESS + XTLS-Reality) через Docker. 
Без тяжеловесных веб-панелей, без баз данных, потребляет всего 20-30 МБ ОЗУ.

## Требования
* Сервер с установленным **Docker** и **Docker Compose**.
* Свободный порт `443`.

## Проверка доступности порта 443
Перед установкой убедитесь, что порт 443 не занят другим веб-сервером:
```bash
sudo ss -tulpn | grep :443
```
Если порт занят старым VPN (TrustTunnel) или nginx, остановите процесс (например, `sudo systemctl stop trusttunnel`).

## Установка и запуск (1 минута)

1. **Склонируйте репозиторий:**
   ```bash
   git clone https://github.com/AI-Agents-account/TunnelFastConfig.git
   cd TunnelFastConfig
   ```

2. **Запустите скрипт автоматической настройки:**
   Скрипт скачает образ, сгенерирует ключи и создаст `config.json`.
   
   Вы можете передать параметр (пресет), под который будет маскироваться ваш VPN. По умолчанию (без параметров) используется `microsoft`.
   Доступные параметры: `microsoft`, `vk`, `yandex`, `gosuslugi`, `apple`, `google`.
   ```bash
   chmod +x setup.sh
   ./setup.sh yandex
   ```

3. **Запустите VPN-сервер:**
   ```bash
   docker compose up -d
   ```

## Как перезапустить сервер (при смене маскировки)
Если вы хотите сменить домен маскировки:
```bash
./setup.sh vk
docker compose down
docker compose up -d
```
Не забудьте обновить ссылку (или SNI) на клиенте!

## Диагностика и решение проблем (Отладка)
Если клиент выдает "Timeout", проверьте работу сервера:
```bash
# Просмотр логов в реальном времени:
docker logs -f xray_vpn

# Кто занимает порт:
sudo ss -tulpn | grep :443

# Статус контейнера:
docker ps -a | grep xray
```
