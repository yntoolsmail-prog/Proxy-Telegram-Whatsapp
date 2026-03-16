#!/bin/bash
# =============================================================================
# Proxy Bot — удалятор
# Использование: bash <(curl -s https://raw.githubusercontent.com/yntoolsmail-prog/Proxy-Telegram-Whatsapp/main/uninstall_proxy.sh)
# =============================================================================
# Version: 1.0

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${CYAN}[i]${NC} $1"; }

[[ $EUID -ne 0 ]] && { echo -e "${RED}[✗]${NC} Запускать от root"; exit 1; }

clear
echo -e "${RED}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║         Proxy Bot — Удаление             ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

# ══════════════════════════════════════════════════════════════════════════════
# ОПРЕДЕЛЯЕМ ЧТО УСТАНОВЛЕНО
# ══════════════════════════════════════════════════════════════════════════════
HAS_MTP=false;   [[ -f /opt/mtproxy/objs/bin/mtproto-proxy ]] && HAS_MTP=true
HAS_WA=false;    docker ps -a --format "{{.Names}}" 2>/dev/null | grep -q "^whatsapp-proxy$" && HAS_WA=true
HAS_BOT=false;   [[ -f /root/proxy_bot.py ]]                  && HAS_BOT=true
HAS_AWG=false;   [[ -f /etc/amnezia/amneziawg/bot.env ]]      && HAS_AWG=true
IS_ADDON=false
[[ -f /etc/proxy-bot/proxy_bot.env ]] && \
    grep -q "^MODE=addon" /etc/proxy-bot/proxy_bot.env 2>/dev/null && IS_ADDON=true

echo -e "  Обнаружено на сервере:\n"
[[ "$HAS_MTP"   == "true" ]] && echo -e "  ${CYAN}•${NC} MTProxy"          || echo -e "  ${YELLOW}•${NC} MTProxy — не установлен"
[[ "$HAS_WA"    == "true" ]] && echo -e "  ${CYAN}•${NC} WhatsApp прокси"  || echo -e "  ${YELLOW}•${NC} WhatsApp прокси — не установлен"
[[ "$HAS_AWG"   == "true" ]] && echo -e "  ${CYAN}•${NC} AmneziaWG бот"   || echo -e "  ${YELLOW}•${NC} AmneziaWG бот — не найден"
[[ "$IS_ADDON"  == "true" ]] && echo -e "  ${CYAN}•${NC} Режим: addon (встроен в AWG бота)"
echo ""

# ══════════════════════════════════════════════════════════════════════════════
# ВЫБОР РЕЖИМА УДАЛЕНИЯ
# ══════════════════════════════════════════════════════════════════════════════
echo -e "  ${CYAN}1)${NC} Удалить только прокси"
if [[ "$IS_ADDON" == "true" ]]; then
    echo -e "     MTProxy, WhatsApp прокси, откат bot.py"
    echo -e "     ${GREEN}AmneziaWG бот остаётся нетронутым${NC}"
else
    echo -e "     MTProxy, WhatsApp прокси и proxy-bot сервис"
fi
echo ""

if [[ "$HAS_AWG" == "true" ]]; then
    echo -e "  ${CYAN}2)${NC} Удалить всё — прокси ${RED}и${NC} AmneziaWG"
    echo -e "     ${RED}Внимание: удалит VPN, всех клиентов и конфиги AWG${NC}"
    echo ""
    MAX_CHOICE=2
else
    MAX_CHOICE=1
fi

echo -e "  ${CYAN}0)${NC} Отмена"
echo ""
while true; do
    read -p "  Ваш выбор: " CHOICE
    [[ "$CHOICE" == "0" ]] && { echo "Отменено."; exit 0; }
    [[ "$CHOICE" =~ ^[1-${MAX_CHOICE}]$ ]] && break
    warn "Введите корректный вариант."
done

# Подтверждение
echo ""
if [[ "$CHOICE" == "2" ]]; then
    echo -e "  ${RED}${BOLD}Будет удалено ВСЁ: VPN, прокси, все конфиги и клиенты.${NC}"
else
    echo -e "  ${YELLOW}Будут удалены все прокси-сервисы.${NC}"
    [[ "$IS_ADDON" == "true" ]] && echo -e "  ${GREEN}AWG бот будет восстановлен.${NC}"
fi
echo ""
read -p "  Подтвердите [y/N]: " CONFIRM
[[ "${CONFIRM,,}" != "y" ]] && { echo "Отменено."; exit 0; }

# ══════════════════════════════════════════════════════════════════════════════
# УДАЛЕНИЕ ПРОКСИ
# ══════════════════════════════════════════════════════════════════════════════

# MTProxy
if [[ "$HAS_MTP" == "true" ]]; then
    log "Удаляем MTProxy..."
    systemctl stop    mtproxy 2>/dev/null || true
    systemctl disable mtproxy 2>/dev/null || true
    rm -f /etc/systemd/system/mtproxy.service
    rm -rf /opt/mtproxy
    MTP_PORT=$(grep '^MTP_PORT=' /etc/proxy-bot/proxy_bot.env 2>/dev/null | cut -d= -f2)
    [[ -n "$MTP_PORT" ]] && ufw delete allow "${MTP_PORT}/tcp" 2>/dev/null || true
    log "MTProxy удалён ✓"
fi

# WhatsApp
if [[ "$HAS_WA" == "true" ]]; then
    log "Удаляем WhatsApp прокси..."
    docker stop whatsapp-proxy  2>/dev/null || true
    docker rm   whatsapp-proxy  2>/dev/null || true
    docker rmi  ghcr.io/whatsapp/proxy:latest 2>/dev/null || true
    WA_PORT=$(grep '^WA_PORT=' /etc/proxy-bot/proxy_bot.env 2>/dev/null | cut -d= -f2)
    [[ -n "$WA_PORT" ]] && ufw delete allow "${WA_PORT}/tcp" 2>/dev/null || true
    # Docker оставляем — мог быть установлен до нас
    warn "Docker оставлен (мог использоваться до установки прокси)."
    log "WhatsApp прокси удалён ✓"
fi

# Standalone proxy-bot сервис
if [[ "$IS_ADDON" == "false" && "$HAS_BOT" == "true" ]]; then
    log "Удаляем proxy-bot сервис..."
    systemctl stop    proxy-bot 2>/dev/null || true
    systemctl disable proxy-bot 2>/dev/null || true
    rm -f /etc/systemd/system/proxy-bot.service
fi

# Файлы прокси
log "Удаляем файлы..."
rm -f /root/proxy_bot.py
rm -f /root/update_proxy.sh
rm -f /root/.proxy_bot_version
rm -rf /etc/proxy-bot
rm -f /var/log/proxy-bot-update.log

# Убираем из cron
crontab -l 2>/dev/null | grep -v update_proxy.sh | crontab - 2>/dev/null || true

systemctl daemon-reload

# ══════════════════════════════════════════════════════════════════════════════
# ОТКАТ ПАТЧА bot.py (addon режим)
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$IS_ADDON" == "true" && -f /root/bot.py ]]; then
    log "Откатываем патч bot.py..."
    python3 - << 'PYEOF'
with open('/root/bot.py', 'r') as f:
    src = f.read()

src = src.replace("""
# ── Proxy Bot аддон ─────────────────────────────────────────────────────────
try:
    import proxy_bot as _proxy
    PROXY_ENABLED = True
except ImportError:
    PROXY_ENABLED = False
""", "")

src = src.replace("""    elif data.startswith("proxy_") and is_admin:
        if PROXY_ENABLED:
            await _proxy.handle_proxy_callback(query, data, user_id, ADMIN_ID)
        else:
            await query.answer("Proxy Bot не установлен", show_alert=True)
""", "")

src = src.replace("""            [InlineKeyboardButton("📡 Прокси",              callback_data="proxy_menu")],
""", "")

with open('/root/bot.py', 'w') as f:
    f.write(src)
print("bot.py откатан ✓")
PYEOF

    log "Перезапускаем AWG бота..."
    systemctl restart awg-bot
    sleep 2
    systemctl is-active --quiet awg-bot && log "AWG бот запущен ✓" || warn "AWG бот не запустился — journalctl -u awg-bot"
fi

# ══════════════════════════════════════════════════════════════════════════════
# УДАЛЕНИЕ AWG (только если выбран вариант 2)
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$CHOICE" == "2" ]]; then
    log "Удаляем AmneziaWG..."

    # Определяем интерфейс
    AWG_IFACE=$(grep '^VPN_IFACE=' /etc/amnezia/amneziawg/server.env 2>/dev/null | cut -d= -f2)
    AWG_IFACE=${AWG_IFACE:-awg0}
    AWG_PORT=$(grep '^SERVER_PORT=' /etc/amnezia/amneziawg/server.env 2>/dev/null | cut -d= -f2)

    systemctl stop    awg-bot 2>/dev/null || true
    systemctl disable awg-bot 2>/dev/null || true
    systemctl stop    "awg-quick@${AWG_IFACE}" 2>/dev/null || true
    systemctl disable "awg-quick@${AWG_IFACE}" 2>/dev/null || true

    rm -f /etc/systemd/system/awg-bot.service
    rm -f /root/bot.py /root/vpn.sh /root/update.sh
    rm -f /root/.bot_version
    rm -rf /etc/amnezia
    rm -f /var/log/awg-bw.log /var/log/awg-update.log

    [[ -n "$AWG_PORT" ]] && ufw delete allow "${AWG_PORT}/udp" 2>/dev/null || true

    crontab -l 2>/dev/null | grep -v update.sh | crontab - 2>/dev/null || true

    systemctl daemon-reload
    log "AmneziaWG удалён ✓"
fi

# ══════════════════════════════════════════════════════════════════════════════
# ИТОГ
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}${BOLD}══════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}   Удаление завершено!${NC}"
echo -e "${GREEN}${BOLD}══════════════════════════════════════════${NC}"
echo ""
if [[ "$CHOICE" == "1" && "$IS_ADDON" == "true" ]]; then
    info "AWG бот восстановлен и работает."
fi
if [[ "$CHOICE" == "1" ]] && command -v docker &>/dev/null; then
    info "Docker оставлен на сервере."
fi
echo ""
