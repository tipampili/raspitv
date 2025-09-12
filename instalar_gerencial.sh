#! /bin/sh
chmod -R 755 LCD-show
sudo cp kiosk_gerencial.sh /home/pi
sudo cp kiosk_gerencial.service /lib/systemd/system/
sudo systemctl enable kiosk_gerencial.service
sudo cp lightdm.conf /etc/lightdm
sudo apt-get install unclutter
unclutter -idle 0.01 -root
reboot
