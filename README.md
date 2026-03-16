# Proxy-Telegram-Whatsapp

Установщик прокси-серверов для обхода блокировок Telegram и WhatsApp с управлением через Telegram бота.

> Используется два независимых инструмента: MTProxy — специально для Telegram, WhatsApp прокси — специально для WhatsApp. SOCKS5 не используется — он хуже детектируется DPI и не даёт преимуществ при наличии MTProxy и AmneziaWG.

## Возможности

- **MTProxy** — официальный прокси-протокол Telegram. Режим *fake-TLS* маскирует трафик под обычный HTTPS — DPI не отличает от браузера. Нативная поддержка в клиентах Telegram, не требует сторонних приложений
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

### WhatsApp прокси (WhatsApp)

WhatsApp → Настройки → Конфиденциальность → Расширенные → Использовать прокси

---

## Где смотреть логин и пароль

Все параметры сохраняются в файл при установке:

```bash
cat /etc/proxy-bot/proxy_bot.env
```

Пример вывода:
```
ADMIN_ID=123456789
SERVER_IP=1.2.3.4
MODE=addon
MTP_PORT=443
MTP_SECRET=dd865cfe7e9805354e7b04ae4031200053
SOCKS_PORT=1080
SOCKS_USER=proxy
SOCKS_PASS=a0152d781d635661
```

Готовые ссылки для подключения также выводятся в конце установки. Если пропустили — собрать вручную:

```bash
# MTProxy
source /etc/proxy-bot/proxy_bot.env
echo "https://t.me/proxy?server=${SERVER_IP}&port=${MTP_PORT}&secret=${MTP_SECRET}"

# SOCKS5
echo "socks5://${SOCKS_USER}:${SOCKS_PASS}@${SERVER_IP}:${SOCKS_PORT}"
```

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
journalctl -u microsocks -f

# WhatsApp прокси
docker ps
docker restart whatsapp-proxy
docker logs whatsapp-proxy -f

# Standalone бот
systemctl status proxy-bot
journalctl -u proxy-bot -f

# Addon режим (бот AmneziaWG)
systemctl status awg-bot
journalctl -u awg-bot -f

# Обновить вручную
bash /root/update_proxy.sh

# Лог обновлений
cat /var/log/proxy-bot-update.log
```

---

## Связанные проекты

Этот репозиторий является дополнением к **[Vpn_AWG](https://github.com/yntoolsmail-prog/Vpn_AWG)** — VPN-серверу на базе AmneziaWG с управлением через Telegram бота.

---

## Удаление

```bash
bash <(curl -s https://raw.githubusercontent.com/yntoolsmail-prog/Proxy-Telegram-Whatsapp/main/uninstall_proxy.sh)
```

Скрипт определяет что установлено на сервере и предлагает два варианта:

**1) Удалить только прокси** — останавливает и удаляет MTProxy, SOCKS5, WhatsApp прокси и все их файлы. Если использовался addon режим — автоматически откатывает патч `bot.py` и перезапускает AWG бота. AmneziaWG VPN не затрагивается.

**2) Удалить всё** — дополнительно удаляет AmneziaWG бота, все VPN конфиги и ключи клиентов. Необратимо.

> Docker если был установлен для WhatsApp прокси — намеренно оставляется, так как мог использоваться до установки прокси.

---

## Благодарности

Проект использует следующие открытые решения:

- [GetPageSpeed/MTProxy](https://github.com/GetPageSpeed/MTProxy) — форк MTProxy с исправлением краша на серверах с PID > 65535 (GPLv2)
- [WhatsApp/proxy](https://github.com/WhatsApp/proxy) — официальный прокси от Meta (MIT)
- [python-telegram-bot](https://github.com/python-telegram-bot/python-telegram-bot) — библиотека для Telegram Bot API (LGPLv3)

Код в этом репозитории распространяется под лицензией [MIT](LICENSE).
