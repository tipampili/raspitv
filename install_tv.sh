#!/bin/bash
# ===============================================================
# Script unificado de instalação Kiosk (Raspberry Pi OS)
# Autor: TI Pampili
# Data: 2025-11
# ===============================================================

# --- Escolha do modo ---
MODO=$1
if [ -z "$MODO" ]; then
  echo "Selecione o modo de instalação:"
  echo "1) Padrão"
  echo "2) Gerencial"
  read -rp "Opção [1-2]: " opcao
  case "$opcao" in
    1) MODO="padrao" ;;
    2) MODO="gerencial" ;;
    *) echo "Opção inválida."; exit 1 ;;
  esac
fi

if [ "$MODO" != "padrao" ] && [ "$MODO" != "gerencial" ]; then
  echo "Uso: $0 [padrao|gerencial]"
  exit 1
fi

echo "🔧 Iniciando instalação no modo: $MODO"
sleep 1

# ===============================================================
# DETECÇÃO DE DISPLAY E RESOLUÇÃO
# ===============================================================
echo "🖥️ Detectando tela conectada..."
DISPLAY_NAME=$(xrandr --query | grep " connected" | cut -d ' ' -f1 | head -n 1)

if [ -z "$DISPLAY_NAME" ]; then
  echo "⚠️ Nenhum display detectado via xrandr. Usando :0 como padrão."
  DISPLAY_NAME=":0"
else
  echo "📺 Display detectado: $DISPLAY_NAME"
fi

RESOLUCAO=$(xrandr | grep -A1 "$DISPLAY_NAME" | grep -o '[0-9]*x[0-9]*' | head -n 1)
if [ -z "$RESOLUCAO" ]; then
  RESOLUCAO="1920x1080"
fi
echo "📏 Resolução detectada: $RESOLUCAO"

# ===============================================================
# CRIAÇÃO DOS ARQUIVOS DE KIOSK
# ===============================================================
echo "📝 Criando scripts de execução..."

# --- Script padrão ---
cat <<EOF > /home/pi/kiosk.sh
#!/bin/bash
xset s noblank
xset s off
xset -dpms
unclutter -idle 0.5 -root &

# Ajusta resolução detectada
xrandr --output $DISPLAY_NAME --mode $RESOLUCAO --primary

# Inicia Firefox em modo kiosk padrão
/usr/bin/firefox --kiosk http://192.168.5.20:4000 &
sleep 5

# Mantém alternância entre abas, se houver
while true; do
   xdotool keydown ctrl+Tab; xdotool keyup ctrl+Tab;
   sleep 10
done
EOF

# --- Script gerencial ---
cat <<EOF > /home/pi/kiosk_gerencial.sh
#!/bin/bash
xset s noblank
xset s off
xset -dpms
unclutter -idle 0.5 -root &

# Ajusta resolução detectada
xrandr --output $DISPLAY_NAME --mode $RESOLUCAO --primary

# Inicia Firefox em modo kiosk gerencial
/usr/bin/firefox --kiosk http://192.168.5.20:4000/?tipo=gerencial &
sleep 5

# Mantém alternância entre abas, se houver
while true; do
   xdotool keydown ctrl+Tab; xdotool keyup ctrl+Tab;
   sleep 10
done
EOF

chmod +x /home/pi/kiosk*.sh

# ===============================================================
# CONFIGURAÇÃO DO LIGHTDM E AUTOSTART
# ===============================================================
echo "⚙️ Configurando LightDM e autostart..."

# --- Forçar autologin do usuário pi ---
cat <<'EOF' > /etc/lightdm/lightdm.conf
[Seat:*]
autologin-user=pi
greeter-session=pi-greeter
[SeatDefaults]
xserver-command=X -s 0 -dpms
EOF

# --- Adiciona o kiosk ao autostart do LXDE ---
AUTOSTART_PATH="/etc/xdg/lxsession/LXDE-pi/autostart"

# Garante que o diretório existe
mkdir -p /etc/xdg/lxsession/LXDE-pi

# Remove linhas antigas de kiosk (caso o script tenha sido executado antes)
sed -i '/kiosk.sh/d' "$AUTOSTART_PATH" 2>/dev/null || true
sed -i '/kiosk_gerencial.sh/d' "$AUTOSTART_PATH" 2>/dev/null || true

# Adiciona a linha certa
if [ "$MODO" = "padrao" ]; then
  echo "@bash /home/pi/kiosk.sh" >> "$AUTOSTART_PATH"
else
  echo "@bash /home/pi/kiosk_gerencial.sh" >> "$AUTOSTART_PATH"
fi

# ===============================================================
# DEPENDÊNCIAS
# ===============================================================
echo "📦 Instalando dependências..."
apt-get update -y
apt-get install -y unclutter xdotool firefox-esr x11-xserver-utils

# ===============================================================
# FINALIZAÇÃO
# ===============================================================
echo "✅ Instalação concluída!"
echo "🔁 O sistema será reiniciado em 5 segundos..."
sleep 5
reboot
