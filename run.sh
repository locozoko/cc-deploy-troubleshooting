#!/bin/bash

# Version 0.7
# Last Updated August 3, 2022
# Contact Zoltan (zkovacs@zscaler.com) with questions or issues

#Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

#Display script banner
echo -e ${BLUE}" ____    ___   ___    _    _      ___   ____  ";
echo -e ${BLUE}")___ (  (  _( / _(   )_\  ) |    ) __( /  _ \ ";
echo -e ${BLUE}"  / /_  _) \  ))_   /( )\ | (__  | _)  )  ' / ";
echo -e ${BLUE}" )____()____) \__( )_/ \_()____( )___( |_()_\ ";
echo -e ${BLUE}"                                              ";
echo -e ${BLUE}"This script checks for common Cloud Connector errors and configuration issues"${NC}

if [[ ! -e ./.checksrc ]]; then
    read -p "Cloud Connector Management IP: " ccmgmtip
    read -p "Cloud Connector SSH Key: " cckey
    read -p "Using a jumpbox? (yes|no): " jumpbox
    read -p "Jumpbox IP or Hostname: " jumpboxhost
    read -p "Jumpbox username: " jumpboxusername
    read -p "Jumpbox SSH Key: " jumpboxkey
    echo ""
    echo "Connecting to Cloud Connector. Please wait..."
    if [ $jumpbox = "no" ]; then
        #SSH direct to Cloud Connector
        ssh -i ${cckey} zsroot@${ccmgmtip} 'bash -s' < checks.sh
        else
        ##SSH to Cloud Connector via jumpbox
        ssh -i ${cckey} zsroot@${ccmgmtip} -o "proxycommand \
        ssh -W %h:%p \-i ${jumpboxkey} ${jumpboxusername}@${jumpboxhost}" 'bash -s' < checks.sh
    fi
    echo "export ccmgmtip=${ccmgmtip}" > .checksrc
    echo "export cckey=${cckey}" >> .checksrc
    echo "export jumpbox=${jumpbox}" >> .checksrc
    echo "export jumpboxhost=${jumpboxhost}" >> .checksrc
    echo "export jumpboxusername=${jumpboxusername}" >> .checksrc
    echo "export jumpboxkey=${jumpboxkey}" >> .checksrc
    else
    # initialize environment variables and run script
    . ./.checksrc
    if [ -z "$ccmgmtip" ] || [ -z "$cckey" ] || [ -z "$jumpboxhost" ] || [ -z "$jumpboxusername" ] || [ -z "$jumpboxkey" ]; then
        echo -e ${RED}"Connection info is missing. Remove .checksrc file and run the script again"${NC}
        exit 1
        else
        echo ""
        echo "Checking Cloud Connector Information. Please wait..."
        echo ""
        if [ $jumpbox = "no" ]; then
        #SSH direct to Cloud Connector
        ssh -i ${cckey} zsroot@${ccmgmtip} 'bash -s' < checks.sh
        else
        ##SSH to Cloud Connector via jumpbox
        ssh -i ${cckey} zsroot@${ccmgmtip} -o "proxycommand \
        ssh -W %h:%p \-i ${jumpboxkey} ${jumpboxusername}@${jumpboxhost}" 'bash -s' < checks.sh
        fi
    fi
fi
unset ccmgmtip
unset cckey
unset jumpboxhost
unset jumpbox
unset jumpboxhost
unset jumpboxusername
unset jumpboxkey