#!/bin/bash
# =============================================================================
# Proxy Bot — установщик (MTProxy + WhatsApp прокси)
# Использование: bash <(curl -s https://raw.githubusercontent.com/yntoolsmail-prog/Proxy-Telegram-Whatsapp/main/setup_proxy.sh)
# =============================================================================
# Version: 1.0

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }
info() { echo -e "${CYAN}[i]${NC} $1"; }
sep()  { echo -e "${CYAN}${BOLD}── $1 ──────────────────────────────────────${NC}"; }

[[ $EUID -ne 0 ]] && err "Запускать от root"

RAW_BASE="https://raw.githubusercontent.com/yntoolsmail-prog/Proxy-Telegram-Whatsapp/main"
MTP_DIR="/opt/mtproxy"
MTP_BIN="$MTP_DIR/objs/bin/mtproto-proxy"
CONF_DIR="/etc/proxy-bot"
CONF_FILE="$CONF_DIR/proxy_bot.env"
AWG_BOT_FILE="/root/bot.py"
PROXY_BOT_FILE="/root/proxy_bot.py"

clear
echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║         Proxy Bot — Установка            ║"
echo "  ║     MTProxy + WhatsApp для Telegram     ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

# ══════════════════════════════════════════════════════════════════════════════
# ОПРЕДЕЛЯЕМ НАЛИЧИЕ AWG БОТА
# ══════════════════════════════════════════════════════════════════════════════
AWG_FOUND=false
if [[ -f /etc/amnezia/amneziawg/bot.env && -f "$AWG_BOT_FILE" ]]; then
    AWG_FOUND=true
fi

# ══════════════════════════════════════════════════════════════════════════════
# ШАГ 1: РЕЖИМ
# ══════════════════════════════════════════════════════════════════════════════
sep "Режим установки"
echo ""
echo -e "  ${CYAN}1)${NC} ${BOLD}Standalone${NC} — отдельный бот, новый токен у @BotFather"
echo -e "     Работает независимо. Два бота в Telegram."
echo ""

INSTALL_MODE="standalone"

if [[ "$AWG_FOUND" == "true" ]]; then
    echo -e "  ${CYAN}2)${NC} ${BOLD}Addon${NC} — встраивается в существующий бот AmneziaWG"
    echo -e "     Тот же токен, кнопка ${CYAN}📡 Прокси${NC} появится в меню."
    echo ""
    while true; do
        read -p "  Ваш выбор [1]: " MODE_CHOICE
        MODE_CHOICE=${MODE_CHOICE:-1}
        [[ "$MODE_CHOICE" == "1" || "$MODE_CHOICE" == "2" ]] && break
        warn "Введите 1 или 2."
    done
    [[ "$MODE_CHOICE" == "2" ]] && INSTALL_MODE="addon"
else
    info "AmneziaWG бот не обнаружен — доступен только Standalone режим."
    read -p "  Нажмите Enter для продолжения..." _
fi

# ══════════════════════════════════════════════════════════════════════════════
# ШАГ 2: ПРОКСИ
# ══════════════════════════════════════════════════════════════════════════════
echo ""
sep "Выбор прокси"
echo ""
echo -e "  ${CYAN}1)${NC} ${BOLD}MTProxy + WhatsApp${NC} ${GREEN}(рекомендуется)${NC}"
echo -e "     MTProxy для Telegram + официальный прокси для WhatsApp."
echo -e "     ${YELLOW}⚠ WhatsApp требует Docker${NC} (~200 MB установка, ~50 MB RAM постоянно)"
echo ""
echo -e "  ${CYAN}2)${NC} ${BOLD}Только MTProxy${NC} — для Telegram"
echo -e "     Нативная поддержка в Telegram. Быстро, без Docker."
echo ""
echo -e "  ${CYAN}3)${NC} ${BOLD}Только WhatsApp прокси${NC}"
echo -e "     Официальный контейнер от Meta."
echo -e "     ${YELLOW}⚠ Требует Docker${NC} (~200 MB установка, ~50 MB RAM постоянно)"
echo ""
while true; do
    read -p "  Ваш выбор [1]: " PROXY_CHOICE
    PROXY_CHOICE=${PROXY_CHOICE:-1}
    [[ "$PROXY_CHOICE" =~ ^[1-3]$ ]] && break
    warn "Введите 1, 2 или 3."
done

INSTALL_MTP=false; INSTALL_WA=false
case "$PROXY_CHOICE" in
    1) INSTALL_MTP=true; INSTALL_WA=true ;;
    2) INSTALL_MTP=true                  ;;
    3)                   INSTALL_WA=true ;;
esac

# Предупреждение про Docker
if [[ "$INSTALL_WA" == "true" ]]; then
    echo ""
    echo -e "  ${YELLOW}${BOLD}Внимание — WhatsApp прокси использует Docker:${NC}"
    echo -e "  • Установка Docker: ~200 MB"
    echo -e "  • Постоянное потребление RAM: ~50 MB"
    echo -e "  • Образ WhatsApp/proxy от Meta (~30 MB)"
    echo -e "  • Docker запускается при старте системы"
    echo ""
    read -p "  Продолжить? [Y/n]: " WA_CONFIRM
    WA_CONFIRM=${WA_CONFIRM:-y}
    if [[ "${WA_CONFIRM,,}" != "y" ]]; then
        INSTALL_WA=false
        warn "WhatsApp прокси исключён."
    fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# ШАГ 3: ТОКЕН И ADMIN ID
# ══════════════════════════════════════════════════════════════════════════════
mkdir -p "$CONF_DIR"
chmod 700 "$CONF_DIR"

if [[ "$INSTALL_MODE" == "standalone" ]]; then
    echo ""
    sep "Токен бота"
    echo ""
    echo -e "  Создайте нового бота у ${YELLOW}@BotFather${NC} → /newbot"
    echo ""
    while true; do
        read -p "  Вставьте токен бота: " BOT_TOKEN
        [[ "$BOT_TOKEN" == *":"* && ${#BOT_TOKEN} -gt 20 ]] && break
        warn "Неверный формат."
    done
    echo ""
    echo -e "  Узнайте ID у ${YELLOW}@userinfobot${NC}"
    echo ""
    while true; do
        read -p "  Вставьте ваш Telegram ID: " ADMIN_ID
        [[ "$ADMIN_ID" =~ ^[0-9]+$ ]] && break
        warn "ID должен быть числом."
    done
    echo ""
    log "Определяю IP сервера..."
    SERVER_IP=$(curl -sf --max-time 10 https://api.ipify.org 2>/dev/null || \
                curl -sf --max-time 10 https://ifconfig.me  2>/dev/null || echo "")
    if [[ -z "$SERVER_IP" ]]; then
        read -p "  Не удалось определить. Введите IP: " SERVER_IP
    else
        info "IP: ${SERVER_IP}"
    fi
    printf "BOT_TOKEN=%s\nADMIN_ID=%s\nSERVER_IP=%s\nMODE=standalone\n" \
        "$BOT_TOKEN" "$ADMIN_ID" "$SERVER_IP" > "$CONF_FILE"
    chmod 600 "$CONF_FILE"
else
    ADMIN_ID=$(grep '^ADMIN_ID='   /etc/amnezia/amneziawg/bot.env    | cut -d= -f2)
    SERVER_IP=$(grep '^SERVER_IP=' /etc/amnezia/amneziawg/server.env | cut -d= -f2)
    printf "ADMIN_ID=%s\nSERVER_IP=%s\nMODE=addon\n" "$ADMIN_ID" "$SERVER_IP" > "$CONF_FILE"
    chmod 600 "$CONF_FILE"
    info "Admin ID: ${ADMIN_ID}  |  IP: ${SERVER_IP}"
fi

# ══════════════════════════════════════════════════════════════════════════════
# ШАГ 4: ЗАВИСИМОСТИ
# ══════════════════════════════════════════════════════════════════════════════
log "Установка зависимостей..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq curl git build-essential libssl-dev zlib1g-dev xxd

if [[ "$INSTALL_MODE" == "standalone" ]]; then
    log "Установка python-telegram-bot..."
    pip3 install "python-telegram-bot[job-queue]>=22.0,<23" --break-system-packages -q || \
    pip3 install "python-telegram-bot[job-queue]>=22.0,<23" -q || \
    err "Не удалось установить python-telegram-bot."
fi

# ══════════════════════════════════════════════════════════════════════════════
# ШАГ 5: MTPROXY
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$INSTALL_MTP" == "true" ]]; then
    echo ""
    sep "MTProxy"

    if [[ -f "$MTP_BIN" ]]; then
        warn "MTProxy уже собран."
    else
        log "Клонирование MTProxy (GetPageSpeed fork)..."
        rm -rf "$MTP_DIR"
        # Используем форк GetPageSpeed — исправлен краш на серверах с PID > 65535
        # Оригинальный TelegramMessenger/MTProxy падает на таких серверах
        git clone --depth=1 https://github.com/GetPageSpeed/MTProxy "$MTP_DIR" \
            || err "Не удалось скачать MTProxy."
        log "Сборка (~1-2 минуты)..."
        cd "$MTP_DIR" && make -j$(nproc) 2>&1 | tail -3 && cd /root
        [[ -f "$MTP_BIN" ]] || err "Сборка не удалась."
        log "Собран ✓"
    fi

    log "Загрузка конфигов Telegram..."
    curl -sf https://core.telegram.org/getProxySecret -o "$MTP_DIR/proxy-secret" \
        || err "Не удалось скачать proxy-secret."
    curl -sf https://core.telegram.org/getProxyConfig -o "$MTP_DIR/proxy-multi.conf" \
        || err "Не удалось скачать proxy-multi.conf."

    echo ""
    while true; do
        read -p "  Порт MTProxy [443]: " MTP_PORT
        MTP_PORT=${MTP_PORT:-443}
        [[ "$MTP_PORT" =~ ^[0-9]+$ && "$MTP_PORT" -ge 1 && "$MTP_PORT" -le 65535 ]] && break
        warn "Введите корректный порт."
    done
    ss -tlnp 2>/dev/null | grep -q ":${MTP_PORT} " && \
        warn "Порт ${MTP_PORT} занят! Проверьте после установки."

    echo ""
    echo -e "  ${CYAN}${BOLD}Тип секрета (способ маскировки трафика)${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} ${BOLD}fake-TLS${NC} ${GREEN}(рекомендуется)${NC}"
    echo -e "     Трафик выглядит как обычный HTTPS."
    echo -e "     DPI и РКН не могут отличить от обычного сайта."
    echo -e "     Значительно сложнее заблокировать."
    echo ""
    echo -e "  ${CYAN}2)${NC} ${BOLD}plain${NC}"
    echo -e "     Трафик выглядит как MTProxy — протокол виден."
    echo -e "     Легче детектируется и блокируется."
    echo -e "     Выбирайте только если fake-TLS не работает."
    echo ""
    while true; do
        read -p "  Тип секрета [1]: " ST; ST=${ST:-1}
        [[ "$ST" == "1" || "$ST" == "2" ]] && break
    done
    # Секрет — всегда 32 hex символа. Префикс dd добавляется только в ссылку для клиента,
    # но НЕ передаётся в -S флаг бинарника (там строго 32 символа).
    # Для fake-TLS используется флаг -D с доменом.
    MTP_SECRET=$(head -c 16 /dev/urandom | xxd -ps)
    [[ "$ST" == "1" ]] && SECRET_MODE="fake-TLS" || SECRET_MODE="plain"
    # В конфиге и ссылке храним с dd чтобы Telegram понял режим
    [[ "$ST" == "1" ]] && MTP_SECRET_STORE="dd${MTP_SECRET}" || MTP_SECRET_STORE="${MTP_SECRET}"
    [[ "$ST" == "1" ]] && MTP_FAKETLS_FLAG="-D google.com" || MTP_FAKETLS_FLAG=""

    command -v ufw &>/dev/null && ufw allow "${MTP_PORT}/tcp" comment "MTProxy" 2>/dev/null || true

    printf "MTP_PORT=%s\nMTP_SECRET=%s\n" "$MTP_PORT" "$MTP_SECRET_STORE" >> "$CONF_FILE"

    cat > /etc/systemd/system/mtproxy.service << EOF
[Unit]
Description=MTProxy for Telegram
After=network-online.target
Wants=network-online.target

[Service]
ExecStartPre=/bin/sh -c 'curl -sf https://core.telegram.org/getProxySecret -o ${MTP_DIR}/proxy-secret; curl -sf https://core.telegram.org/getProxyConfig -o ${MTP_DIR}/proxy-multi.conf'
ExecStart=${MTP_BIN} -u nobody -p 8888 -H ${MTP_PORT} -S ${MTP_SECRET} ${MTP_FAKETLS_FLAG} --aes-pwd ${MTP_DIR}/proxy-secret ${MTP_DIR}/proxy-multi.conf -M 1
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable mtproxy
    systemctl start  mtproxy
    sleep 2
    systemctl is-active --quiet mtproxy && log "MTProxy запущен ✓" || warn "MTProxy не запустился — journalctl -u mtproxy"
fi

# ══════════════════════════════════════════════════════════════════════════════
# ШАГ 7: WHATSAPP PROXY
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$INSTALL_WA" == "true" ]]; then
    echo ""
    sep "WhatsApp прокси (Docker)"

    # Установка Docker если нет
    if ! command -v docker &>/dev/null; then
        log "Установка Docker..."
        curl -fsSL https://get.docker.com | sh \
            || err "Не удалось установить Docker."
        systemctl enable docker --now
        log "Docker установлен ✓"
    else
        warn "Docker уже установлен."
    fi

    echo ""
    while true; do
        read -p "  Порт WhatsApp прокси [443]: " WA_PORT
        WA_PORT=${WA_PORT:-443}
        [[ "$WA_PORT" =~ ^[0-9]+$ && "$WA_PORT" -ge 1 && "$WA_PORT" -le 65535 ]] && break
        warn "Введите корректный порт."
    done

    # Предупреждение если 443 занят MTProxy
    if [[ "$INSTALL_MTP" == "true" && "$WA_PORT" == "$MTP_PORT" ]]; then
        warn "Порт ${WA_PORT} уже занят MTProxy!"
        read -p "  Введите другой порт для WhatsApp [8443]: " WA_PORT
        WA_PORT=${WA_PORT:-8443}
    fi

    command -v ufw &>/dev/null && {
        ufw allow "${WA_PORT}/tcp"  comment "WhatsApp proxy" 2>/dev/null || true
        ufw allow 5222/tcp          comment "WhatsApp proxy" 2>/dev/null || true
        ufw allow 8080/tcp          comment "WhatsApp proxy" 2>/dev/null || true
        ufw allow 8443/tcp          comment "WhatsApp proxy" 2>/dev/null || true
        ufw allow 8888/tcp          comment "WhatsApp proxy" 2>/dev/null || true
    }

    printf "WA_PORT=%s\n" "$WA_PORT" >> "$CONF_FILE"

    log "Скачиваю образ WhatsApp прокси..."
    docker pull ghcr.io/whatsapp/proxy:latest \
        || err "Не удалось скачать образ. Проверьте доступ к ghcr.io."

    # Удаляем старый контейнер если есть
    docker rm -f whatsapp-proxy 2>/dev/null || true

    log "Запускаю контейнер..."
    docker run -d \
        --name whatsapp-proxy \
        --restart always \
        -p "${WA_PORT}:443" \
        -p "${WA_PORT}:80" \
        -p "5222:5222" \
        -p "8080:8080" \
        -p "8443:8443" \
        -p "8888:8888" \
        ghcr.io/whatsapp/proxy:latest

    sleep 3
    if docker ps --filter "name=whatsapp-proxy" --filter "status=running" | grep -q whatsapp; then
        log "WhatsApp прокси запущен ✓"
    else
        warn "Контейнер не запустился — docker logs whatsapp-proxy"
    fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# ШАГ 8: СКАЧИВАЕМ proxy_bot.py
# ══════════════════════════════════════════════════════════════════════════════
log "Скачиваем proxy_bot.py..."
curl -sf "${RAW_BASE}/proxy_bot.py" -o "$PROXY_BOT_FILE" \
    || err "Не удалось скачать proxy_bot.py."
chmod +x "$PROXY_BOT_FILE"

# ══════════════════════════════════════════════════════════════════════════════
# ШАГ 9: ЗАПУСК — STANDALONE ИЛИ ADDON
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$INSTALL_MODE" == "standalone" ]]; then
    log "Создаём systemd сервис proxy-bot..."
    cat > /etc/systemd/system/proxy-bot.service << 'EOF'
[Unit]
Description=Proxy Bot (MTProxy + WhatsApp)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /root/proxy_bot.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable proxy-bot
    systemctl start  proxy-bot
    sleep 2
    systemctl is-active --quiet proxy-bot && log "Proxy Bot запущен ✓" || warn "Не запустился — journalctl -u proxy-bot"

else
    # ADDON — патчим bot.py
    log "Подключаем аддон к bot.py..."

    if grep -q "proxy_bot" "$AWG_BOT_FILE" 2>/dev/null; then
        warn "Аддон уже подключён, пропускаем патч."
    else
        python3 - "$AWG_BOT_FILE" << 'PYEOF'
import sys

with open(sys.argv[1], 'r') as f:
    src = f.read()

# 1) Импорт
addon_import = '''
# ── Proxy Bot аддон ─────────────────────────────────────────────────────────
try:
    import proxy_bot as _proxy
    PROXY_ENABLED = True
except ImportError:
    PROXY_ENABLED = False
'''
lines = src.split('\n')
last_import = 0
for i, line in enumerate(lines):
    if line.startswith('import ') or line.startswith('from '):
        last_import = i
lines.insert(last_import + 1, addon_import)
src = '\n'.join(lines)

# 2) Кнопка в admin-меню
old = '[InlineKeyboardButton("💾 Бэкап",                callback_data="backup")],'
new = '[InlineKeyboardButton("📡 Прокси",              callback_data="proxy_menu")],\n            ' + old
src = src.replace(old, new)

# 3) Роутинг в button_handler
old_kick = '    elif data.startswith("kick_user_") and is_admin:'
new_route = (
    '    elif data.startswith("proxy_") and is_admin:\n'
    '        if PROXY_ENABLED:\n'
    '            await _proxy.handle_proxy_callback(query, data, user_id, ADMIN_ID)\n'
    '        else:\n'
    '            await query.answer("Proxy Bot не установлен", show_alert=True)\n'
    '    elif data.startswith("kick_user_") and is_admin:'
)
src = src.replace(old_kick, new_route)

with open(sys.argv[1], 'w') as f:
    f.write(src)
print("OK")
PYEOF
        log "bot.py пропатчен ✓"
    fi

    log "Перезапускаем AmneziaWG бота..."
    systemctl restart awg-bot
    sleep 2
    systemctl is-active --quiet awg-bot && log "Бот перезапущен ✓" || warn "Не запустился — journalctl -u awg-bot"
fi

# ══════════════════════════════════════════════════════════════════════════════
# ШАГ 10: СКРИПТ ОБНОВЛЕНИЯ
# ══════════════════════════════════════════════════════════════════════════════
log "Создаём update_proxy.sh..."
cat > /root/update_proxy.sh << 'UPDATEEOF'
#!/bin/bash
RAW="https://raw.githubusercontent.com/yntoolsmail-prog/Proxy-Telegram-Whatsapp/main"
VER_FILE="/root/.proxy_bot_version"
CURRENT=$(cat "$VER_FILE" 2>/dev/null || echo "none")
LATEST=$(curl -s "https://api.github.com/repos/yntoolsmail-prog/Proxy-Telegram-Whatsapp/commits/main" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['sha'][:7])" 2>/dev/null)
[[ -z "$LATEST" || "$CURRENT" == "$LATEST" ]] && exit 0
curl -sf "$RAW/proxy_bot.py" -o /root/proxy_bot.py || exit 1
echo "$LATEST" > "$VER_FILE"
MODE=$(grep '^MODE=' /etc/proxy-bot/proxy_bot.env 2>/dev/null | cut -d= -f2)
[[ "$MODE" == "standalone" ]] && systemctl restart proxy-bot || systemctl restart awg-bot
echo "$(date) — proxy_bot обновлён до $LATEST" >> /var/log/proxy-bot-update.log
UPDATEEOF
chmod +x /root/update_proxy.sh

echo ""
echo -e "  ${CYAN}1)${NC} Включить автообновление ${GREEN}(рекомендуется)${NC}"
echo -e "  ${CYAN}2)${NC} Не включать"
echo ""
while true; do
    read -p "  Автообновление proxy_bot.py [1]: " AU; AU=${AU:-1}
    [[ "$AU" == "1" || "$AU" == "2" ]] && break
done
if [[ "$AU" == "1" ]]; then
    (crontab -l 2>/dev/null; echo "*/15 * * * * /root/update_proxy.sh") | crontab -
    AU_STATUS="${GREEN}активно (каждые 15 минут)${NC}"
else
    AU_STATUS="${YELLOW}отключено${NC}"
fi

# ══════════════════════════════════════════════════════════════════════════════
# ИТОГ
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}${BOLD}══════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}   Установка завершена!${NC}"
echo -e "${GREEN}${BOLD}══════════════════════════════════════════${NC}"
echo ""
info "Режим: ${INSTALL_MODE}"
echo ""

if [[ "$INSTALL_MTP" == "true" ]]; then
    MTP_LINK="https://t.me/proxy?server=${SERVER_IP}&port=${MTP_PORT}&secret=${MTP_SECRET}"
    echo -e "  ${CYAN}📡 MTProxy${NC} (${SECRET_MODE})  порт ${MTP_PORT}"
    echo -e "  ${GREEN}${MTP_LINK}${NC}"
    echo ""
fi

if [[ "$INSTALL_WA" == "true" ]]; then
    echo -e "  ${CYAN}💬 WhatsApp прокси${NC}  порт ${WA_PORT}"
    echo -e "  Адрес для WhatsApp: ${GREEN}${SERVER_IP}:${WA_PORT}${NC}"
    echo ""
fi

if [[ "$INSTALL_MODE" == "standalone" ]]; then
    info "Статус: systemctl status proxy-bot"
    info "Логи:   journalctl -u proxy-bot -f"
    echo -e "  Напишите ${CYAN}/start${NC} боту в Telegram"
else
    echo -e "  Кнопка ${CYAN}📡 Прокси${NC} добавлена в меню AmneziaWG бота"
fi
echo ""
info "Автообновление: ${AU_STATUS}"
echo ""
