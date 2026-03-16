# Proxy-Telegram-Whatsapp

Установщик прокси-серверов для обхода блокировок Telegram и WhatsApp с управлением через Telegram бота.

## Возможности

- **MTProxy** — официальный прокси-протокол Telegram с поддержкой fake-TLS (маскировка под HTTPS). Нативная поддержка в клиентах Telegram, не требует сторонних приложений
- **SOCKS5** — универсальный прокси на базе microsocks. Работает с Telegram и WhatsApp
- **WhatsApp прокси** — официальный контейнер от Meta. Встроенная поддержка в WhatsApp начиная с версии 2.22.x
- **Telegram бот** — управление всеми прокси из одного интерфейса: статус, запуск/остановка, смена секрета, ссылки для подключения
- **Два режима установки** — отдельный бот или встроенный раздел в [AmneziaWG бота](https://github.com/yntoolsmail-prog/Vpn_AWG)
- **Автообновление** — бот обновляется из репозитория автоматически

## Требования

- Ubuntu 22.04 или 24.04
- VPS с root доступом
- Telegram бот (получить у @BotFather) — только для standalone режима

## Установка

```bash
bash <(curl -s https://raw.githubusercontent.com/yntoolsmail-prog/Proxy-Telegram-Whatsapp/main/setup_proxy.sh)
```

Установщик спросит:

1. **Режим** — отдельный бот или встроить в существующий AmneziaWG бот (если обнаружен на сервере)
2. **Прокси** — любую комбинацию из MTProxy, SOCKS5, WhatsApp
3. **Порт и параметры** для каждого выбранного прокси
4. **Автообновление** бота

> ⚠️ WhatsApp прокси требует Docker (~200 MB установка, ~50 MB RAM постоянно)

---

## Режимы установки

### Standalone

Отдельный бот с новым токеном. Работает независимо от других сервисов. Управляется командой `/start`.

```
systemctl status proxy-bot
journalctl -u proxy-bot -f
```

### Addon

Встраивается в существующего [AmneziaWG бота](https://github.com/yntoolsmail-prog/Vpn_AWG). Установщик автоматически обнаруживает бота на сервере и добавляет кнопку **📡 Прокси** в меню администратора. Отдельный токен не нужен.

---

## Подключение клиентов

### MTProxy (Telegram)

Telegram → Настройки → Данные и память → Тип соединения → Добавить прокси → MTProxy

Или перейти по ссылке вида:
```
https://t.me/proxy?server=ВАШ_IP&port=443&secret=ВАШ_СЕКРЕТ
```

### SOCKS5 (Telegram)

Telegram → Настройки → Данные и память → Тип соединения → Добавить прокси → SOCKS5

### SOCKS5 / WhatsApp прокси (WhatsApp)

WhatsApp → Настройки → Конфиденциальность → Расширенные → Использовать прокси

---

## Управление через терминал

```bash
# MTProxy
systemctl status mtproxy
systemctl restart mtproxy
journalctl -u mtproxy -f

# SOCKS5
systemctl status microsocks
systemctl restart microsocks

# WhatsApp прокси
docker ps
docker restart whatsapp-proxy
docker logs whatsapp-proxy

# Обновить вручную
bash /root/update_proxy.sh

# Лог обновлений
cat /var/log/proxy-bot-update.log
```

---

## Связанные проекты

Этот репозиторий является дополнением к **[Vpn_AWG](https://github.com/yntoolsmail-prog/Vpn_AWG)** — VPN-серверу на базе AmneziaWG с управлением через Telegram бота.

---

## Благодарности

Проект использует следующие открытые решения:

- [TelegramMessenger/MTProxy](https://github.com/TelegramMessenger/MTProxy) — официальный MTProxy сервер от Telegram (GPLv2)
- [rofl0r/microsocks](https://github.com/rofl0r/microsocks) — лёгкий SOCKS5 сервер (MIT)
- [WhatsApp/proxy](https://github.com/WhatsApp/proxy) — официальный прокси от Meta (MIT)
- [python-telegram-bot](https://github.com/python-telegram-bot/python-telegram-bot) — библиотека для Telegram Bot API (LGPLv3)

Код в этом репозитории распространяется под лицензией [MIT](LICENSE).
