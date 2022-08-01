#!/bin/bash

#Things to check for:
#Secrets Access Permissions AZURE
#Internet Access and Routing
#Verify the checks are looking at the correct log file bootup or runtime

 
#Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;36m'
PURPLE='\033[1;35m'
NC='\033[0m' # No Color

#Variable Inputs
bootlog=/var/run/janus/bootup.log
runlog=/var/run/janus/runtime.log


#Check if Cloud Connector is completely operational. Quit if successful, continue if not ready yet
if tail -100  $runlog | grep -m 1 -q "Instance is ready to process traffic"; then
    echo -e ${PURPLE}"No errors detected."
    echo -e "Cloud Connector is deployed and ready to process traffic!"${NC}
    echo ""
    exit 0;
    else
    echo -e ${RED} "Cloud Connector is not ready to process traffic for workloads"${NC}
    echo ""
fi

#Check if janus bootup is complete. Check for bootup.log errors if not complete.
if grep -q "Bootup Complete" $bootlog; then
    echo "Cloud Connector Control Plane Bootup Complete"
    echo ""
    else
    #Check for Secrets Access Permissions with KMS
    if grep -m 1 -q "Access to KMS is not allowed" $bootlog; then
        echo -e ${RED}"Error: Access to KMS is not allowed"
        echo -e ${YELLOW}"Reason: Cloud Connector IAM Role does not have access to read or decrypt the KMS Encryption Key for the AWS Secrets"
        echo -e ${GREEN}"How to Fix: Add the Cloud Connector IAM Role ARN to KMS IAM Policy to allow access"${NC}
        echo ""
    fi
    #Check if AWS Secret Exists
    if grep -m 1 -q "Secrets Manager can\'t find the specified secret." $bootlog; then
        echo -e ${RED}"Error: Secrets Manager can\'t find the specified secret."
        echo -e ${YELLOW}"Reason: The specified AWS Secret Name does not exist in AWS Secrets Manager"
        echo -e ${GREEN}"How to Fix: Create the AWS Secrets using the name specified in the deployment and in the correct region"${NC}
        echo ""
    fi
    #Check for correct API Key
    if grep -m 1 -q "Error while provisioning the EC cloud. string index out of range" $bootlog; then
     echo -e ${RED}"Error: Error while provisioning the EC cloud. string index out of range"
        echo -e ${YELLOW}"Reason: The stored Cloud Connector API Key in AWS Secrets Manager is incorrect"
     echo -e ${GREEN}"How to Fix: Edit the api-key secret in AWS Secrets manager with the correct API key from Connector admin console"${NC}
     echo ""
    fi
    #Check for correct Admin Username and Password
    if grep -m 1 -q "\"code\":\"AUTHENTICATION_FAILED\",\"message\":\"INVALID_USERNAME_OR_PASSWORD\"" $bootlog; then
        echo -e ${RED}"Error: \"code\":\"AUTHENTICATION_FAILED\",\"message\":\"INVALID_USERNAME_OR_PASSWORD\""
     echo -e ${YELLOW}"Reason: The stored Cloud Connector Admin Credentials in AWS Secrets Manager is incorrect"
     echo -e ${GREEN}"How to Fix: Edit the username and/or password secrets in AWS Secrets manager with the correct credentials from Connector admin console"${NC}
      echo ""
    fi
    #Check for valid Provisioining URL
    if grep -m 1 -q "Provisioning URL Query https://connector..*.net:443/api/v1/provUrl returned empty response" $bootlog; then
        provurl=$(cat $bootlog | grep "Insufficient data on querying Provisioning URL"| cut -d ' ' -f 11)
        echo -e ${RED}"Error: Provisioning URL Query returned empty response"
        echo -e ${YELLOW}"Reason: The Cloud Connector Provisioning URL ${provurl} does not exist"
     echo -e ${GREEN}"How to Fix: Verify or create a Provisioning Template in the Connector admin console "${NC}
     echo ""
    fi
fi

#Check for Key Vault Access Permissions in Azure - NEED TO TEST

#Checks in the runtime.log
#Check for License SKU
if grep -m 1 -q "Malformed DHCP lease response" $runlog; then
    echo -e ${RED}"Error: Malformed DHCP lease response"
    echo -e ${YELLOW}"Reason: Missing License SKU in Tenant"
    echo -e ${GREEN}"How to Fix: Contact Zscaler Provisioning Team to add all required SKUs for Cloud Connectrs"${NC}
    echo ""
fi

#Check for Network Interface order. Management Interface needs to be first
smedgeifconfig=$(/sc/instances/edgeconnector0/bin/smmgr -ys smnet="ifconfig nm0 :type any" | grep inet | cut -d ' ' -f 2)
vmifconfig=$(ifconfig ena0 | grep inet | cut -d ' ' -f 2)
if [ "$smedgeifconfig" == "$vmifconfig" ]; then
    echo -e ${RED}"Configuration Error: Management network interface is not first"
    echo -e ${YELLOW}"Reason: The CFT/TF template has incorrect configuration of network interfaces order"
    echo -e ${GREEN}"How to Fix: Change the interface order so management is first in the CFT/TF and redeploy Cloud Connectors "${NC}
    echo ""
fi

#Check HTTP Probe Health Check
if grep -m 1 -q "http_probe_port" $runlog; then
    probetest=$(curl -v http://${smedgeifconfig}:${probeportlogs}/?cchealth)
    if grep -q "HTTP/1.1 200 OK" $probetest; then
    echo "Health Check Probe Test Successful"
    echo ""
    else
    echo -e ${RED}" Error: Health Check Probe Test Failed"
    echo -e ${YELLOW}"Reason: Health check on service interface IP ${smedgeifconfig} port ${probeportlogs} did not respond to probe"
    echo -e ${GREEN}"How to Fix: Check network firewall rules, routing, network interface order, and verify port is correct"${NC}
    echo ""
    fi
fi

#Check for Internet Access -- is this bootlog or runlog????
if grep -m 1 -q "Connection to gateway..*.net timed out" $bootlog; then
    echo -e ${RED}"Error: Connector to the Zscaler Gateway timed out"
    echo -e ${YELLOW}"Reason: The Cloud Connector is unable to reach out to the Zscaler Cloud"
    echo -e ${GREEN}"How to Fix: Check for and fix outbound firewall/security rules, routing so Cloud Connector has outbound internet access"${NC}
    echo ""
fi

#Check for Internet Access specifically for Service Interface
if grep -m 1 -q "ZIA gateway PAC resolution failed" $runlog; then
    echo -e ${RED}"Error: ZIA gateway PAC resolution failed"
    echo -e ${YELLOW}"Reason: The Cloud Connector Service Interface is unable to reach out to the Zscaler Cloud"
    echo -e ${GREEN}"How to Fix: Check for and fix outbound firewall/security rules for the Cloud Connector Service Interface outbound to Internet"${NC}
    echo ""
fi

#Basic Configuration Checks and Information

imageid=$(sudo januscli status | grep "system_fingerprint" | cut -d ':' -f 2)
echo "Cloud Connector VM/AMI Version: $imageid"
echo ""

bootuplog=/var/run/janus/bootup.log
if [ -f "$bootuplog" ]; then
    echo "Control Plane (janus service) bootup.log file exists"
fi

runtime=/var/run/janus/runtime.log
if test -f "$runtime"; then
    echo "Control Plane (janus service) runtime.log file exists"
fi

ecdirectory=/sc/instances/edgeconnector0
if [ -d "$ecdirectory" ]; then
    echo "Data Plane (smedge service) instance directory exists"
fi

probeportlogs=$(cat /var/run/janus/bootup.log | grep -m 1 http_probe_port | cut -d ':' -f 2)
probeportconfig=$(cat /etc/cloud/cloud.cfg.d/userdata.cfg | grep http_probe_port | cut -d ':' -f 2 | tr -d \'\")
if [ "$probeportlogs" == "$probeportconfig" ]; then
    echo "Cloud Connector Health Check Probe Port Properly Configured using Port $probeportconfig"
    echo ""
fi