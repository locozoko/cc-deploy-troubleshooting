# Cloud Connector Deployment Troubleshooting Script

## Description
This script is not an official Zscaler script and was used to help improve time to resolution for Cloud Connector deployments. This will be maintained and updated when possible but it is not guaranteed to always catch the latest or newest errors. However, most of the common deployment and configuration issues will be identified with this script.

## How to Use
There are 2 ways you can use these scripts: Run locally from your macos or linux device or run directly on a Cloud Connector. There is some basic logic in these scripts but nothing really fancy. It mainly just looks through the Cloud Connector boot and runtime logs by tailing the last ~100-150 lines and uses grep to find known errors. 

Output from the scripts are only displayed on the screen and are not written to a log file.

### Run the script from your macos or linux device

Demo Video: https://www.loom.com/share/8a1c6b827f6c4e648eccd175a155f200

1. Cone this repo to your macos or linux device: <code>git clone https://github.com/locozoko/cc-deploy-troubleshooting</code>
2. Run the troubleshooting helper script: <code>./run.sh</code>
3. On first run, you will be prompted for various input such as Cloud Connector Management IP and SSH Key, if there's a jumbpox/bastion, etc. 
4. **Please note the SSH Key inputs require a full path so if the key is not in the same folder as this cloned repo, provide the full path such as /Users/someone/mykeys/cloudconnector.key. Also note that the script simply uses SSH to execute the commands remotely, so you'll need the private key already copied to the Jumpbox/bastion you specify. 
5. The helper script will then execute the checks.sh script on the Cloud Connector remotely but display the output locally to your device. 
6. Review the output as it will display any known errors with the common root causes and steps to fix them.
7. Rerun the script whenver you fix the issue. You can run it as many times as needed.

You'll notice after the first run you are no longer prompted for Cloud Connector or Jumpbox input. That's because the script saves those variables into the same directory as a hidden file ".checksrc". If you want to run the script against another Cloud Connector, you can either delete the .checksrc file or just modify the variables with the new information and execute ./run.sh again.

### Run the script directly on a Cloud Connector
1. Cone this repo on the Cloud Connector: <code>git clone https://github.com/locozoko/cc-deploy-troubleshooting</code>
2. Run the troubleshooting script: <code>./checks.sh</code>
3. Review the output as it will display any known errors with the common root causes and steps to fix them.
4. Rerun the script whenver you fix the issue. You can run it as many times as needed.

## Version and Help

Version 0.6
Last Updated August 2 2022
Contact Zoltan (zkovacs@zscaler.com) with questions or issues

Feel free to fork this repo to make your own changes, improvements, etc. Send over a pull request from your fork and I will review and merge any approved changes submitted after testing.
