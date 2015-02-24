# !/bin/bash
#
# setup-ntp-on-cent-os-7.sh
# Purpose: Installs the NTP daemon and enables it.
#
# Copyright (c) 2014-2015 Michael Dichirico (https://github.com/mdichirico)
# This software/script is released under the terms of the MIT license (http://en.wikipedia.org/wiki/MIT_License).
# 
# INSTRUCTIONS FOR USE:
# 1. Copy this shell script to your home directory or the /tmp directory.
# 2. Make it executable with the following command: 
#      chmod a+x setup-ntp-on-cent-os-7.sh
# 3. Execute the script as a sudo user:
#      sudo ./setup-ntp-on-cent-os-7.sh

echo ""
echo "Starting..."
MYDATE=`date -R`
echo "The date on your server BEFORE any changes: $MYDATE";

RELEASE=`cat /etc/redhat-release`
isCentOs7=false
SUBSTR=`echo $RELEASE|cut -c1-22`
SUBSTR2=`echo $RELEASE|cut -c1-26`

if [ "$SUBSTR" == "CentOS Linux release 7" ]
then
    isCentOs7=true
fi

# TODO: add a check for versions earlier than 6.5

if [ "$isCentOs7" == true ]
then
    echo "I am CentOS 7"
    echo ""
fi


# Install and set-up NTP daemon:
if [ "$isCentOs7" == true ]
then
    sudo yum install ntp > /dev/null
    sudo firewall-cmd --add-service=ntp --permanent
    sudo firewall-cmd --reload

    sudo systemctl start ntpd
fi

echo ""
echo "Finished with setup"
echo "The date on your server AFTER any changes: $MYDATE";
echo "If you do not see any changes before the BEFORE and AFTER values, wait a few minutes for NTP to pool its time servers and then try this command: date -R"
echo ""
