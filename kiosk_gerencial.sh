#!/bin/bash
xset s noblank
xset s off
xset -dpms

unclutter -idle 0.5 -root &

# Iniciar o Firefox em modo kiosk
/usr/bin/firefox --kiosk http://192.168.5.20:4000/?tipo=gerencial  &

# Aguarda o Firefox abrir para evitar erro com xdotool
sleep 5

# Caso tenha múltiplas abas abertas, alterna entre elas
while true; do
   xdotool keydown ctrl+Tab; xdotool keyup ctrl+Tab;
   sleep 10
done

