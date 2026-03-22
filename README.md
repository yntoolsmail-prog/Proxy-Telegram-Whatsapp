# Proxy-Telegram-Whatsapp

Установщик прокси-серверов для обхода блокировок Telegram и WhatsApp с управлением через Telegram бота.

> Используется два независимых инструмента: MTProxy — специально для Telegram, WhatsApp прокси — специально для WhatsApp. SOCKS5 не используется — он хуже детектируется DPI и не даёт преимуществ при наличии MTProxy и AmneziaWG.

## Возможности

- **MTProxy** — официальный прокси-протокол Telegram. Режимы *EE (TLS 1.3)* и *fake-TLS* маскируют трафик под обычный HTTPS — DPI не отличает от браузера. Нативная поддержка в клиентах Telegram, не требует сторонних приложений
- **WhatsApp прокси** — официальный образ от Meta. Встроенная поддержка в WhatsApp начиная с версии 2.22.x
- **Telegram бот** — управление всеми прокси из одного интерфейса: статус, запуск/остановка, смена секрета, ссылки для подключения, инструкции
- **Уведомления об обновлениях** — бот ежедневно проверяет репозиторий и сообщает если появилась новая версия

## Требования

- Ubuntu 22.04 или 24.04
- VPS с root доступом
- Telegram бот (получить у @BotFather)

## Установка

```bash
bash <(curl -s https://raw.githubusercontent.com/yntoolsmail-prog/Proxy-Telegram-Whatsapp/main/setup_proxy.sh)
```

Установщик спросит:

1. **Режим вывода** — тихий или подробный
2. **Прокси** — MTProxy, WhatsApp прокси или оба
3. **Порт и тип секрета** для MTProxy (EE / fake-TLS / plain)
4. **Токен бота** и Telegram ID администратора
5. **Часовой пояс** для корректного отображения времени в логах

> ⚠️ WhatsApp прокси требует Docker (~200 MB установка, ~50 MB RAM постоянно)

---

## Подключение клиентов

### MTProxy (Telegram)

- **Android:** Настройки → Данные и память → Прокси
- **ПК:** Настройки → Продвинутые настройки → Тип соединения

Или перейти по ссылке из бота — она откроет Telegram и добавит прокси автоматически.

### WhatsApp прокси

WhatsApp → Настройки → Конфиденциальность → Расширенные → Использовать прокси

Введите IP сервера и порт 443.

---

## Управление через бота

Напишите `/start` боту в Telegram. Доступно:

**MTProxy:**
- Старт / стоп / рестарт
- Смена секрета (EE / fake-TLS / plain) с подтверждением
- Обновление конфигов Telegram
- Текущая ссылка для подключения

**WhatsApp прокси:**
- Старт / стоп / рестарт
- Обновление образа от Meta
- Адрес для подключения

**Сервер:**
- RAM, диск, load average, аптайм

---

## Управление через терминал

```bash
# MTProxy
systemctl status mtproxy
systemctl restart mtproxy
journalctl -u mtproxy -f

# WhatsApp прокси
docker ps
docker restart whatsapp-proxy
docker logs whatsapp-proxy -f

# Бот
systemctl status proxy-bot
journalctl -u proxy-bot -f

# Обновить вручную
curl -sf https://raw.githubusercontent.com/yntoolsmail-prog/Proxy-Telegram-Whatsapp/main/proxy_bot.py \
    -o /root/proxy_bot.py && systemctl restart proxy-bot

# Параметры подключения
cat /etc/proxy-bot/proxy_bot.env
```

---

## Восстановление ссылки MTProxy

```bash
source /etc/proxy-bot/proxy_bot.env
echo "https://t.me/proxy?server=${SERVER_IP}&port=${MTP_PORT}&secret=${MTP_SECRET}"
```

---

## Удаление

```bash
bash <(curl -s https://raw.githubusercontent.com/yntoolsmail-prog/Proxy-Telegram-Whatsapp/main/uninstall_proxy.sh)
```

Скрипт останавливает и удаляет MTProxy, WhatsApp прокси, бота и все их файлы.

> Docker если был установлен для WhatsApp прокси — намеренно оставляется, так как мог использоваться до установки прокси.

---

## Благодарности

- [GetPageSpeed/MTProxy](https://github.com/GetPageSpeed/MTProxy) — форк MTProxy с исправлением краша на серверах с PID > 65535 (GPLv2)
- [facebook/whatsapp_proxy](https://hub.docker.com/r/facebook/whatsapp_proxy) — официальный образ от Meta (MIT)
- [python-telegram-bot](https://github.com/python-telegram-bot/python-telegram-bot) — библиотека для Telegram Bot API (LGPLv3)

Код в этом репозитории распространяется под лицензией [MIT](LICENSE).
