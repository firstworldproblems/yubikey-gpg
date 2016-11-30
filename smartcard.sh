#!/bin/bash


#!/bin/bash
# Bash Menu Script Example
#!/bin/bash

 

while true; do
    if [[ -z   $(lsusb | grep 1050:0111) ]]; then
    	sleep 0.5
    else 
    	break
    fi



done

echo Yubikey connected....


echo Configuring Yubikey as composite HID + CCID device
ykpersonalize -m82 -y -v

sudo apt-get install gnupg2 gnupg-agent libpth20 pinentry-curses libccid pcscd scdaemon libksba8