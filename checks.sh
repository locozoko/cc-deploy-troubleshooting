#!/bin/bash

# Version 0.7
# Last Updated August 3, 2022
# Contact Zoltan (zkovacs@zscaler.com) with questions or issues

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

#Check if janus bootup is complete. Check for bootup.log errors if not complete.
echo "Checking bootup.log for known errors..."
echo ""
if grep -m 1 -q "Bootup Complete" $bootlog; then
    echo "Cloud connector Control plane bootup complete without errors..."
    echo ""
    else
    #Check for Secrets Access Permissions with KMS
    if tail -200 $bootlog | grep -m 1 -q "Access to KMS is not allowed"; then
        echo -e ${RED}"Error: Access to KMS is not allowed"
        echo -e ${YELLOW}"Reason: Cloud Connector IAM Role does not have access to read or decrypt the KMS Encryption Key for the AWS Secrets"
        echo -e ${GREEN}"How to Fix: Add the Cloud Connector IAM Role ARN to KMS IAM Policy to allow access"${NC}
        echo ""
    fi
    #Check if AWS Secret Exists
    if tail -200 $bootlog | grep -m 1 -q "Secrets Manager can.*t find the specified secret"; then
        echo -e ${RED}"Error: Secrets Manager can\'t find the specified secret"
        echo -e ${YELLOW}"Reason: The specified AWS Secret Name does not exist in AWS Secrets Manager"
        echo -e ${GREEN}"How to Fix: Create the AWS Secrets using the name specified in the deployment and in the correct region"${NC}
        echo ""
    fi
    #Check if Azure Key Vault URL is valid format
    if tail -200 $bootlog | grep -m 1 -q "Secret retrieval failed. No connection adapters were found for"; then
        echo -e ${RED}"Error: Secret retrieval failed. No connection adapters were found for"
        echo -e ${YELLOW}"Reason: The specified Azure Key Vault URL does not appear correct"
        echo -e ${GREEN}"How to Fix: Check the terraform script for typos for the Azure Key Vault URL and redeploy"${NC}
        echo ""
    fi
    #Check if Azure Key Vault Exists
    if tail -200 $bootlog | grep -m 1 -q "Failed to establish a new connection: \[Errno 8\] hostname nor servname provided, or not known"; then
        echo -e ${RED}"Error: Failed to establish a new connection: [Errno 8] hostname nor servname provided, or not known"
        echo -e ${YELLOW}"Reason: The specified Azure Key Vault does not exist"
        echo -e ${GREEN}"How to Fix: Create the Azure Key Vault using the name specified in the deployment and in the correct region"${NC}
        echo ""
    fi
    #Check for Azure Key Vault Permissions
    if tail -200 $bootlog | grep -m 1 -q "does not have secrets get permission on key vault"; then
        echo -e ${RED}"Error: The user, group or applicatio...does not have secrets get permission on key vault"
        echo -e ${YELLOW}"Reason: The Managed Identity does not have permission to access the Azure Key Vault"
        echo -e ${GREEN}"How to Fix: Give the Managed Identity Get and List Secret permissions in the Azure Key Vault"${NC}
        echo ""
    fi
    #Check for correct API Key
    if tail -200 $bootlog | grep -m 1 -q "Error while provisioning the EC cloud. string index out of range"; then
     echo -e ${RED}"Error: Error while provisioning the EC cloud. string index out of range"
        echo -e ${YELLOW}"Reason: The stored Cloud Connector API Key in AWS Secrets Manager or Azure Key Vault is incorrect"
     echo -e ${GREEN}"How to Fix: Edit the api_key in AWS Secrets Manager or api-key in Azure Key Vault with the correct API key from Connector admin console"${NC}
     echo ""
    fi
    #Check for correct Admin Username and Password
    if tail -200 $bootlog | grep -m 1 -q "\"code\":\"AUTHENTICATION_FAILED\",\"message\":\"INVALID_USERNAME_OR_PASSWORD\""; then
        echo -e ${RED}"Error: \"code\":\"AUTHENTICATION_FAILED\",\"message\":\"INVALID_USERNAME_OR_PASSWORD\""
     echo -e ${YELLOW}"Reason: The stored Cloud Connector Admin Credentials in AWS Secrets Manager or Azure Key Vault is incorrect"
     echo -e ${GREEN}"How to Fix: Edit the username and/or password secrets in AWS Secrets Manager or Azure Key Vault with the correct credentials"${NC}
      echo ""
    fi
    #Check for valid Provisioining URL
    if tail -200 $bootlog | grep -m 1 -q  "Provisioning URL Query https://connector..*.net:443/api/v1/provUrl returned empty response"; then
        provurl=$(cat $bootlog | grep "Insufficient data on querying Provisioning URL"| cut -d ' ' -f 11)
        echo -e ${RED}"Error: Provisioning URL Query returned empty response"
        echo -e ${YELLOW}"Reason: The Cloud Connector Provisioning URL ${provurl} does not exist"
     echo -e ${GREEN}"How to Fix: Create a Provisioning Template with matching name in the Connector admin console"
     echo -e ${GREEN}"            If the Provisioing URL is incorrect, fix in CFT/TF and redeploy the Cloud Connector"${NC}
     echo ""
    fi
    #Check for Internet Access
    if  tail -200 $bootlog | grep -m 1 -q "Connection to gateway..*.net timed out"; then
        echo -e ${RED}"Error: Connection to the Zscaler Gateway timed out"
        echo -e ${YELLOW}"Reason: The Cloud Connector is unable to reach out to the Zscaler Cloud"
        echo -e ${GREEN}"How to Fix: Check for and fix outbound firewall/security rules, routing so Cloud Connector has outbound internet access"${NC}
        echo ""
    fi
    if tail -200 $bootlog | grep -m 1 -q "No route to host"; then
        echo -e ${RED}"Error: No route to host"
        echo -e ${YELLOW}"Reason: The Cloud Connector is unable to reach out to the Zscaler Cloud"
        echo -e ${GREEN}"How to Fix: Check for and fix outbound firewall/security rules, routing so Cloud Connector has outbound internet access"${NC}
        echo ""
    fi
    #Check for cloud config metadata issue
    if tail -200 $bootlog | grep -m 1 -q  "HTTP GET Request on URL http://169.254.169.254/latest/user-data failed with status code 404 and error"; then
        echo -e ${RED}"Error: HTTP GET Request on URL http://169.254.169.254/latest/user-data failed with status code 404 and error"
        echo -e ${YELLOW}"Reason: The metadata file was possible corrupted on boot"
     echo -e ${GREEN}"How to Fix: Run this command on the Cloud Connector: mv /etc/cloud/cloud.cfg.d/metadata.cfg /etc/cloud/cloud.cfg.d/metadata.cfg.old"
     echo -e ${GREEN}"            Then restart the control plane service by running this command: sudo janus restart"${NC}
     echo ""
    fi
    #Check for unsupported availability zone deployment
    if tail -200 $bootlog | grep -m 1 -q  "Error while provisioning the EC cloud. .* object has no attribute" ; then
        echo -e ${RED}"Error: Error while provisioning the EC cloud. NoneType object has no attribute keys"
        echo -e ${YELLOW}"Reason: The Cloud Connector has been deployed in an unsupported Availability Zone"
     echo -e ${GREEN}"How to Fix: Redeploy the Cloud Connector in a support Availability Zone. Contact Zscaler for assistance"${NC}
     echo ""
    fi
    #Check for pending activations in ZIA and CC admin consoles
    if tail -200 $bootlog | grep -m 1 -q  "status_code 500" ; then
        echo -e ${RED}"Error: status_code 500"
        echo -e ${YELLOW}"Reason: There is a pending activation in the ZIA/CC admin portal"
        echo -e ${GREEN}"How to Fix: Active changes in the ZIA/CC admin portal"${NC}
        echo -e ${GREEN}"Then run the following command on the Cloud Connector: sudo janus restart"${NC}
     echo ""
    fi
fi

#Check the runtime.log for errors if the runtime.log file exists
if [[ -f "/var/run/janus/runtime.log" ]]
then
    echo "Checking runtime.log for known errors..."
    echo ""
    #Check for Azure Managed Identity Role/Permissions
    if tail -200 $runlog | grep -m 1 -q "does not have secrets get permission on key vault"; then
        echo -e ${RED}"The user, group or application...does not have secrets get permission on key vault"
        echo -e ${YELLOW}"Reason: The Managed Identity does not correct permissions"
        echo -e ${GREEN}"How to Fix: Give the Managed Identity Network Contributor or custom role with network interfaces read access"${NC}
        echo ""
    fi
    #Check for Old Cloud Connector Image Version
    if tail -200 $runlog | grep -m 1 -q " failed to find the version of janus : pkg: Repository Zscaler missing"; then
        echo -e ${RED}"failed to find the version of janus : pkg: Repository Zscaler missing"
        echo -e ${YELLOW}"Reason: Possibly referencing an old Cloud Connector Azure VM Image Version or AWS AMI"
        echo -e ${GREEN}"How to Fix: Use latest or update CFT/TF deployment script with latest Cloud Connector image"${NC}
        echo ""
    fi
    #Additional Check for Old Cloud Connector Image Version
    if tail -200 $runlog | grep -m 1 -q " pkg edgeconnector-nightly doesn't seem to be exist in the remote repositories: pkg: Repository FreeBSD missing"; then
        echo -e ${RED}"pkg edgeconnector-nightly doesn't seem to be exist in the remote repositories: pkg: Repository FreeBSD missing"
        echo -e ${YELLOW}"Reason: Possibly referencing an old Cloud Connector Azure VM Image Version or AWS AMI"
        echo -e ${GREEN}"How to Fix: Use latest or update CFT/TF deployment script with latest Cloud Connector image"${NC}
        echo ""
    fi
    #Check for License SKU
    if tail -200 $runlog | grep -m 1 -q "Malformed DHCP lease response"; then
        echo -e ${RED}"Error: Malformed DHCP lease response"
        echo -e ${YELLOW}"Reason: Missing License SKU in Tenant"
        echo -e ${GREEN}"How to Fix: Contact Zscaler Provisioning Team to add all required SKUs for Cloud Connectrs"${NC}
        echo ""
    fi
    #Check for Network Interface order. Management Interface needs to be first
    if grep -q "  azEnvironment: AzurePublicCloud" /etc/cloud/cloud.cfg.d/metadata.cfg; then
        #Azure Checks
        smedgeifconfig=$(/sc/instances/edgeconnector0/bin/smmgr -ys smnet="ifconfig /dev/tap0 :type any" > /dev/null 2>&1 | grep inet | cut -d ' ' -f 2 )
        vmifconfig=$(ifconfig hn0 | grep inet | cut -d ' ' -f 2)   
    if [ "$smedgeifconfig" == "$vmifconfig" ]; then
        echo -e ${RED}"Configuration Error: Management network interface is not first"
        echo -e ${YELLOW}"Reason: The CFT/TF template has incorrect configuration of network interfaces order"
        echo -e ${GREEN}"How to Fix: Change the interface order so management is first in the CFT/TF and redeploy Cloud Connectors "${NC}
        echo ""
    fi
    else
    #AWS Checks
        smedgeifconfig=$(/sc/instances/edgeconnector0/bin/smmgr -ys smnet="ifconfig nm0 :type any" > /dev/null 2>&1 | grep inet | cut -d ' ' -f 2 )
        vmifconfig=$(ifconfig ena0 | grep inet | cut -d ' ' -f 2)   
        if [ "$smedgeifconfig" == "$vmifconfig" ]; then
            echo -e ${RED}"Configuration Error: Management network interface is not first"
            echo -e ${YELLOW}"Reason: The CFT/TF template has incorrect configuration of network interfaces order"
            echo -e ${GREEN}"How to Fix: Change the interface order so management is first in the CFT/TF and redeploy Cloud Connectors "${NC}
            echo ""
        fi
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
    #Check for Internet Access specifically for Service Interface
    if tail -200 $runlog | grep -m 1 -q "ZIA gateway PAC resolution failed"; then
        echo -e ${RED}"Error: ZIA gateway PAC resolution failed"
        echo -e ${YELLOW}"Reason: The Cloud Connector Service Interface is unable to reach out to the Zscaler Cloud"
        echo -e ${GREEN}"How to Fix: Check for and fix outbound firewall/security rules for the Cloud Connector Service Interface outbound to Internet"${NC}
        echo ""
    fi
fi

#Check if Cloud Connector is completely operational
if [[ -f "/var/run/janus/runtime.log" ]]; then
    if grep -m 1 -q "Instance is ready to process traffic" $runlog; then
        echo -e ${PURPLE}"No errors detected."
        echo -e "Cloud Connector is deployed and ready to process traffic!"${NC}
        echo ""
        exit 0;
        else
        echo ""
        echo -e ${YELLOW}"Cloud Connector is not ready to process traffic for workloads"${NC}
        echo -e ${BLUE}"The enrollment process can take up to 15 Minutes. Please re-run the script in a few minutes..."${NC}
        echo ""
    fi
fi