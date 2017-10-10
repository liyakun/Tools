#!/bin/bash
# This script will assist you to setup vpn connection
# Assuming that you already have necessary drivers installed to read SmartCard
# Additionally, you need to have OpenConnect and p11tool installed
#
# Usage:
#       sudo sh vpn.sh VPN_SERVER TOKEN_ID AUTH_ID PATH_SCLIB
# Arguments:
#       VPN_SERVER, name of vpn server
#       TOKEN_ID, token identifier of your SmartCard appears in the URL of Token
#       AUTH_ID, identifier of your authentication certificate in the URL of Object
#       PATH_SCLIB, path to the security lib you need
# Example:
#       sudo sh vpn.sh https://mycompany.com CompanyName Authentication
#

# set vpn server, system path to libcvP11 and opensc.module
VPN_SERVER=$1
TOKEN_ID=$2
AUTH_ID=$3
PATH_SCLIB=$4
OPENSC_MODULE='/usr/share/p11-kit/modules/opensc.module'

echo "Connect $VPN_SERVER"

# check whether OpenConnect installed
check_openconnect () {
    if  [ ! -x "$(command -v openconnect)" ]; then
        echo 'Error: openconnect is not installed, install with by typing: sudo apt install openconnect'
        exit 1
    fi
}

# check whether p11tool installed
check_p11tool () {
    if  [ ! -x "$(command -v p11tool)" ]; then
        echo 'Error: p11tool is not installed, install with by typing: sudo apt install gnutls-bin'
        exit 1
    fi
}

# check whether module exists in opensc.module
set_smartcard_lib () {
    # if libcvP11 is not in opensc.module
    if grep -Fxq libcvP11 $OPENSC_MODULE; then
        echo "Add $PATH_SCLIB to $OPENSC_MODULE"
        echo "module:$PATH_SCLIB" >> $OPENSC_MODULE
    fi
}

# get smart card token
get_smartcard_token () {
    TOKEN_URL=`p11tool --list-tokens | grep URL | grep $TOKEN_ID | awk '{print $2}'`
}

# get authentication certicate
get_auth_cert () {
    AUTH_OBJ=`p11tool --list-all-certs $TOKEN_URL | grep URL | grep $AUTH_ID | awk '{print $2}'`
}

# you can comment out the following three lines if you already set up your environment
check_openconnect
check_p11tool
set_smartcard_lib

get_smartcard_token
# if found expected smart card token
if [ ! -z "$TOKEN_URL" ]; then
    # get auth certificate
    get_auth_cert
    # connect to vpn server
    tail -f `sudo openconnect -c $AUTH_OBJ $VPN_SERVER --no-cert-check`
fi
