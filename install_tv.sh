#!/bin/bash
# ===============================================================
# Script de instalação unificado para Raspberry Pi (Modo Kiosk)
# Autor: TI Pampili
# Data: 2025-11
# ===============================================================

# --- Seleção do modo ---
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

# Detectar resolução
RESOLUCAO=$(xrandr | grep -A1 "$DISPLAY_NAME" | grep -o '[0-9]*x[0-9]*' | head -n 1)
if [ -z "$RESOLUCAO" ]; then
  RESOLUCAO="1920x1080"
fi
echo "📏 Resolução detectada: $RESOLUCAO"

# ===============================================================
# CRIAÇÃO DOS ARQUIVOS
# ===============================================================
echo "📝 Criando scripts e serviços..."

# --- Script do Kiosk (Padrão) ---
cat <<EOF > /home/pi/kiosk.sh
#!/bin/bash
xset s noblank
xset s off
xset -dpms
unclutter -idle 0.5 -root &

# Ajustar resolução detectada
xrandr --output $DISPLAY_NAME --mode $RESOLUCAO --primary

# Iniciar o Firefox em modo kiosk
/usr/bin/firefox --kiosk http://192.168.5.20:4000 &
sleep 5

# Alternar entre abas abertas (mantém navegador ativo)
while true; do
   xdotool keydown ctrl+Tab; xdotool keyup ctrl+Tab;
   sleep 10
done
EOF

# --- Script do Kiosk (Gerencial) ---
cat <<EOF > /home/pi/kiosk_gerencial.sh
#!/bin/bash
xset s noblank
xset s off
xset -dpms
unclutter -idle 0.5 -root &

# Ajustar resolução detectada
xrandr --output $DISPLAY_NAME --mode $RESOLUCAO --primary

# Iniciar o Firefox em modo kiosk gerencial
/usr/bin/firefox --kiosk http://192.168.5.20:4000/?tipo=gerencial &
sleep 5

# Alternar entre abas abertas (mantém navegador ativo)
while true; do
   xdotool keydown ctrl+Tab; xdotool keyup ctrl+Tab;
   sleep 10
done
EOF

chmod +x /home/pi/kiosk*.sh

# --- Serviço Padrão ---
cat <<'EOF' > /lib/systemd/system/kiosk.service
[Unit]
Description=Kiosk Mode Firefox
After=systemd-user-sessions.service network.target

[Service]
User=pi
Environment=XAUTHORITY=/home/pi/.Xauthority
Environment=DISPLAY=:0
ExecStart=/home/pi/kiosk.sh
Restart=always
RestartSec=10

[Install]
WantedBy=graphical.target
EOF

# --- Serviço Gerencial ---
cat <<'EOF' > /lib/systemd/system/kiosk_gerencial.service
[Unit]
Description=Kiosk Mode Firefox (Gerencial)
After=systemd-user-sessions.service network.target

[Service]
User=pi
Environment=XAUTHORITY=/home/pi/.Xauthority
Environment=DISPLAY=:0
ExecStart=/home/pi/kiosk_gerencial.sh
Restart=always
RestartSec=10

[Install]
WantedBy=graphical.target
EOF

# --- Configuração LightDM ---
cat <<'EOF' > /etc/lightdm/lightdm.conf
[Seat:*]
greeter-session=pi-greeter
greeter-hide-users=false
display-setup-script=/usr/share/dispsetup.sh
autologin-user=pi
[SeatDefaults]
xserver-command=X -s 0 -dpms
EOF

# ===============================================================
# DEPENDÊNCIAS
# ===============================================================
echo "📦 Instalando dependências..."
apt-get update -y
apt-get install -y unclutter xdotool firefox-esr x11-xserver-utils

# ===============================================================
# ATIVAR SERVIÇO CORRETO
# ===============================================================
echo "⚙️ Ativando o serviço do modo $MODO..."
if [ "$MODO" = "padrao" ]; then
  systemctl disable kiosk_gerencial.service 2>/dev/null
  systemctl enable kiosk.service
else
  systemctl disable kiosk.service 2>/dev/null
  systemctl enable kiosk_gerencial.service
fi

# ===============================================================
# FINALIZAÇÃO
# ===============================================================
echo "✅ Instalação concluída!"
echo "🔁 Reiniciando o sistema em 5 segundos..."
sleep 5
reboot
