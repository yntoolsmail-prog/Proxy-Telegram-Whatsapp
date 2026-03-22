#!/bin/bash
# =============================================================================
# Proxy Bot — удаление
# Использование: bash <(curl -s https://raw.githubusercontent.com/yntoolsmail-prog/Proxy-Telegram-Whatsapp/main/uninstall_proxy.sh)
# =============================================================================
# Version: 2.0

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

HAS_MTP=false;  [[ -f /opt/mtproxy/objs/bin/mtproto-proxy ]] && HAS_MTP=true
HAS_WA=false;   docker ps -a --format "{{.Names}}" 2>/dev/null | grep -q "^whatsapp-proxy$" && HAS_WA=true
HAS_BOT=false;  [[ -f /root/proxy_bot.py ]] && HAS_BOT=true

echo -e "  Обнаружено на сервере:\n"
[[ "$HAS_MTP" == "true" ]] && echo -e "  ${CYAN}•${NC} MTProxy"         || echo -e "  ${YELLOW}•${NC} MTProxy — не установлен"
[[ "$HAS_WA"  == "true" ]] && echo -e "  ${CYAN}•${NC} WhatsApp прокси" || echo -e "  ${YELLOW}•${NC} WhatsApp прокси — не установлен"
[[ "$HAS_BOT" == "true" ]] && echo -e "  ${CYAN}•${NC} Proxy Bot"       || echo -e "  ${YELLOW}•${NC} Proxy Bot — не найден"
echo ""

echo -e "  ${YELLOW}Будут удалены: MTProxy, WhatsApp прокси, proxy-bot и все их файлы.${NC}"
echo ""
echo -e "  ${CYAN}0)${NC} Отмена"
echo -e "  ${CYAN}1)${NC} Удалить"
echo ""
read -p "  Ваш выбор: " CHOICE
[[ "$CHOICE" == "0" || -z "$CHOICE" ]] && { echo "Отменено."; exit 0; }
[[ "$CHOICE" != "1" ]] && { warn "Введите 0 или 1."; exit 1; }

echo ""
read -p "  Подтвердите [y/N]: " CONFIRM
[[ "${CONFIRM,,}" != "y" ]] && { echo "Отменено."; exit 0; }

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

if [[ "$HAS_WA" == "true" ]]; then
    log "Удаляем WhatsApp прокси..."
    docker stop whatsapp-proxy 2>/dev/null || true
    docker rm   whatsapp-proxy 2>/dev/null || true
    docker rmi  facebook/whatsapp_proxy:latest 2>/dev/null || true
    docker rmi  whatsapp-proxy 2>/dev/null || true
    ufw delete allow 80/tcp   2>/dev/null || true
    ufw delete allow 443/tcp  2>/dev/null || true
    ufw delete allow 5222/tcp 2>/dev/null || true
    rm -rf /opt/whatsapp-proxy-src
    warn "Docker оставлен (мог использоваться до установки прокси)."
    log "WhatsApp прокси удалён ✓"
fi

log "Удаляем proxy-bot сервис..."
systemctl stop    proxy-bot 2>/dev/null || true
systemctl disable proxy-bot 2>/dev/null || true
rm -f /etc/systemd/system/proxy-bot.service

log "Удаляем файлы..."
rm -f /root/proxy_bot.py
rm -f /root/.proxy_bot_version
rm -rf /etc/proxy-bot

systemctl daemon-reload

echo ""
echo -e "${GREEN}${BOLD}══════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}   Удаление завершено!${NC}"
echo -e "${GREEN}${BOLD}══════════════════════════════════════════${NC}"
echo ""
command -v docker &>/dev/null && info "Docker оставлен на сервере."
echo ""
