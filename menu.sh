



whiptail --title "OPTIONAL KEY SPECIFICATIONS" --checklist \
"GPG requires that you specify an name or alias for your keys. Specify which of the following, if any, you would like to configure with your keys." 15 60 4 \
"E-mail address" "Basic usage" ON \
"Passphrase" "Desktop usage" OFF \
"Expiry" "Desktop & Server" OFF 



exitstatus=$?

if [ $exitstatus = 0 ]; then
  echo "The chosen distro is:" $VERSION
else
  echo "You chose Cancel."
fi


exit 


OPTIONS=$(whiptail --title "YUBiKEY CONFIGURATOR" --menu "Specify your setttings" 15 60 4 \
"1" "Master key" \
"2" "Subkeys" \
"3" "Web-server install" \
"4" "Openstack install" \
"5" "custom install" 3>&1 1>&2 2>&3)

exitstatus=$?

if [ $exitstatus = 0 ]; then
  echo "Your selected option:" $OPTIONS
else
  echo "You chose cancel."
fi