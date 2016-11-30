#!/bin/bash


#!/bin/bash
# Bash Menu Script Example
#!/bin/bash
function header(){
keylist=$(gpg --no-default-keyring --secret-keyring ${KEYFILE[Keyring-Secret]} --keyring ${KEYFILE[Keyring-Public]} --list-secret-keys  --keyid-format 0xlong )
userid=$(echo "$keylist" | sed -n -e "s/^.*\(${CONFIG[Name-Real]} \)/\1/p")
keyid=$(echo "$keylist" | grep --color=never -oP "[[:xdigit:]]{16}")
#gpg --list-keys --keyid-format 0xlong | grep -oP "[[:xdigit:]]{16}"
cat << EOM
Description: $*
Date: $(date +"%d %B, %Y")
Time: $(date +%r)
User ID: $userid
Key ID: $keyid

EOM


}

function getkeys(){
keylist=$(gpg --no-default-keyring --secret-keyring ${KEYFILE[Keyring-Secret]} --keyring ${KEYFILE[Keyring-Public]} --list-secret-keys  --keyid-format 0xlong )
userid=$(echo "$keylist" | sed -n -e "s/^.*\(${CONFIG[Name-Real]} \)/\1/p")
keyid=$(echo "$keylist" | grep --color=never -oP "[[:xdigit:]]{16}")

echo -------------
echo "$keylist"

echo --------
echo "$userid"

echo ---------
echo "$keyid"
}


declare -A CONFIG MASTER KEYFILE SUBKEY

# make temporary for folder that won't survive reboot (ref: https://github.com/drduh/YubiKey-Guide#creating-keys)
export GNUPGHOME=$(mktemp -d) 
echo $GNUPGHOME









CONFIG[Name-Real]='Chad Talbott'
CONFIG[Key-Length]=1028
CONFIG[Name-Email]=user@mail.com
CONFIG[Passphrase]=passphrase
CONFIG[Expire-Date]=0


# valid expiry dates:
# Never = 0
# Days = X;
# Weeks = Xw
# Months = Xm
# Years = Xy






SUBKEY[Key-Length]=2048





MASTER[Key-Type]=RSA
MASTER[Key-Usage]=sign
MASTER[%pubring]=$GNUPGHOME/keyring-public.pub
MASTER[%secring]=$GNUPGHOME/keyring-secret.sec





#CONFIG[Name-Email]=vince@gmail.com
#CONFIG[Expire-Date]=0


KEYFILE[Keyring-Public]=$GNUPGHOME/pubring.pub
KEYFILE[Keyring-Secret]=$GNUPGHOME/secring.sec
KEYFILE[master-revocation]=$GNUPGHOME/master-revocation.crt
#KEYFILE[master-public]="$GNUPGHOME/master-public.asc"
#KEYFILE[master-secret]="$GNUPGHOME/master-secret.asc"
#KEYFILE[master-revocation]="$GNUPGHOME/master-revocation.asc"
#KEYFILE[subkey-public]="$GNUPGHOME/subkey-public.asc"
#KEYFILE[subkey-secret]="$GNUPGHOME/subkey-secret.asc"






# pipe temporary gpg configurtion for key generation (ref: https://github.com/drduh/YubiKey-Guide#create-configuration)
cat << EOF > $GNUPGHOME/gpg.conf
personal-cipher-preferences AES256 AES192 AES CAST5
personal-digest-preferences SHA512 SHA384 SHA256 SHA224
default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed
cert-digest-algo SHA512
s2k-digest-algo SHA512
s2k-cipher-algo AES256
charset utf-8
fixed-list-mode
no-comments
no-emit-version
keyid-format 0xlong
list-options show-uid-validity
verify-options show-uid-validity
with-fingerprint
EOF


# MASTER SIGNING KEY 
gpg --verbose --logger-fd=2 --batch --gen-key <<EOF 
Key-Type: ${MASTER[Key-Type]}
Key-Usage: ${MASTER[Key-Usage]}
$(for i in "${!CONFIG[@]}"; do echo "$i: ${CONFIG[$i]}"; done)
%pubring ${KEYFILE[Keyring-Public]}
%secring ${KEYFILE[Keyring-Secret]}
%commit
EOF






# MASTER REVOCATION CERTIFICATE

header "Revocation certificate" > $GNUPGHOME/revoke.txt

touch $GNUPGHOME/status.log
touch $GNUPGHOME/result.log

echo -ne "Y\n1\n${CONFIG[Passphrase]}\n\nY\n${CONFIG[Passphrase]}\n" | \
gpg  --no-default-keyring --quiet --logger-file=$GNUPGHOME/result.log --status-file=$GNUPGHOME/status.log --command-fd=0 --secret-keyring ${KEYFILE[Keyring-Secret]} --keyring ${KEYFILE[Keyring-Public]}  --gen-revoke "${CONFIG[Name-Real]}"  >> $GNUPGHOME/revoke.txt

echo -ne "\n\n\n---------------------------\n\n"
cat $GNUPGHOME/revoke.txt






#echo posting publically 
#gpg  --no-default-keyring --secret-keyring ${KEYFILE[Keyring-Secret]} --keyring ${KEYFILE[Keyring-Public]}  --send-key "$keyid"
#exit 

# SUBKEY - SIGNING
echo -ne "addkey\n${CONFIG[Passphrase]}\n4\n${SUBKEY[Key-Length]}\n0\nsave\n" | \
gpg --logger-fd 2 --verbose --status-fd=2 --command-fd=0  --no-default-keyring --secret-keyring ${KEYFILE[Keyring-Secret]} --keyring ${KEYFILE[Keyring-Public]}  --expert --edit-key "${CONFIG[Name-Real]}"


# SUBKEY - ENCRYPTION
echo -ne "addkey\n${CONFIG[Passphrase]}\n6\n${SUBKEY[Key-Length]}\n0\nsave\n" | \
gpg --logger-fd 2 --verbose --status-fd=2 --command-fd=0  --no-default-keyring --secret-keyring ${KEYFILE[Keyring-Secret]} --keyring ${KEYFILE[Keyring-Public]}  --expert --edit-key "${CONFIG[Name-Real]}"


# SUBKEY - AUTHENTICATION
echo -ne "addkey\n${CONFIG[Passphrase]}\n8\nS\nE\nA\nQ\n${SUBKEY[Key-Length]}\n0\nsave\n" | \
gpg --logger-fd 2 --verbose --status-fd=2 --command-fd=0  --no-default-keyring --secret-keyring ${KEYFILE[Keyring-Secret]} --keyring ${KEYFILE[Keyring-Public]}  --expert --edit-key "${CONFIG[Name-Real]}"




gpg2 --verbose --no-default-keyring --secret-keyring ${KEYFILE[Keyring-Secret]} --keyring ${KEYFILE[Keyring-Public]} --list-secret-keys "${CONFIG[Name-Real]}"


gpg2 --no-default-keyring --secret-keyring ${KEYFILE[Keyring-Secret]} --keyring ${KEYFILE[Keyring-Public]} --armor --output $GNUPGHOME/mastersub.key  --export-secret-keys "${CONFIG[Name-Real]}"

cat $GNUPGHOME/mastersub.key


gpg2 --no-default-keyring --secret-keyring ${KEYFILE[Keyring-Secret]} --keyring ${KEYFILE[Keyring-Public]} --armor --output $GNUPGHOME/masterpublic.key  --export "${CONFIG[Name-Real]}"
cat $GNUPGHOME/masterpublic.key


gpg2 --no-default-keyring --secret-keyring ${KEYFILE[Keyring-Secret]} --keyring ${KEYFILE[Keyring-Public]} --armor --output $GNUPGHOME/subsecret.key  --export-secret-subkeys "${CONFIG[Name-Real]}"
cat $GNUPGHOME/subsecret.key

gpg2 --no-default-keyring --secret-keyring ${KEYFILE[Keyring-Secret]} --keyring ${KEYFILE[Keyring-Public]} --armor --output $GNUPGHOME/sub.key  --export "${CONFIG[Name-Real]}"
cat $GNUPGHOME/sub.key



echo $GNUPGHOME

exit 















# your name/alias and/or e-mail address
# only your name is required, but it must start with a letter and be at least 5 characters long
KEY[name]="user-$(date +%s)" 
KEY[email]=user@email.com


# size of master key; as this isn't uploaded to the yubikey, it can be as large as you wish


# size of subkeys in bits.
# yubikey NEO supports 2048 bits; newer models will support 4096 
SUBKEY[bits]=2048
SUBKEY[expiration]=0

# passphrase for both master and subkeys. 
# neither are necessary but recommended. comment out if you don't want a passphrase
# [ -n "${MASTER[passphrase]}" ] && SUBKEY[passphrase]=${MASTER[passphrase]} # don't alter unless you want a different passphrase for subkeys


# filenames designation for gpg keys and revocation certificate
# unless there is a pressing need to do so, no real need to change
MASTER[public]='master-public.asc'
MASTER[secret]='master-secret.asc'
MASTER[revocation]='master-revocation.asc'
SUBKEY[public]="subkey-public.asc"
SUBKEY[secret]="subkey-secret.asc"







# MASTER KEY REVOCATION CERTIFICATE
# generate a revocation certificate in case subkeys are compromised
# 



exit 




gpg2 --verbose --no-default-keyring --secret-keyring $GNUPGHOME/master.sec --keyring $GNUPGHOME/master.pub --list-secret-keys "${KEY[name]}" | tee $GNUPGHOME/list-of-keys.key



# export keys
gpg2 --no-default-keyring --secret-keyring $GNUPGHOME/master.sec --keyring $GNUPGHOME/master.pub --armor --output $GNUPGHOME/pubkey.txt  --export "${KEY[name]}"

##gpg --armor --export-secret-keys "${KEY[name]}" > $GNUPGHOME/mastersub.key
gpg2 --no-default-keyring --secret-keyring $GNUPGHOME/master.sec --keyring $GNUPGHOME/master.pub --armor --output $GNUPGHOME/mastersub.key  --export-secret-keys "${KEY[name]}"
gpg2 --no-default-keyring --secret-keyring $GNUPGHOME/master.sec --keyring $GNUPGHOME/master.pub --armor --output $GNUPGHOME/sub.key  --export-secret-subkeys "${KEY[name]}"



gpg --no-default-keyring --secret-keyring $GNUPGHOME/master.sec --output $GNUPGHOME/${MASTER[secret]} --keyring $GNUPGHOME/master.pub --armor --export-secret-keys "${KEY[name]}"| tee $GNUPGHOME/master.key

# export master key to ascii-armored file




echo
echo
echo





echo
echo
echo





echo $GNUPGHOME/revocation.crt
echo $GNUPGHOME/mastersub.key
echo $GNUPGHOME/sub.key



exit 
zenity --info --text="<b>NOTE: </b> Insert your YubiKey device \n and then press OK to continue..."



ykpersonalize -m82 -y











exit 


# modifying gnupg configuratin file
cat << EOF > ~/.gnupg/gpg.conf
auto-key-locate keyserver
keyserver hkps://hkps.pool.sks-keyservers.net
keyserver-options no-honor-keyserver-url
keyserver-options ca-cert-file=/etc/sks-keyservers.netCA.pem
keyserver-options no-honor-keyserver-url
keyserver-options debug
keyserver-options verbose
personal-cipher-preferences AES256 AES192 AES CAST5
personal-digest-preferences SHA512 SHA384 SHA256 SHA224
default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed
cert-digest-algo SHA512
s2k-cipher-algo AES256
s2k-digest-algo SHA512
charset utf-8
fixed-list-mode
no-comments
no-emit-version
keyid-format 0xlong
list-options show-uid-validity
verify-options show-uid-validity
with-fingerprint
use-agent
require-cross-certification
EOF

sudo curl --silent "https://sks-keyservers.net/sks-keyservers.netCA.pem" -o /etc/sks-keyservers.netCA.pem


echo -ne "Y\n" | 


exit
























# package dependencies for yubikey smartcard 
dependencies=( gnupg2 
gnupg-agent 
pinentry-curses 
scdaemon 
pcscd  
pcsc-tools
ccid
libusb-compat
yubikey-personalization 
libusb-1.0-0-dev )

# iterate through dependency array. if not installed on system, add to array of packages to be installed
for x in ${dependencies[@]}; do
     [ $(dpkg-query -W -f='${Status}' $x 2>/dev/null | grep -c "ok installed") -eq 0 ] && missing+=("$x") || skipped+=("$x")
done

# only petform apt-get update if a required dependency is missing 
if [[ ${#missing[@]} -gt  0 ]]; then
   # sudo apt-get update

# attempt install and query result
for y in ${missing[@]}; do
     echo -ne Installing... $y
  #   sudo apt-get install --yes --force-yes $y >/dev/null 2>&1
    [ $? -eq 0 ] && success+=("$y") && echo good ||  error+=("$y")
done

fi


echo Installed: ${#success[@]} 
for i in ${success[@]}; do echo " - $i"; done
echo Skipped: ${#skipped[@]}
for i in ${skipped[@]}; do echo " - $i"; done
echo Failed: ${#error[@]}
for i in ${error[@]}; do echo " - $i"; done





