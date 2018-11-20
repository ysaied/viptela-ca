#! /bin/bash

echo "##########################################"
echo "Welcome to Linux Root CA for Viptela SD-WAN"
echo "##########################################"
echo ""


echo "Install OpenSSL package"
sudo apt-get install -y openssl > /dev/null
sudo apt-get install -y expect > /dev/null

echo "Create sdwan-ca directory"
if [ -d $HOME/sdwan-ca ]; then sudo rm -r $HOME/sdwan-ca; fi
mkdir ~/sdwan-ca

echo "OpenSSL Private Key Generated"
openssl genrsa -out ~/sdwan-ca/ca.key 2048 &> /dev/null

echo "OpenSSL Root Certificate Generated"

echo '#!/usr/bin/expect -f
set timeout -1
spawn openssl req -new -x509 -key /home/admin/sdwan-ca/ca.key -out /home/admin/sdwan-ca/ca.crt -days 10950
match_max 100000
expect -exact "Country Name (2 letter code) \[AU\]:"
send -- "AE\r"
expect -exact "State or Province Name (full name) \[Some-State\]:"
send -- "Dubai\r"
expect -exact "Locality Name (eg, city) \[\]:"
send -- "Dubai\r"
expect -exact "Organization Name (eg, company) \[Internet Widgits Pty Ltd\]:"
send -- "du\r"
expect -exact "Organizational Unit Name (eg, section) \[\]:"
send -- "sdwan\r"
expect -exact "Common Name (e.g. server FQDN or YOUR name) \[\]:"
send -- "du.ae\r"
expect -exact "Email Address \[\]:"
send -- "viptela@du.ae\r"
expect eof' | sudo tee /var/tmp/sdwan-ca.exp > /dev/null

sudo chmod 775 /var/tmp/sdwan-ca.exp
(cd /var/tmp && ./sdwan-ca.exp) > /dev/null


echo "OpenSSL Certificate Authority Config file Generated "
echo '[ ca ]
default_ca                              = du_sdwan

[ du_sdwan ]
dir                                     = /home/admin/sdwan-ca
certs                                   = $dir/certs
new_certs_dir                           = $dir/newcerts
database                                = $dir/index.txt
serial                                  = ./serial
RANDFILE                                = $dir/private/.rand

# The root key and root certificate.
private_key                             = ./ca.key
certificate                             = ./ca.crt

default_md                              = sha256
name_opt                                = ca_default
cert_opt                                = ca_default
default_days                            = 10950
preserve                                = no
policy                                  = sdwan_policy

[ sdwan_policy ]
countryName                             = optional
stateOrProvinceName                     = optional
organizationName                        = optional
organizationalUnitName                  = optional
commonName                              = supplied
emailAddress                            = optional' | sudo tee ~/sdwan-ca/ca.conf > /dev/null

echo "OpenSSL CA Ready to Sign Certificates"
mkdir ~/sdwan-ca/newcerts
touch ~/sdwan-ca/index.txt
touch ~/sdwan-ca/index.txt.attr
echo '01' > ~/sdwan-ca/serial


echo 'read -r -p "Enter file name to be signed?  " answer
if [ -f ./$answer ]
then 
   (sudo openssl ca -config ca.conf -out $answer.pem -infiles $answer)
else 
   echo "file not found ...!!!"
fi' | sudo tee ~/sdwan-ca/sign.sh > /dev/null
sudo chmod 775 ~/sdwan-ca/sign.sh


