#! /bin/sh
chmod -R 755 LCD-show
sudo cp kiosk.sh /home/pi
sudo cp kiosk.service /lib/systemd/system/
sudo systemctl enable kiosk.service
sudo cp lightdm.conf /etc/lightdm
sudo apt-get install unclutter
unclutter -idle 0.01 -root
reboot
