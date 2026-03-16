# TunnelFastConfig

Максимально простой и быстрый способ развернуть Xray VPN (VLESS + XTLS-Reality) через Docker. 
Без тяжеловесных веб-панелей, без баз данных, потребляет всего 20-30 МБ ОЗУ.
(Маскируется под трафик `www.microsoft.com`).

## Требования
* Сервер с установленным **Docker** и **Docker Compose**.
* Свободный порт `443`.

## Проверка доступности порта 443

Перед установкой убедитесь, что порт 443 не занят другим веб-сервером (например, Nginx или Apache). Выполните команду:
```bash
sudo ss -tulpn | grep :443
```
Если вывод пуст — порт свободен, можно смело приступать к установке.

**Если порт занят (например, `nginx`):**
Вам необходимо остановить мешающий сервис:
```bash
sudo systemctl stop nginx
sudo systemctl disable nginx
# Или для Apache:
sudo systemctl stop apache2
sudo systemctl disable apache2
```
*(Если вам необходимо, чтобы на сервере одновременно работал и ваш сайт на порту 443, и VPN, потребуется настройка "Xray Fallbacks", когда Xray ставится "перед" Nginx).*

## Установка и запуск (1 минута)

1. **Склонируйте репозиторий:**
   ```bash
   git clone https://github.com/AI-Agents-account/TunnelFastConfig.git
   cd TunnelFastConfig
   ```

2. **Запустите скрипт автоматической настройки:**
   Скрипт скачает образ, сгенерирует UUID, ключи шифрования и автоматически создаст `config.json` на основе шаблона.
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```
   **ОБЯЗАТЕЛЬНО** сохраните данные для клиента (Public Key, UUID, ShortId), которые выведет скрипт по завершении работы!

3. **Запустите VPN-сервер:**
   ```bash
   docker compose up -d
   ```

## Настройка клиента
На телефоне или компьютере (подойдут приложения **v2rayN**, **v2rayNG**, **Hiddify**, **V2Box, Streisand**) добавьте новое **VLESS** подключение со следующими параметрами:

* **Address:** IP-адрес вашего сервера (или доменное имя)
* **Port:** `443`
* **ID:** `Ваш UUID (из вывода скрипта)`
* **Flow:** `xtls-rprx-vision`
* **Network:** `tcp`
* **TLS:** `reality`
* **SNI:** `www.microsoft.com`
* **Public Key:** `Ваш Public Key (Password из вывода скрипта)`
* **ShortId:** `Ваш ShortId (из вывода скрипта)`

Готово!

**Если порт занят старым VPN (TrustTunnel):**
Если в выводе команды `ss -tulpn | grep :443` вы видите `trusttunnel_end`, вам нужно временно остановить этот процесс перед запуском Xray. 

Остановить TrustTunnel:
```bash
# Если он работает как systemd-сервис:
sudo systemctl stop trusttunnel
# (или sudo systemctl stop trusttunnel_endpoint / trusttunnel-server - в зависимости от названия службы)

# Если он запущен напрямую, можно "убить" процесс жестко:
sudo killall trusttunnel_end
```

Чтобы вернуть старый VPN (TrustTunnel) обратно:
```bash
# Сначала выключаем Xray
cd TunnelFastConfig
docker compose down

# Затем запускаем TrustTunnel
sudo systemctl start trusttunnel
# (Или запустите его так же, как вы делали это изначально)
```

## Как перезапустить сервер (при обновлении или смене ключей)

Если вы сгенерировали новые ключи (запустив `setup.sh` еще раз), изменили `config.json` вручную или просто хотите перезагрузить сервер, выполните следующие команды в папке `TunnelFastConfig`:

```bash
# Остановка и удаление текущего контейнера Xray
docker compose down

# Запуск контейнера заново с новыми настройками
docker compose up -d
```

## Диагностика и решение проблем (Отладка)

Если клиент выдает "Timeout" или не подключается, вы можете проверить работу сервера следующими командами:

**1. Просмотр логов Xray (в реальном времени):**
```bash
# Выводит последние логи и следит за новыми (для выхода нажмите Ctrl+C)
docker logs -f xray_vpn
```
*Если VPN работает успешно, при попытке открыть сайт на телефоне вы увидите в логах строки вида `accepted tcp: ... [direct]` (это означает, что трафик пошел).*

**2. Проверка, кто занимает порт 443:**
Если контейнер падает или не может запуститься, возможно, порт занят другой программой (например, nginx или старым VPN).
```bash
sudo ss -tulpn | grep :443
```
*В последней колонке вы увидите название процесса (например, `users:(("nginx",pid=...))`). Этот процесс нужно остановить.*

**3. Проверка статуса контейнера:**
```bash
docker ps -a | grep xray
```
*Статус `Up` означает, что сервер работает. Статус `Restarting` или `Exited` означает ошибку (смотрите логи).*

## Как сменить домен маскировки (Готовые пресеты)

Важное правило протокола **XTLS-Reality**: в список `serverNames` можно добавлять только те домены, которые принадлежат серверу, указанному в параметре `dest`. 
Смешивать в одном конфиге `vk.com` и `microsoft.com` **категорически нельзя** — это сломает подключение, так как сервер Microsoft откажется выдавать сертификат для домена ВКонтакте.

По умолчанию в `config.json` используется маскировка под Microsoft (там уже вписано 9 доменов: `www.microsoft.com`, `update.microsoft.com`, `bing.com`, `skype.com` и т.д., между которыми вы можете переключаться в клиенте без перезагрузки сервера).

Если вы хотите полностью сменить маскировку (например, на российскую для обхода жестких белых списков), откройте ваш файл `config.json` и замените блок `realitySettings` на один из пресетов ниже.

### Пресет 1: Яндекс (Россия)
```json
"realitySettings": {
  "show": false,
  "dest": "ya.ru:443",
  "xver": 0,
  "serverNames": [
    "ya.ru",
    "www.ya.ru",
    "yandex.ru",
    "mail.yandex.ru",
    "disk.yandex.ru",
    "music.yandex.ru"
  ],
  "privateKey": "YOUR_PRIVATE_KEY",
  "shortIds": [
    "YOUR_SHORT_ID"
  ]
}
```

### Пресет 2: ВКонтакте (Россия)
```json
"realitySettings": {
  "show": false,
  "dest": "vk.com:443",
  "xver": 0,
  "serverNames": [
    "vk.com",
    "m.vk.com",
    "api.vk.com",
    "oauth.vk.com"
  ],
  "privateKey": "YOUR_PRIVATE_KEY",
  "shortIds": [
    "YOUR_SHORT_ID"
  ]
}
```

### Пресет 3: Госуслуги (Россия)
```json
"realitySettings": {
  "show": false,
  "dest": "www.gosuslugi.ru:443",
  "xver": 0,
  "serverNames": [
    "www.gosuslugi.ru",
    "esia.gosuslugi.ru",
    "lk.gosuslugi.ru"
  ],
  "privateKey": "YOUR_PRIVATE_KEY",
  "shortIds": [
    "YOUR_SHORT_ID"
  ]
}
```

### Пресет 4: Apple (Зарубежный)
```json
"realitySettings": {
  "show": false,
  "dest": "www.apple.com:443",
  "xver": 0,
  "serverNames": [
    "www.apple.com",
    "icloud.com",
    "www.icloud.com",
    "itunes.apple.com",
    "support.apple.com",
    "update.apple.com"
  ],
  "privateKey": "YOUR_PRIVATE_KEY",
  "shortIds": [
    "YOUR_SHORT_ID"
  ]
}
```

### Пресет 5: Google (Зарубежный)
```json
"realitySettings": {
  "show": false,
  "dest": "dl.google.com:443",
  "xver": 0,
  "serverNames": [
    "dl.google.com",
    "play.google.com",
    "android.clients.google.com",
    "update.googleapis.com"
  ],
  "privateKey": "YOUR_PRIVATE_KEY",
  "shortIds": [
    "YOUR_SHORT_ID"
  ]
}
```

*(После изменения `config.json` не забудьте перезапустить сервер: `docker compose down` и `docker compose up -d`)*
